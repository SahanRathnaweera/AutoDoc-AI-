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

parser = argparse.ArgumentParser()
parser.add_argument("--vehicle", choices=["car"], required=True)
parser.add_argument("--manifest", required=True)
args = parser.parse_args()

manifest_path = ROOT / args.manifest
dataset_root = manifest_path.parent

df = pd.read_csv(manifest_path, keep_default_na=False)

required = {"file_name", "label", "split", "group", "duration_s"}
if not required.issubset(df.columns):
    raise ValueError(f"Missing columns: {required - set(df.columns)}")

df["duration_s"] = pd.to_numeric(df["duration_s"], errors="raise")

# Exclude real_test from training and model selection.
df = df[df["split"].isin(["train", "validation", "test"])].copy()
df = df[df["duration_s"] >= 5.0].copy()

# Exclude two recordings flagged by the clipping check.
excluded_files = [
    "prepared/test/healthy/revix_car_clean_0065.wav",
    "prepared/test/healthy/revix_car_clean_0299.wav",
]

df = df[~df["file_name"].isin(excluded_files)].copy()

print("Excluded clipped recordings:", len(excluded_files))

if df.groupby("group")["split"].nunique().max() > 1:
    raise ValueError("Data leakage: a group crosses splits.")

labels = sorted(df[df["split"] == "train"]["label"].unique())

if len(labels) < 2:
    raise ValueError("At least two training classes are required.")

for split in ["train", "validation", "test"]:
    subset = df[df["split"] == split]
    if set(subset["label"]) != set(labels):
        raise ValueError(f"{split} does not contain all classes.")

paths = [dataset_root / name for name in df["file_name"]]

if not all(path.is_file() for path in paths):
    raise FileNotFoundError("One or more dataset audio files are missing.")

print("Usable recordings:")
print(df.groupby(["label", "split"]).size().unstack(fill_value=0))

print("\nExtracting features...")
X = np.stack([
    audio_features(
        path,
        min_duration=5.0,
        max_duration=None,
        window_seconds=5.0,
    )
    for path in paths
])

y = df["label"].to_numpy()
splits = df["split"].to_numpy()

model = make_pipeline(
    StandardScaler(),
    SVC(kernel="rbf", class_weight="balanced", C=1.0),
)

model.fit(X[splits == "train"], y[splits == "train"])

metrics = {}

for split in ["validation", "test"]:
    mask = splits == split
    predictions = model.predict(X[mask])

    metrics[split] = classification_report(
        y[mask],
        predictions,
        labels=labels,
        output_dict=True,
        zero_division=0,
    )

    metrics[split + "_confusion_matrix"] = confusion_matrix(
        y[mask],
        predictions,
        labels=labels,
    ).tolist()

metadata = {
    "vehicle_type": "car",
    "version": "v1",
    "labels": labels,
    "features": "MFCC20 mean+std",
    "sample_rate": 16000,
    "window_seconds": 5.0,
    "window_method": "central crop",
    "metrics": metrics,
    "limits": "Experimental sound classification; not a confirmed diagnosis.",
}

MODELS.mkdir(parents=True, exist_ok=True)
model_path = MODELS / "car_audio_v1.joblib"

joblib.dump(
    {"model": model, "metadata": metadata},
    model_path,
    compress=3,
)

report_dir = ROOT / "reports"
report_dir.mkdir(parents=True, exist_ok=True)
(report_dir / "car_audio_v1.json").write_text(
    json.dumps(metadata, indent=2),
    encoding="utf-8",
)

print("\nModel saved:", model_path)
print("\nEvaluation results:")
print(json.dumps(metrics, indent=2))
