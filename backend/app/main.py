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

loaded = {}
failed = []
locks = {}
KINDS = ['price', 'audio', 'damage']
VEHICLES = ['car', 'bike']


def validate_price_artifact(artifact, vehicle, demo=False):
    if not isinstance(artifact, dict) or not callable(getattr(artifact.get('model'), 'predict', None)):
        raise ValueError('Invalid price model artifact')
    metadata = artifact.get('metadata', {})
    if metadata.get('vehicle_type') != vehicle:
        raise ValueError('Wrong vehicle type in price model')
    expected = ['name', 'year', 'km_driven'] if demo else list(FEATURES)
    if metadata.get('features') != expected:
        raise ValueError('Price artifact has an incompatible input schema')
    if demo:
        artifact['model'].named_steps['preprocess'].named_transformers_['name'].categories_
    else:
        for key in ['pairs', 'year_range', 'mileage_range']:
            if key not in artifact:
                raise ValueError(f'Price artifact is missing {key}')


def price_units_verified(artifact):
    if not artifact:
        return False
    meta = artifact.get('metadata', {})
    flag = meta.get('price_units_verified', meta.get('config', {}).get('price_units_verified', False))
    return meta.get('currency') == 'LKR' and flag is True


def require_verified_price(artifact):
    if not price_units_verified(artifact):
        raise HTTPException(503, 'LKR price units are not verified in this saved model. Use /api/v1/demo/car-price or /api/v1/demo/bike-price for experimental testing. Verify dataset units and retrain before using valuation.')


def price_row(artifact, make, model, year, mileage_km):
    make, model = make.strip().lower(), model.strip().lower()
    if [make, model] not in artifact['pairs']:
        raise HTTPException(422, 'This make/model pair was not present in the training set.')
    lo, hi = artifact['year_range']
    ml, mh = artifact['mileage_range']
    if not lo <= year <= hi or not ml <= mileage_km <= mh:
        raise HTTPException(422, 'Year/mileage is outside the training range.')
    return pd.DataFrame([[make, model, year, mileage_km]], columns=FEATURES)


def predict_price(key, artifact, row):
    try:
        with locks[key]:
            value = float(artifact['model'].predict(row)[0])
        if not math.isfinite(value) or value <= 0:
            raise ValueError('Invalid prediction value')
        return value
    except Exception:
        logging.exception('Prediction failed for %s', key)
        raise HTTPException(500, 'Price prediction failed. Check server logs and model/package compatibility.') from None


@asynccontextmanager
async def lifespan(app):
    loaded.clear()
    failed.clear()
    locks.clear()
    for vehicle in VEHICLES:
        for kind in KINDS:
            key = f'{vehicle}_{kind}'
            ext = 'pt' if kind == 'damage' else 'joblib'
            path = MODELS / f'{key}_v1.{ext}'
            if not path.exists():
                continue
            try:
                # Load ONLY your team's trusted model artifacts.
                if kind == 'damage':
                    from ultralytics import YOLO
                    loaded[key] = YOLO(str(path))
                else:
                    artifact = joblib.load(path)
                    if kind == "price":
                        validate_price_artifact(artifact, vehicle)
                    loaded[key] = artifact
                locks[key] = Lock()
            except Exception:
                logging.exception('Failed to load %s', key)
                failed.append(key)
    demo_path = MODELS / 'demo' / 'bike_price_v1.joblib'
    if demo_path.is_file():
        try:
            artifact = joblib.load(demo_path)
            validate_price_artifact(artifact, 'bike', demo=True)
            loaded['bike_price_demo'] = artifact
            locks['bike_price_demo'] = Lock()
        except Exception:
            logging.exception('Failed to load bike_price_demo')
            failed.append('bike_price_demo')
    try:
        yield
    finally:
        loaded.clear()
        locks.clear()


app = FastAPI(title='AutoInspect AI', version='0.3.0', lifespan=lifespan)


class VehicleRequest(BaseModel):
    model_config = ConfigDict(extra='forbid', allow_inf_nan=False)
    vehicle_type: Literal['car', 'bike']
    make: str = Field(min_length=1, max_length=80)
    model: str = Field(min_length=1, max_length=100)
    year: int = Field(ge=1950, le=datetime.now().year + 1)
    mileage_km: float = Field(ge=0)
    reviewed_repair_allowance_lkr: float = Field(default=0, ge=0)


