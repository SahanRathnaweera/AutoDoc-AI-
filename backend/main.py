from pathlib import Path
from uuid import uuid4

from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="AutoDoc AI - Engine Audio API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOAD_DIR = Path(__file__).parent / "uploads" / "engine_audio"
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

ALLOWED_EXTENSIONS = {".wav", ".m4a", ".mp3", ".aac"}


@app.get("/")
def home():
    return {"message": "AutoDoc AI API is running"}


@app.get("/health")
def health():
    return {"status": "healthy"}


@app.post("/api/engine-audio/upload")
async def upload_engine_audio(file: UploadFile = File(...)):
    extension = Path(file.filename or "").suffix.lower()

    if extension not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail="Unsupported audio format",
        )

    content = await file.read()

    if not content:
        raise HTTPException(status_code=400, detail="Empty audio file")

    if len(content) > 20 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="File is too large")

    filename = f"{uuid4().hex}{extension}"
    file_path = UPLOAD_DIR / filename
    file_path.write_bytes(content)

    return {
        "message": "Audio uploaded successfully",
        "filename": filename,
        "size_bytes": len(content),
        "status": "uploaded",
    }