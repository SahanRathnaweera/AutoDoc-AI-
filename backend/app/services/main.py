from contextlib import asynccontextmanager
from datetime import datetime
from io import BytesIO
from threading import Lock
from typing import Literal
import logging
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


@asynccontextmanager
async def lifespan(app):
    loaded.clear()
    failed.clear()
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
                    loaded[key] = joblib.load(path)
                locks[key] = Lock()
            except Exception:
                logging.exception('Failed to load %s', key)
                failed.append(key)
    yield
    loaded.clear()


app = FastAPI(title='AutoInspect AI', version='0.2.0', lifespan=lifespan)


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
            'load_failures': failed}


@app.post('/api/v1/valuation')
def valuation(req: VehicleRequest):
    artifact = get_model(req.vehicle_type, 'price')
    make, model = req.make.strip().lower(), req.model.strip().lower()
    if [make, model] not in artifact['pairs']:
        raise HTTPException(422, 'This make/model pair was not present in the training set.')
    lo, hi = artifact['year_range']
    ml, mh = artifact['mileage_range']
    if not lo <= req.year <= hi or not ml <= req.mileage_km <= mh:
        raise HTTPException(422, 'Year/mileage is outside the training range.')
    row = pd.DataFrame([[make, model, req.year, req.mileage_km]], columns=FEATURES)
    base = float(artifact['model'].predict(row)[0])
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
    photos = [{'image_index': i, **detect(req.vehicle_type, f)} for i, f in enumerate(images)]
    sound = classify_audio(req.vehicle_type, audio)
    price = valuation(req)
    count = sum(len(x['detections']) for x in photos)
    return {'vehicle_type': req.vehicle_type, 'damage': photos, 'audio': sound, 'valuation': price,
        'voice_summary': f'Inspection processing completed. {count} visual detections across the photos. '
            f'The experimental engine sound label is {sound["predicted_label"]}. '
            'Please review the findings. This report is not a mechanical safety certificate.'}
