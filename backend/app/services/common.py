from pathlib import Path
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
MODELS = ROOT / 'models'
FEATURES = ['make', 'model', 'year', 'mileage_km']


def audio_features(source):
    # Shared by training AND serving. Initial contract: 10-15 second WAV.
    import soundfile as sf
    import librosa
    with sf.SoundFile(source) as f:
        if f.format != 'WAV':
            raise ValueError('Only WAV audio is supported.')
        duration = len(f) / f.samplerate
        if not 10 <= duration <= 15.1:
            raise ValueError('Record 10-15 seconds of audio.')
        if f.samplerate > 96000 or f.channels > 2:
            raise ValueError('Use mono/stereo audio at 96 kHz or below.')
        y = f.read(dtype='float32', always_2d=True).mean(axis=1)
        sr = f.samplerate
    if not np.isfinite(y).all() or np.max(np.abs(y)) < 1e-4:
        raise ValueError('Audio is invalid or silent. Record again.')
    if np.mean(np.abs(y) >= 0.999) > 0.02:
        raise ValueError('Audio is clipping. Move the microphone farther away.')
    y = librosa.resample(y, orig_sr=sr, target_sr=16000)
    mfcc = librosa.feature.mfcc(y=y, sr=16000, n_mfcc=20)
    return np.concatenate([mfcc.mean(axis=1), mfcc.std(axis=1)]).astype('float32')
