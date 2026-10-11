from contextlib import asynccontextmanager
from datetime import datetime
from io import BytesIO
from threading import Lock
from typing import Literal
import logging
import math
import warnings

import joblib
import pandas as pd
from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from PIL import Image, ImageOps, UnidentifiedImageError
from pydantic import BaseModel, ConfigDict, Field, ValidationError

from app.common import MODELS, FEATURES, audio_features
from app.gemini_damage import detect_bike_gemini, gemini_configured


loaded = {}
failed = []
locks = {}

KINDS = ["price", "audio", "damage"]
VEHICLES = ["car", "bike"]


def validate_price_artifact(artifact, vehicle, demo=False):
    if not isinstance(artifact, dict) or not callable(
        getattr(artifact.get("model"), "predict", None)
    ):
        raise ValueError("Invalid price model artifact")

    metadata = artifact.get("metadata", {})

    if metadata.get("vehicle_type") != vehicle:
        raise ValueError("Wrong vehicle type in price model")

    expected = ["name", "year", "km_driven"] if demo else list(FEATURES)

    if metadata.get("features") != expected:
        raise ValueError("Price artifact has an incompatible input schema")

    if demo:
        artifact["model"].named_steps[
            "preprocess"
        ].named_transformers_["name"].categories_
    else:
        for key in ["pairs", "year_range", "mileage_range"]:
            if key not in artifact:
                raise ValueError(f"Price artifact is missing {key}")


def price_units_verified(artifact):
    if not artifact:
        return False

    meta = artifact.get("metadata", {})
    flag = meta.get(
        "price_units_verified",
        meta.get("config", {}).get("price_units_verified", False),
    )

    return meta.get("currency") == "LKR" and flag is True


def require_verified_price(artifact):
    if not price_units_verified(artifact):
        raise HTTPException(
            503,
            "LKR price units are not verified in this saved model. "
            "Use /api/v1/demo/car-price or /api/v1/demo/bike-price "
            "for experimental testing. Verify dataset units and "
            "retrain before using valuation.",
        )


def price_row(artifact, make, model, year, mileage_km):
    make = make.strip().lower()
    model = model.strip().lower()

    if [make, model] not in artifact["pairs"]:
        raise HTTPException(
            422,
            "This make/model pair was not present in the training set.",
        )

    lo, hi = artifact["year_range"]
    ml, mh = artifact["mileage_range"]

    if not lo <= year <= hi or not ml <= mileage_km <= mh:
        raise HTTPException(
            422,
            "Year/mileage is outside the training range.",
        )

    return pd.DataFrame(
        [[make, model, year, mileage_km]],
        columns=FEATURES,
    )


def predict_price(key, artifact, row):
    try:
        with locks[key]:
            value = float(artifact["model"].predict(row)[0])

        if not math.isfinite(value) or value <= 0:
            raise ValueError("Invalid prediction value")

        return value

    except Exception:
        logging.exception("Prediction failed for %s", key)
        raise HTTPException(
            500,
            "Price prediction failed. Check server logs "
            "and model/package compatibility.",
        ) from None


@asynccontextmanager
async def lifespan(app):
    loaded.clear()
    failed.clear()
    locks.clear()

    for vehicle in VEHICLES:
        for kind in KINDS:
            if vehicle == "bike" and kind == "damage":
                continue  # Bike damage uses the Gemini API.

            key = f"{vehicle}_{kind}"
            ext = "pt" if kind == "damage" else "joblib"
            path = MODELS / f"{key}_v1.{ext}"

            # Pretrained car damage model uses ONNX.
            if vehicle == "car" and kind == "damage":
                path = MODELS / "car_damage_v1.onnx"

            if not path.is_file():
                print(f"Model not installed: {key}", flush=True)
                continue

            try:
                # Load only trusted model artifacts.
                print(f"Loading model: {key} from {path}", flush=True)

                if kind == "damage":
                    from ultralytics import YOLO

                    loaded[key] = YOLO(str(path), task="segment")
                else:
                    artifact = joblib.load(path)

                    if kind == "price":
                        validate_price_artifact(artifact, vehicle)

                    loaded[key] = artifact

                locks[key] = Lock()
                print(f"Loaded model: {key}", flush=True)

            except Exception:
                logging.exception("Failed to load %s", key)
                failed.append(key)

    demo_path = MODELS / "demo" / "bike_price_v1.joblib"

    if demo_path.is_file():
        try:
            print("Loading model: bike_price_demo", flush=True)

            artifact = joblib.load(demo_path)
            validate_price_artifact(artifact, "bike", demo=True)

            loaded["bike_price_demo"] = artifact
            locks["bike_price_demo"] = Lock()

            print("Loaded model: bike_price_demo", flush=True)

        except Exception:
            logging.exception("Failed to load bike_price_demo")
            failed.append("bike_price_demo")

    try:
        yield
    finally:
        loaded.clear()
        locks.clear()


