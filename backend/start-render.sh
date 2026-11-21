#!/bin/sh
set -eu

cd "$(dirname "$0")"
export MALLOC_MMAP_THRESHOLD_=65536
export MALLOC_TRIM_THRESHOLD_=65536
export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=1
exec python -m uvicorn app.main:app --host 0.0.0.0 --port "${PORT:-10000}" --workers 1
