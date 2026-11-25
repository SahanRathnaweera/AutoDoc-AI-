from pathlib import Path
import json
import shutil
import subprocess

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
MODELS = ROOT / 'models'
FEATURES = ['make', 'model', 'year', 'mileage_km']


def audio_features(
    source,
    *,
    min_duration=10.0,
    max_duration=15.1,
    window_seconds=5.0,
):
    """Extract MFCC features from a fixed central audio window."""
    import audioread
    import librosa
    import soundfile as sf
    import tempfile

    if hasattr(source, "read"):
        source.seek(0)
        with tempfile.TemporaryDirectory() as directory:
            audio_path = Path(directory) / "inspection-audio"
            audio_path.write_bytes(source.read())
            y, sr = _load_audio(librosa, audioread, sf, audio_path)
    else:
        y, sr = _load_audio(librosa, audioread, sf, source)

    channels = 1 if y.ndim == 1 else y.shape[0]
    duration = y.shape[-1] / sr

    if duration < min_duration:
        raise ValueError(f"Audio must be at least {min_duration} seconds.")

    if max_duration is not None and duration > max_duration:
        raise ValueError(f"Audio must not exceed {max_duration} seconds.")

    if sr > 96000 or channels > 2:
        raise ValueError("Use mono/stereo audio at 96 kHz or below.")

    if not np.isfinite(y).all() or np.max(np.abs(y)) < 1e-4:
        raise ValueError("Audio is invalid or silent. Record again.")

    if np.mean(np.abs(y) >= 0.999) > 0.02:
        raise ValueError("Audio is clipping. Move the microphone farther away.")

    if y.ndim > 1:
        y = librosa.to_mono(y)

    if sr != 16000:
        y = librosa.resample(y, orig_sr=sr, target_sr=16000)

    target_samples = int(window_seconds * 16000)

    if len(y) < target_samples:
        raise ValueError("Audio is too short for the feature window.")

    crop_start = (len(y) - target_samples) // 2
    y = y[crop_start:crop_start + target_samples]

    mfcc = librosa.feature.mfcc(y=y, sr=16000, n_mfcc=20)

    return np.concatenate([
        mfcc.mean(axis=1),
        mfcc.std(axis=1),
    ]).astype("float32")


def _load_audio(librosa, audioread, soundfile, source):
    try:
        return librosa.load(source, sr=None, mono=False)
    except (
        audioread.NoBackendError,
        audioread.DecodeError,
        soundfile.LibsndfileError,
        ValueError,
        RuntimeError,
        OSError,
        EOFError,
    ):
        return _load_audio_ffmpeg(source)


def _load_audio_ffmpeg(source):
    ffmpeg = shutil.which('ffmpeg')
    ffprobe = shutil.which('ffprobe')
    if ffmpeg is None or ffprobe is None:
        raise ValueError(
            'Could not decode this audio format. Install FFmpeg and ensure '
            'both ffmpeg and ffprobe are available on PATH.'
        )

    try:
        probe = subprocess.run(
            [
                ffprobe,
                '-v', 'error',
                '-select_streams', 'a:0',
                '-show_entries', 'stream=sample_rate,channels',
                '-of', 'json',
                str(source),
            ],
            check=True,
            capture_output=True,
            text=True,
            timeout=30,
        )
        streams = json.loads(probe.stdout).get('streams', [])
        if not streams:
            raise ValueError('The selected file has no audio stream.')
        sample_rate = int(streams[0]['sample_rate'])
        channels = int(streams[0]['channels'])
        if sample_rate <= 0 or channels <= 0:
            raise ValueError('The audio stream has invalid format metadata.')

        decoded = subprocess.run(
            [
                ffmpeg,
                '-nostdin',
                '-v', 'error',
                '-i', str(source),
                '-map', '0:a:0',
                '-f', 'f32le',
                '-acodec', 'pcm_f32le',
                'pipe:1',
            ],
            check=True,
            capture_output=True,
            timeout=120,
        )
    except (
        subprocess.CalledProcessError,
        subprocess.TimeoutExpired,
        FileNotFoundError,
        KeyError,
        TypeError,
        ValueError,
        json.JSONDecodeError,
    ) as error:
        raise ValueError(
            'Could not decode this audio format. Use a readable audio file '
            'supported by the installed FFmpeg decoder.'
        ) from error

    samples = np.frombuffer(decoded.stdout, dtype='<f4')
    if samples.size == 0 or samples.size % channels:
        raise ValueError('The audio decoder returned invalid audio samples.')

    return samples.reshape(-1, channels).T, sample_rate
