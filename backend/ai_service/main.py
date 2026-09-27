from pathlib import Path
from typing import Any, Literal

import joblib
import pandas as pd
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel


BASE_DIR = Path(__file__).resolve().parent
MODEL_DIR = BASE_DIR / "models"

MODEL_PATHS = {
    "car": MODEL_DIR / "car_price_model.joblib",
    "bike": MODEL_DIR / "bike_price_model.joblib",
}

models = {}


def _is_git_lfs_pointer(model_path: Path) -> bool:
    header = model_path.read_bytes()[:200]
    return (
        b"version https://git-lfs.github.com/spec/v1" in header
        and b"oid sha256:" in header
        and b"size " in header
    )


for vehicle_type, model_path in MODEL_PATHS.items():
    if not model_path.exists():
        raise FileNotFoundError(f"Model file not found: {model_path}")
    if _is_git_lfs_pointer(model_path):
        raise RuntimeError(
            "Model artifact is a Git LFS pointer, not a downloaded model file: "
            f"{model_path}. Run 'git lfs install' and 'git lfs pull' in the "
            "repository root to fetch model artifacts before starting the API."
        )
    models[vehicle_type] = joblib.load(model_path)


app = FastAPI(
    title="AutoDoc AI Vehicle Price API",
    description="Predicts car and bike prices using trained models.",
    version="1.0.0",
)

# For local Flutter development.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class PricePredictionRequest(BaseModel):
    vehicle_type: Literal["car", "bike"]
    features: dict[str, Any]


@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "loaded_models": list(models.keys()),
    }


@app.get("/price/schema/{vehicle_type}")
def get_price_schema(vehicle_type: Literal["car", "bike"]):
    model = models[vehicle_type]
    columns = (
        model.named_steps["preprocessing"]
        .feature_names_in_
        .tolist()
    )

    return {
        "vehicle_type": vehicle_type,
        "required_features": columns,
    }


@app.post("/price/predict")
def predict_price(request: PricePredictionRequest):
    model = models[request.vehicle_type]

    required_columns = (
        model.named_steps["preprocessing"]
        .feature_names_in_
        .tolist()
    )

    missing_columns = [
        column
        for column in required_columns
        if column not in request.features
    ]

    if missing_columns:
        raise HTTPException(
            status_code=422,
            detail={
                "message": "Some required vehicle details are missing.",
                "missing_features": missing_columns,
            },
        )

    input_data = pd.DataFrame([request.features])
    input_data = input_data.reindex(columns=required_columns)

    try:
        predicted_price = float(model.predict(input_data)[0])
    except (TypeError, ValueError) as error:
        raise HTTPException(
            status_code=422,
            detail=f"Could not process the supplied vehicle details: {error}",
        )

    return {
        "vehicle_type": request.vehicle_type,
        "predicted_price": round(predicted_price, 2),
        "price_unit_note": (
            "The prediction uses the original price unit in the selected dataset."
        ),
        "voice_summary": (
            f"Estimated {request.vehicle_type} price is "
            f"{predicted_price:,.2f} in the dataset's original price unit."
        ),
    }