app = FastAPI(
    title="AutoInspect AI",
    version="0.4.0",
    lifespan=lifespan,
)


class VehicleRequest(BaseModel):
    model_config = ConfigDict(extra="forbid", allow_inf_nan=False)

    vehicle_type: Literal["car", "bike"]
    make: str = Field(min_length=1, max_length=80)
    model: str = Field(min_length=1, max_length=100)
    year: int = Field(ge=1950, le=datetime.now().year + 1)
    mileage_km: float = Field(ge=0)
    reviewed_repair_allowance_lkr: float = Field(default=0, ge=0)


def get_model(vehicle, kind):
    key = f"{vehicle}_{kind}"

    if key not in loaded:
        raise HTTPException(
            503,
            detail=(
                f"{key} model unavailable. "
                "Train/install it and restart the API."
            ),
        )

    return loaded[key]


@app.get("/health")
def health():
    return {
        "status": "ok",
        "service": "autoinspect-ai",
    }


@app.get("/ready")
def ready():
    # This reports local loading/configuration, not a live cloud health check.
    expected_local = [
        f"{vehicle}_{kind}"
        for vehicle in VEHICLES
        for kind in KINDS
        if (vehicle, kind) != ("bike", "damage")
    ]
    missing = [key for key in expected_local if key not in loaded]
    configured = gemini_configured()
    if not configured:
        missing.append("bike_damage_gemini")

    return {
        "all_models_loaded": all(key in loaded for key in expected_local),
        "all_dependencies_configured": not missing,
        "available": sorted(loaded),
        "missing": missing,
        "load_failures": list(failed),
        "damage_providers": {
            "car": {"provider": "local_onnx", "loaded": "car_damage" in loaded},
            "bike": {
                "provider": "google_gemini",
                "configured": configured,
                "connection_verified": False,
                "connection_status": "not_checked_by_this_endpoint",
            },
        },
        "price_units_verified": {
            vehicle: price_units_verified(loaded.get(f"{vehicle}_price"))
            for vehicle in VEHICLES
        },
        "ready_for_price_demo": (
            "car_price" in loaded and "bike_price_demo" in loaded
        ),
        "note": (
            "all_models_loaded refers to required local models only. "
            "Gemini configuration does not verify key validity, model access or quota. "
            "ONNX initializes on first prediction. Full inspection also requires "
            "audio/price models and verified price units. Availability does not "
            "establish accuracy."
        ),
    }


@app.post("/api/v1/valuation")
def valuation(req: VehicleRequest):
    artifact = get_model(req.vehicle_type, "price")
    require_verified_price(artifact)

    row = price_row(
        artifact,
        req.make,
        req.model,
        req.year,
        req.mileage_km,
    )

    base = predict_price(
        f"{req.vehicle_type}_price",
        artifact,
        row,
    )

    return {
        "vehicle_type": req.vehicle_type,
        "currency": "LKR",
        "base_estimate_lkr": round(base, 2),
        "reviewed_repair_allowance_lkr": (
            req.reviewed_repair_allowance_lkr
        ),
        "adjusted_estimate_lkr": round(
            max(0, base - req.reviewed_repair_allowance_lkr),
            2,
        ),
        "model_version": f"{req.vehicle_type}_price_v1",
        "estimate_type": "historical_listing_asking_price",
        "adjustment_method": (
            "Explicit caller-supplied reviewed allowance; "
            "not learned from images/audio"
        ),
        "notice": (
            "Prototype estimate. "
            "Not a current-market or certified valuation."
        ),
    }