def get_model(vehicle, kind):
    key = f'{vehicle}_{kind}'
    if key not in loaded:
        raise HTTPException(503, detail=f'{key} model unavailable. Train/install it and restart the API.')
    return loaded[key]


@app.get('/health')
def health():
    return {'status': 'ok', 'service': 'autoinspect-ai'}


@app.get('/ready')
def ready():
    expected = [f'{v}_{k}' for v in VEHICLES for k in KINDS]
    return {'all_models_loaded': all(k in loaded for k in expected),
            'available': sorted(loaded), 'missing': [k for k in expected if k not in loaded],
            'load_failures': list(failed),
            'price_units_verified': {v: price_units_verified(loaded.get(f'{v}_price')) for v in VEHICLES},
            'ready_for_price_demo': 'car_price' in loaded and 'bike_price_demo' in loaded,
            'note': 'Loaded models do not establish validated accuracy. Missing damage/audio models still prevent a full inspection.'}


@app.post('/api/v1/valuation')
def valuation(req: VehicleRequest):
    artifact = get_model(req.vehicle_type, 'price')
    require_verified_price(artifact)
    row = price_row(artifact, req.make, req.model, req.year, req.mileage_km)
    base = predict_price(f'{req.vehicle_type}_price', artifact, row)
    return {'vehicle_type': req.vehicle_type, 'currency': 'LKR',
        'base_estimate_lkr': round(base, 2),
        'reviewed_repair_allowance_lkr': req.reviewed_repair_allowance_lkr,
        'adjusted_estimate_lkr': round(max(0, base - req.reviewed_repair_allowance_lkr), 2),
        'model_version': f'{req.vehicle_type}_price_v1',
        'estimate_type': 'historical_listing_asking_price',
        'adjustment_method': 'Explicit caller-supplied reviewed allowance; not learned from images/audio',
        'notice': 'Prototype estimate. Not a current-market or certified valuation.'}


def read_upload(file, max_bytes=10 * 1024 * 1024):
    data = file.file.read(max_bytes + 1)
    if len(data) > max_bytes:
        raise HTTPException(413, 'File is larger than 10 MiB.')
    if not data:
        raise HTTPException(422, 'Empty upload.')
    return data


def detect(vehicle, file):
    model = get_model(vehicle, 'damage')
    raw = read_upload(file)
    try:
        with warnings.catch_warnings():
            warnings.simplefilter('error', Image.DecompressionBombWarning)
            with Image.open(BytesIO(raw)) as source:
                if source.format not in ['JPEG', 'PNG']:
                    raise ValueError('Only JPEG and PNG are supported.')
                if source.width * source.height > 20_000_000:
                    raise ValueError('Image exceeds 20 megapixels.')
                image = ImageOps.exif_transpose(source).convert('RGB')
    except (UnidentifiedImageError, OSError, ValueError, Image.DecompressionBombError,
            Image.DecompressionBombWarning):
        raise HTTPException(422, 'Use a valid JPEG/PNG image below 20 megapixels.')
    with locks[f'{vehicle}_damage']:
        prediction = model.predict(image, conf=0.25, device='cpu', verbose=False)[0]
    detections = []
    for box in prediction.boxes:
        detections.append({'label': prediction.names[int(box.cls.item())],
            'confidence': float(box.conf.item()), 'bbox': box.xyxyn[0].tolist()})
    return {'vehicle_type': vehicle, 'model_version': f'{vehicle}_damage_v1',
        'image_width': image.width, 'image_height': image.height,
        'coordinate_format': 'xyxy_normalized', 'orientation': 'EXIF corrected',
        'detections': detections,
        'notice': 'No detections does not establish a damage-free or structurally safe vehicle.'}


@app.post('/api/v1/damage')
def damage(vehicle_type: Literal['car', 'bike'] = Form(...), image: UploadFile = File(...)):
    return detect(vehicle_type, image)


