import argparse
import hashlib
import json
import platform
from datetime import datetime, timezone
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
from app.common import ROOT, MODELS, FEATURES


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--vehicle', choices=['car', 'bike'], required=True)
    p.add_argument('--csv', required=True)
    p.add_argument('--config', required=True)
    a = p.parse_args()
    cfg = json.loads((ROOT / a.config).read_text(encoding='utf-8-sig'))
    if cfg['currency'] != 'LKR':
        raise ValueError('Use a verified LKR dataset; no automatic currency conversion.')
    source = ROOT / a.csv
    raw = pd.read_csv(source)
    mapping = cfg['columns']
    keys = FEATURES + ['price_lkr']
    if set(mapping) != set(keys) or len(set(mapping.values())) != len(keys):
        raise ValueError('Map each required feature to a distinct source column.')
    missing = set(mapping.values()) - set(raw.columns)
    if missing:
        raise ValueError(f'Fix config. Missing source columns: {sorted(missing)}')
    d = raw[[mapping[k] for k in keys]].copy()
    d.columns = keys
    for c in ['make', 'model']:
        d[c] = d[c].astype('string').str.strip().str.lower()
        d[c] = d[c].replace('', pd.NA)
    # Deliberately strict: do not silently interpret lakhs, miles, "negotiable", etc.
    for c in ['year', 'mileage_km', 'price_lkr']:
        d[c] = pd.to_numeric(d[c].astype('string').str.replace(',', '', regex=False).str.strip(), errors='coerce')
    d['price_lkr'] *= float(cfg['price_multiplier'])
    d['mileage_km'] *= float(cfg['mileage_multiplier'])
    d = d.replace([np.inf, -np.inf], np.nan).dropna(subset=keys)
    year = datetime.now().year
    d = d[(d.year.between(1950, year + 1)) & (d.year % 1 == 0)
          & (d.mileage_km >= 0) & (d.price_lkr > 0)].copy()
    group_col = cfg.get('group_column')
    if group_col:
        if group_col not in raw:
            raise ValueError('Configured group column does not exist.')
        d['group'] = raw.loc[d.index, group_col].astype('string')
        if d.group.isna().any():
            raise ValueError('Vehicle/listing group IDs must not be missing.')
    else:
        # Keeps identical vehicle feature tuples together; real vehicle IDs are better.
        d['group'] = d[FEATURES].astype(str).agg('|'.join, axis=1)
    d = d.drop_duplicates(subset=keys)
    print(f'Raw rows: {len(raw)}, retained rows: {len(d)}')
    if len(d) < 100 or d.group.nunique() < 20:
        raise ValueError('Too few usable rows/groups. Inspect units and mappings first.')
    trainval, test = next(GroupShuffleSplit(n_splits=1, test_size=.2, random_state=42).split(d, groups=d.group))
    tv = d.iloc[trainval]
    tr, va = next(GroupShuffleSplit(n_splits=1, test_size=.25, random_state=43).split(tv, groups=tv.group))
    train, valid, test = tv.iloc[tr], tv.iloc[va], d.iloc[test]
    prep = ColumnTransformer([
        ('categories', OneHotEncoder(handle_unknown='ignore'), ['make', 'model']),
        ('numbers', 'passthrough', ['year', 'mileage_km'])
    ])
    model = Pipeline([('preprocess', prep), ('regressor', RandomForestRegressor(
        n_estimators=200, max_depth=18, min_samples_leaf=2, random_state=42, n_jobs=-1))])
    model.fit(train[FEATURES], train.price_lkr)
    metrics = {}
    for name, part in [('validation', valid), ('test', test)]:
        pred = model.predict(part[FEATURES])
        metrics[name + '_mae_lkr'] = float(mean_absolute_error(part.price_lkr, pred))
        metrics[name + '_baseline_mae_lkr'] = float(mean_absolute_error(
            part.price_lkr, np.full(len(part), train.price_lkr.median())))
    metadata = dict(vehicle_type=a.vehicle, version='v1', currency='LKR',
        target='historical_listing_asking_price', features=FEATURES, metrics=metrics,
        rows={'train': len(train), 'validation': len(valid), 'test': len(test)},
        python=platform.python_version(), sklearn=sklearn.__version__,
        trained_at=datetime.now(timezone.utc).isoformat(),
        dataset_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),
        split='grouped_random_60_20_20', config=cfg,
        limits='Historical listings, not verified sale prices; no learned damage/engine adjustment.')
    artifact = dict(model=model, metadata=metadata,
        pairs=train[['make', 'model']].drop_duplicates().values.tolist(),
        year_range=[int(train.year.min()), int(train.year.max())],
        mileage_range=[float(train.mileage_km.min()), float(train.mileage_km.max())])
    MODELS.mkdir(exist_ok=True)
    name = a.vehicle + '_price_v1'
    joblib.dump(artifact, MODELS / (name + '.joblib'), compress=3)
    reports = ROOT / 'reports'
    reports.mkdir(exist_ok=True)
    (reports / (name + '.json')).write_text(json.dumps(metadata, indent=2), encoding='utf-8')
    print(json.dumps(metrics, indent=2))
    print('Saved:', MODELS / (name + '.joblib'))
    print('Compare MAE with baseline. This is a prototype, not a certified valuation.')

if __name__ == '__main__':
    main()