def read_upload(file, max_bytes=10 * 1024 * 1024):
    data = file.file.read(max_bytes + 1)

    if len(data) > max_bytes:
        raise HTTPException(413, "File is larger than 10 MiB.")

    if not data:
        raise HTTPException(422, "Empty upload.")

    return data


def detect(vehicle, file):
    if vehicle == "bike":
        return detect_bike_gemini(file)

    model = get_model(vehicle, "damage")
    raw = read_upload(file)

    try:
        with warnings.catch_warnings():
            warnings.simplefilter(
                "error",
                Image.DecompressionBombWarning,
            )

            with Image.open(BytesIO(raw)) as source:
                if source.format not in ["JPEG", "PNG"]:
                    raise ValueError(
                        "Only JPEG and PNG are supported."
                    )

                if source.width * source.height > 20_000_000:
                    raise ValueError(
                        "Image exceeds 20 megapixels."
                    )

                image = ImageOps.exif_transpose(source).convert("RGB")

    except (
        UnidentifiedImageError,
        OSError,
        ValueError,
        Image.DecompressionBombError,
        Image.DecompressionBombWarning,
    ):
        raise HTTPException(
            422,
            "Use a valid JPEG/PNG image below 20 megapixels.",
        ) from None

    try:
        with locks[f"{vehicle}_damage"]:
            prediction = model.predict(
                source=image,
                conf=0.25,
                imgsz=640,
                device="cpu",
                verbose=False,
            )[0]

        detections = []

        if prediction.boxes is not None:
            for box in prediction.boxes:
                class_id = int(box.cls.item())

                detections.append({
                    "label": prediction.names[class_id],
                    "confidence": float(box.conf.item()),
                    "bbox": box.xyxyn[0].tolist(),
                })

    except Exception:
        logging.exception(
            "Damage prediction failed for %s",
            vehicle,
        )
        raise HTTPException(
            500,
            "Damage prediction failed. Check the server terminal "
            "for model compatibility, input-shape or memory errors.",
        ) from None

    return {
        "vehicle_type": vehicle,
        "model_version": f"{vehicle}_damage_v1",
        "image_width": image.width,
        "image_height": image.height,
        "coordinate_format": "xyxy_normalized",
        "orientation": "EXIF corrected",
        "detections": detections,
        "notice": (
            "Experimental visual predictions. No detections does "
            "not establish a damage-free or structurally safe vehicle."
        ),
    }


@app.post("/api/v1/damage")
def damage(
    vehicle_type: Literal["car", "bike"] = Form(...),
    image: UploadFile = File(...),
):
    return detect(vehicle_type, image)


def classify_audio(vehicle, file):
    artifact = get_model(vehicle, "audio")

    try:
        features = audio_features(BytesIO(read_upload(file)))
    except (ValueError, RuntimeError):
        raise HTTPException(
            422,
            "Use a non-silent, unclipped 10-15 second WAV recording.",
        ) from None

    with locks[f"{vehicle}_audio"]:
        label = str(
            artifact["model"].predict(features.reshape(1, -1))[0]
        )

    return {
        "vehicle_type": vehicle,
        "model_version": f"{vehicle}_audio_v1",
        "predicted_label": label,
        "status": "experimental_classification",
        "notice": (
            "Uncalibrated sound classification; "
            "not a confirmed mechanical diagnosis."
        ),
    }


@app.post("/api/v1/audio")
def audio(
    vehicle_type: Literal["car", "bike"] = Form(...),
    audio: UploadFile = File(...),
):
    return classify_audio(vehicle_type, audio)


