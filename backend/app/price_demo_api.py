"""Local experimental price-model API. Run on 127.0.0.1:8001."""
import logging
from contextlib import asynccontextmanager
from datetime import datetime
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse
from pydantic import BaseModel, ConfigDict, Field

ROOT = Path(__file__).resolve().parents[1]
MODEL_PATHS = {
    'car': ROOT / 'models/car_price_v1.joblib',
    'bike': ROOT / 'models/demo/bike_price_v1.joblib',
}
log = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app):
    app.state.models = {}
    app.state.model_status = {}
    for vehicle, path in MODEL_PATHS.items():
        if not path.is_file():
            app.state.model_status[vehicle] = 'missing'
            continue
        try:
            artifact = joblib.load(path)
            if not isinstance(artifact, dict) or not callable(getattr(artifact.get('model'), 'predict', None)):
                raise ValueError('Unexpected artifact format')
            if not isinstance(artifact.get('metadata'), dict):
                raise ValueError('Missing model metadata')
            if artifact['metadata'].get('vehicle_type') != vehicle:
                raise ValueError('Wrong vehicle model')
            app.state.models[vehicle] = artifact
            app.state.model_status[vehicle] = 'loaded'
        except Exception:
            log.exception('Could not load %s model', vehicle)
            app.state.model_status[vehicle] = 'load_error'
    yield
    app.state.models.clear()


app = FastAPI(
    title='AutoDoc Price Model Test API',
    description='Local experimental predictions. Car price scale is assumed and bike currency is unverified. Not a production valuation service.',
    version='0.1.0', lifespan=lifespan,
)


class CarInput(BaseModel):
    model_config = ConfigDict(extra='forbid')
    make: str = Field(min_length=1, max_length=80)
    model: str = Field(min_length=1, max_length=120)
    year: int = Field(ge=1950, le=datetime.now().year + 1)
    mileage_km: float = Field(ge=0, le=5_000_000, allow_inf_nan=False)


class BikeInput(BaseModel):
    model_config = ConfigDict(extra='forbid')
    name: str = Field(min_length=1, max_length=160)
    year: int = Field(ge=1950, le=datetime.now().year + 1)
    km_driven: float = Field(ge=0, le=5_000_000, allow_inf_nan=False)


def get_model(request, vehicle):
    artifact = request.app.state.models.get(vehicle)
    if artifact is None:
        raise HTTPException(503, f'{vehicle} model is not loaded. Check /ready and server logs; restart after fixing the file.')
    return artifact


def predict(artifact, row):
    try:
        value = float(artifact['model'].predict(pd.DataFrame([row]))[0])
        if not np.isfinite(value) or value <= 0:
            raise ValueError('Invalid prediction')
        return round(value, 2)
    except Exception:
        log.exception('Model prediction failed')
        raise HTTPException(500, 'Prediction failed. Check server logs and model/package compatibility.') from None


@app.get('/health')
def health():
    return {'status': 'ok', 'mode': 'local_experimental'}


@app.get('/ready')
def ready(request: Request):
    loaded = all(status == 'loaded' for status in request.app.state.model_status.values())
    return JSONResponse(status_code=200 if loaded else 503, content={
        'ready_for_demo': loaded,
        'models': request.app.state.model_status,
        'ready_for_production': False,
    })


@app.post('/demo/car-price')
def car_price(body: CarInput, request: Request):
    artifact = get_model(request, 'car')
    row = body.model_dump()
    row['make'] = row['make'].strip().lower()
    row['model'] = row['model'].strip().lower()
    pairs = artifact.get('pairs', [])
    if pairs and [row['make'], row['model']] not in pairs:
        raise HTTPException(422, 'This make/model pair was not present in training data.')
    for feature, key in [('year', 'year_range'), ('mileage_km', 'mileage_range')]:
        bounds = artifact.get(key)
        if bounds and not bounds[0] <= row[feature] <= bounds[1]:
            raise HTTPException(422, f'{feature} is outside the training range {bounds}.')
    return {
        'vehicle_type': 'car', 'prediction': predict(artifact, row),
        'currency': None, 'assumed_currency': 'LKR',
        'unit_status': 'unverified_assumed_LKR_scale',
        'experimental': True,
        'model_version': artifact['metadata'].get('version', 'unknown'),
        'note': 'Uses the configured price multiplier; verify source units before interpreting this as LKR. Historical asking-price model, not a certified valuation.',
    }


@app.post('/demo/bike-price')
def bike_price(body: BikeInput, request: Request):
    artifact = get_model(request, 'bike')
    row = body.model_dump()
    row['name'] = ' '.join(row['name'].strip().lower().split())
    encoder = artifact['model'].named_steps['preprocess'].named_transformers_['name']
    if row['name'] not in encoder.categories_[0]:
        raise HTTPException(422, 'This bike name was not present in training data; use the exact training name.')
    return {
        'vehicle_type': 'bike', 'prediction': predict(artifact, row),
        'currency': None, 'unit_status': 'original_dataset_units_unverified',
        'experimental': True,
        'model_version': artifact['metadata'].get('version', 'unknown'),
        'note': 'No currency conversion applied. This is not a Sri Lankan LKR valuation.',
    }
