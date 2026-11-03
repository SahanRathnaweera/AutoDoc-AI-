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

## Flutter inspection report

The Flutter report screen submits vehicle metadata and 1-6 JPEG/PNG images to
`POST /api/v1/inspection`. A non-silent, unclipped 10-15 second audio recording
is optional.
Common formats such as WAV, MP3, M4A/AAC, FLAC, and OGG are accepted when
supported by the installed `soundfile` or FFmpeg audio decoder.
Install FFmpeg and ensure it is available on `PATH` to decode compressed
formats such as MP3 or M4A when they are not supported by the installed
libsndfile build.
Inspection reports can be partial. Available analysis models run normally;
missing car-price/audio models, unverified LKR price units, or unconfigured
motorcycle damage analysis are reported as unavailable instead of blocking
available analysis or inserting placeholder values. A car inspection can run
photo analysis with `models/car_damage_v1.onnx`; engine audio is optional when
no audio model is installed. Check `/ready` for model availability. Direct
valuation requests still require a compatible model with verified LKR units.

For local Flutter web testing, the API allows requests from `localhost` and
`127.0.0.1` origins. For a deployed frontend, configure an explicit production
CORS origin policy rather than exposing the development API publicly.

Run the Flutter app with `--dart-define=API_BASE_URL=<backend URL>`. Android
emulators reach the host computer at `http://10.0.2.2:8000`; physical devices
should use the host computer's LAN IP; Windows desktop and iOS simulators can
use `http://127.0.0.1:8000`.

## Layout

- `app/`: FastAPI application, schemas, and services
- `training/`: model-training scripts
- `models/`: generated model artifacts
- `data/raw/`: source datasets
- `data/processed/`: prepared datasets
- `reports/`: generated reports
- `tests/`: backend tests