def classify_audio(vehicle, file):
    artifact = get_model(vehicle, 'audio')
    try:
        features = audio_features(BytesIO(read_upload(file)))
    except (ValueError, RuntimeError):
        raise HTTPException(422, 'Use a non-silent, unclipped 10-15 second WAV recording.')
    label = str(artifact['model'].predict(features.reshape(1, -1))[0])
    return {'vehicle_type': vehicle, 'model_version': f'{vehicle}_audio_v1',
        'predicted_label': label, 'status': 'experimental_classification',
        'notice': 'Uncalibrated sound classification; not a confirmed mechanical diagnosis.'}


@app.post('/api/v1/audio')
def audio(vehicle_type: Literal['car', 'bike'] = Form(...), audio: UploadFile = File(...)):
    return classify_audio(vehicle_type, audio)


@app.post('/api/v1/inspection')
def inspection(metadata: str = Form(...), images: list[UploadFile] = File(...),
               audio: UploadFile = File(...)):
    if len(metadata) > 8000:
        raise HTTPException(422, 'Metadata is too long.')
    try:
        req = VehicleRequest.model_validate_json(metadata)
    except ValidationError:
        raise HTTPException(422, 'Metadata must be a valid VehicleRequest JSON string.')
    if not 1 <= len(images) <= 6:
        raise HTTPException(422, 'Upload 1-6 images.')
    # Check required models before doing expensive work.
    for kind in KINDS:
        get_model(req.vehicle_type, kind)
    price = valuation(req)
    photos = [{'image_index': i, **detect(req.vehicle_type, f)} for i, f in enumerate(images)]
    sound = classify_audio(req.vehicle_type, audio)
    count = sum(len(x['detections']) for x in photos)
    return {'vehicle_type': req.vehicle_type, 'damage': photos, 'audio': sound, 'valuation': price,
        'voice_summary': f'Inspection processing completed. {count} visual detections across the photos. '
            f'The experimental engine sound label is {sound["predicted_label"]}. '
            'Please review the findings. This report is not a mechanical safety certificate.'}


class CarDemoRequest(BaseModel):
    model_config = ConfigDict(extra='forbid', allow_inf_nan=False)
    make: str = Field(min_length=1, max_length=80)
    model: str = Field(min_length=1, max_length=100)
    year: int = Field(ge=1950, le=datetime.now().year + 1)
    mileage_km: float = Field(ge=0)


class BikeDemoRequest(BaseModel):
    model_config = ConfigDict(extra='forbid', allow_inf_nan=False)
    name: str = Field(min_length=1, max_length=160)
    year: int = Field(ge=1950, le=datetime.now().year + 1)
    km_driven: float = Field(ge=0)


@app.post('/api/v1/demo/car-price', tags=['Experimental prices'])
def demo_car_price(req: CarDemoRequest):
    artifact = get_model('car', 'price')
    row = price_row(artifact, req.make, req.model, req.year, req.mileage_km)
    verified = price_units_verified(artifact)
    return {
        'vehicle_type': 'car',
        'prediction': round(predict_price('car_price', artifact, row), 2),
        'currency': 'LKR' if verified else None,
        'unit_status': 'verified_LKR' if verified else 'unverified_assumed_LKR_scale',
        'price_units_verified': verified,
        'experimental': True,
        'model_version': 'car_price_v1',
        'notice': 'Historical asking-price prototype. Verify source price units before interpreting unverified output as LKR.',
    }


@app.post('/api/v1/demo/bike-price', tags=['Experimental prices'])
def demo_bike_price(req: BikeDemoRequest):
    artifact = get_model('bike', 'price_demo')
    name = ' '.join(req.name.strip().lower().split())
    encoder = artifact['model'].named_steps['preprocess'].named_transformers_['name']
    if name not in encoder.categories_[0]:
        raise HTTPException(422, 'This bike name was not present in training. Use its exact training name.')
    row = pd.DataFrame([{'name': name, 'year': req.year, 'km_driven': req.km_driven}])
    return {
        'vehicle_type': 'bike',
        'prediction': round(predict_price('bike_price_demo', artifact, row), 2),
        'currency': None,
        'unit_status': 'original_dataset_units_unverified',
        'price_units_verified': False,
        'experimental': True,
        'model_version': 'bike_price_demo_v1',
        'notice': 'Original source units without currency conversion. Not a Sri Lankan LKR valuation.',
    }
