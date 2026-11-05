import argparse
import json
import joblib
import numpy as np
import pandas as pd
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.svm import SVC
from sklearn.metrics import classification_report, confusion_matrix
from app.common import ROOT, MODELS, audio_features

p = argparse.ArgumentParser()
p.add_argument('--vehicle', choices=['car', 'bike'], required=True)
p.add_argument('--manifest', required=True)
a = p.parse_args()
d = pd.read_csv(ROOT / a.manifest)
required = {'path', 'label', 'vehicle_id', 'split'}
if not required.issubset(d.columns) or d[list(required)].isna().any().any():
    raise ValueError('Manifest requires path,label,vehicle_id,split with no empty fields.')
if set(d.split) != {'train', 'val', 'test'}:
    raise ValueError('Use train, val, test splits.')
if d.groupby('vehicle_id').split.nunique().max() > 1:
    raise ValueError('A vehicle crosses splits: data leakage.')
if d.groupby('path').split.nunique().max() > 1:
    raise ValueError('A recording crosses splits: data leakage.')
if d[d.split == 'train'].label.nunique() < 2:
    raise ValueError('At least two real labelled classes are required.')
labels = sorted(d[d.split == 'train'].label.unique())
for split in ['val', 'test']:
    if set(d[d.split == split].label) != set(labels):
        raise ValueError(f'{split} must contain all trained classes.')
X = np.stack([audio_features(ROOT / path) for path in d.path])
m = make_pipeline(StandardScaler(), SVC(kernel='rbf', class_weight='balanced', C=1.0))
m.fit(X[d.split == 'train'], d.loc[d.split == 'train', 'label'])
metrics = {}
for split in ['val', 'test']:
    pred = m.predict(X[d.split == split])
    actual = d.loc[d.split == split, 'label']
    metrics[split] = classification_report(actual, pred, output_dict=True, zero_division=0)
    metrics[split + '_confusion_matrix'] = confusion_matrix(actual, pred, labels=labels).tolist()
metadata = {'vehicle_type': a.vehicle, 'version': 'v1', 'labels': labels,
    'features': 'MFCC20 mean+std, mono 16kHz, 10-15s WAV', 'metrics': metrics,
    'limits': 'Uncalibrated experimental sound classification; no engine health percentage.'}
MODELS.mkdir(exist_ok=True)
joblib.dump({'model': m, 'metadata': metadata}, MODELS / f'{a.vehicle}_audio_v1.joblib', compress=3)
(ROOT / 'reports').mkdir(exist_ok=True)
(ROOT / 'reports' / f'{a.vehicle}_audio_v1.json').write_text(json.dumps(metadata, indent=2), encoding='utf-8')
print(json.dumps(metrics, indent=2))
