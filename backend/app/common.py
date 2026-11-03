from pathlib import Path
import json
import shutil
import subprocess

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
MODELS = ROOT / 'models'
FEATURES = ['make', 'model', 'year', 'mileage_km']


def audio_features(source):
    # Decode common audio formats before extracting the shared training features.
    import audioread
    import librosa
    import soundfile as sf
    import tempfile

    if hasattr(source, 'read'):
        source.seek(0)
        with tempfile.TemporaryDirectory() as directory:
            audio_path = Path(directory) / 'inspection-audio'
            audio_path.write_bytes(source.read())
            source_path = audio_path
            y, sr = _load_audio(librosa, audioread, sf, source_path)
    else:
        y, sr = _load_audio(librosa, audioread, sf, source)

    channels = 1 if y.ndim == 1 else y.shape[0]
    duration = y.shape[-1] / sr
    if not 10 <= duration <= 15.1:
        raise ValueError('Record 10-15 seconds of audio.')
    if sr > 96000 or channels > 2:
        raise ValueError('Use mono/stereo audio at 96 kHz or below.')
    if y.ndim > 1:
        y = librosa.to_mono(y)
    if not np.isfinite(y).all() or np.max(np.abs(y)) < 1e-4:
        raise ValueError('Audio is invalid or silent. Record again.')
    if np.mean(np.abs(y) >= 0.999) > 0.02:
        raise ValueError('Audio is clipping. Move the microphone farther away.')
    y = librosa.resample(y, orig_sr=sr, target_sr=16000)
    mfcc = librosa.feature.mfcc(y=y, sr=16000, n_mfcc=20)
    return np.concatenate([mfcc.mean(axis=1), mfcc.std(axis=1)]).astype('float32')


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
