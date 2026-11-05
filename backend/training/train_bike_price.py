"""Train the supplied bike CSV in its ORIGINAL, unverified price units."""
import argparse
import hashlib
import json
import platform
from datetime import datetime, timezone
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
import sklearn
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_absolute_error
from sklearn.model_selection import GroupShuffleSplit
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder

ROOT = Path(__file__).resolve().parents[1]
FEATURES = ['name', 'year', 'km_driven']


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--csv', required=True)
    parser.add_argument('--config', default='config/bike_price.json')
    args = parser.parse_args()
    source = ROOT / args.csv
    config_path = ROOT / args.config
    if not source.is_file():
        parser.error(f'CSV not found: {source}')
    if not config_path.is_file():
        parser.error(f'Config not found: {config_path}')
    cfg = json.loads(config_path.read_text(encoding='utf-8-sig'))
    columns = cfg['columns']
    required = FEATURES + ['price']
    if set(columns) != set(required) or len(set(columns.values())) != len(required):
        parser.error('Config must map name, year, km_driven and price to distinct CSV columns.')
    print(f'Reading: {source}', flush=True)
    raw = pd.read_csv(source, low_memory=False)
    raw.columns = raw.columns.str.strip()
    missing = set(columns.values()) - set(raw.columns)
    if missing:
        parser.error(f'Missing CSV columns: {sorted(missing)}')
    frame = raw[[columns[key] for key in required]].copy()
    frame.columns = required
    frame['name'] = frame['name'].astype('string').str.strip().str.lower().str.replace(r'\s+', ' ', regex=True).replace('', pd.NA)
    for key in ['year', 'km_driven', 'price']:
        frame[key] = pd.to_numeric(frame[key].astype('string').str.replace(',', '', regex=False).str.strip(), errors='coerce')
    frame = frame.replace([np.inf, -np.inf], np.nan).dropna(subset=required)
    frame = frame.loc[frame.year.between(1950, datetime.now().year + 1)
                      & frame.year.mod(1).eq(0) & frame.km_driven.ge(0)
                      & frame.price.gt(0)].drop_duplicates(subset=required).copy()
    groups = pd.util.hash_pandas_object(frame[FEATURES], index=False)
    if len(frame) < 100 or groups.nunique() < 20:
        parser.error('Too few usable rows/groups after cleaning; inspect the dataset.')
    train_indices, test_indices = next(GroupShuffleSplit(n_splits=1, test_size=0.2, random_state=42).split(frame, groups=groups))
    train, test = frame.iloc[train_indices], frame.iloc[test_indices]
    print(f'Raw rows: {len(raw)} | Retained: {len(frame)} | Train: {len(train)} | Test: {len(test)}', flush=True)
    print('Training in original source price units. Currency is UNVERIFIED; this is a demo model.', flush=True)
    pipeline = Pipeline([
        ('preprocess', ColumnTransformer([
            ('name', OneHotEncoder(handle_unknown='ignore'), ['name']),
            ('numeric', 'passthrough', ['year', 'km_driven'])
        ])),
        ('regressor', RandomForestRegressor(n_estimators=200, max_depth=18,
                         min_samples_leaf=2, random_state=42, n_jobs=-1))
    ])
    pipeline.fit(train[FEATURES], train.price)
    predictions = pipeline.predict(test[FEATURES])
    model_mae = float(mean_absolute_error(test.price, predictions))
    baseline_mae = float(mean_absolute_error(test.price, np.full(len(test), train.price.median())))
    metadata = {
        'vehicle_type': 'bike', 'version': 'demo-v1',
        'currency': 'UNVERIFIED', 'price_unit': 'original_CSV_units',
        'price_multiplier': 1, 'ready_for_lkr_api': False,
        'target': columns['price'], 'features': FEATURES,
        'rows': {'raw': len(raw), 'retained': len(frame), 'train': len(train), 'test': len(test)},
        'metrics': {'test_mae_source_units': model_mae, 'baseline_mae_source_units': baseline_mae},
        'beats_median_baseline': model_mae < baseline_mae,
        'dataset_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
        'trained_at': datetime.now(timezone.utc).isoformat(),
        'python_version': platform.python_version(), 'sklearn_version': sklearn.__version__,
        'split': '80/20 grouped by identical name, year and mileage; true vehicle IDs unavailable',
        'config': cfg,
        'limitations': 'Experimental source-market model. Currency and market need source verification. Not a Sri Lankan valuation. No repair-cost adjustment. No hyperparameter tuning.'
    }
    model_path = ROOT / 'models/demo/bike_price_v1.joblib'
    report_path = ROOT / 'reports/demo/bike_price_v1.json'
    model_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    joblib.dump({'model': pipeline, 'metadata': metadata}, model_path, compress=3)
    report_path.write_text(json.dumps(metadata, indent=2), encoding='utf-8')
    print(json.dumps(metadata['metrics'], indent=2))
    print(f'Saved: {model_path}')
    print(f'Report saved: {report_path}')


if __name__ == '__main__':
    main()
