# AutoDoc AI Backend

Backend services and model-training entry points for AutoDoc AI.

## Setup

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

## Run the API

```powershell
uvicorn app.main:app --reload
```

The health endpoint is available at `http://127.0.0.1:8000/health`.

## Layout

- `app/`: FastAPI application, schemas, and services
- `training/`: model-training scripts
- `models/`: generated model artifacts
- `data/raw/`: source datasets
- `data/processed/`: prepared datasets
- `reports/`: generated reports
- `tests/`: backend tests