@app.post("/api/v1/inspection")
def inspection(
    metadata: str = Form(...),
    images: list[UploadFile] = File(...),
    audio: UploadFile = File(...),
):
    if len(metadata) > 8000:
        raise HTTPException(422, "Metadata is too long.")

    try:
        req = VehicleRequest.model_validate_json(metadata)
    except ValidationError:
        raise HTTPException(
            422,
            "Metadata must be a valid VehicleRequest JSON string.",
        ) from None

    if not 1 <= len(images) <= 6:
        raise HTTPException(422, "Upload 1-6 images.")

    # Check required models before doing expensive work.
    for kind in KINDS:
        if req.vehicle_type == "bike" and kind == "damage":
            if not gemini_configured():
                raise HTTPException(
                    503, "Set GEMINI_API_KEY in backend/.env and restart."
                )
            continue
        get_model(req.vehicle_type, kind)

    price = valuation(req)

    photos = [
        {
            "image_index": index,
            **detect(req.vehicle_type, file),
        }
        for index, file in enumerate(images)
    ]

    sound = classify_audio(req.vehicle_type, audio)
    count = sum(len(photo["detections"]) for photo in photos)

    return {
        "vehicle_type": req.vehicle_type,
        "damage": photos,
        "audio": sound,
        "valuation": price,
        "voice_summary": (
            f"Inspection processing completed. "
            f"{count} possible visual findings across the photos. "
            f'The experimental engine sound label is '
            f'{sound["predicted_label"]}. '
            "Please review the findings. "
            "This report is not a mechanical safety certificate."
        ),
    }


class CarDemoRequest(BaseModel):
    model_config = ConfigDict(extra="forbid", allow_inf_nan=False)

    make: str = Field(min_length=1, max_length=80)
    model: str = Field(min_length=1, max_length=100)
    year: int = Field(ge=1950, le=datetime.now().year + 1)
    mileage_km: float = Field(ge=0)


class BikeDemoRequest(BaseModel):
    model_config = ConfigDict(extra="forbid", allow_inf_nan=False)

    name: str = Field(min_length=1, max_length=160)
    year: int = Field(ge=1950, le=datetime.now().year + 1)
    km_driven: float = Field(ge=0)


@app.post(
    "/api/v1/demo/car-price",
    tags=["Experimental prices"],
)
def demo_car_price(req: CarDemoRequest):
    artifact = get_model("car", "price")

    row = price_row(
        artifact,
        req.make,
        req.model,
        req.year,
        req.mileage_km,
    )

    verified = price_units_verified(artifact)

    return {
        "vehicle_type": "car",
        "prediction": round(
            predict_price("car_price", artifact, row),
            2,
        ),
        "currency": "LKR" if verified else None,
        "unit_status": (
            "verified_LKR"
            if verified
            else "unverified_assumed_LKR_scale"
        ),
        "price_units_verified": verified,
        "experimental": True,
        "model_version": "car_price_v1",
        "notice": (
            "Historical asking-price prototype. Verify source "
            "price units before interpreting unverified output as LKR."
        ),
    }


@app.post(
    "/api/v1/demo/bike-price",
    tags=["Experimental prices"],
)
def demo_bike_price(req: BikeDemoRequest):
    artifact = get_model("bike", "price_demo")
    name = " ".join(req.name.strip().lower().split())

    encoder = (
        artifact["model"]
        .named_steps["preprocess"]
        .named_transformers_["name"]
    )

    if name not in encoder.categories_[0]:
        raise HTTPException(
            422,
            "This bike name was not present in training. "
            "Use its exact training name.",
        )

    row = pd.DataFrame([{
        "name": name,
        "year": req.year,
        "km_driven": req.km_driven,
    }])

    return {
        "vehicle_type": "bike",
        "prediction": round(
            predict_price("bike_price_demo", artifact, row),
            2,
        ),
        "currency": None,
        "unit_status": "original_dataset_units_unverified",
        "price_units_verified": False,
        "experimental": True,
        "model_version": "bike_price_demo_v1",
        "notice": (
            "Original source units without currency conversion. "
            "Not a Sri Lankan LKR valuation."
        ),
    }