"""Measure fresh single-worker HTTP runs without deploying either variant."""
import argparse
import json
import os
from pathlib import Path
import socket
import subprocess
import sys
import time

import httpx

BACKEND = Path(os.environ.get("DAMAGE_BENCHMARK_BACKEND", Path(__file__).resolve().parents[1])).resolve()


def serve(port):
    import uvicorn
    sys.path.insert(0, str(BACKEND))
    from app import main as module

    @module.app.get("/probe")
    def probe():
        model = module.loaded.get("car_damage")
        session = getattr(model, "session", None)
        return {
            "model_loaded": model is not None,
            "session": id(session) if session else None,
            "providers": session.get_providers() if session else None,
            "imports": [name for name in ("torch", "ultralytics") if name in sys.modules],
        }

    uvicorn.run(module.app, host="127.0.0.1", port=port, log_level="warning")


def memory(pid):
    values = dict(
        line.split(":", 1) for line in Path(f"/proc/{pid}/status").read_text().splitlines()
        if line.startswith(("VmRSS:", "VmHWM:"))
    )
    return float(values["VmRSS"].split()[0]) / 1024, float(values["VmHWM"].split()[0]) / 1024


def benchmark(images):
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        port = sock.getsockname()[1]
    env = dict(os.environ, OPENBLAS_NUM_THREADS="1", OMP_NUM_THREADS="1",
               YOLO_CONFIG_DIR="/tmp/autodoc-damage-probe")
    child = subprocess.Popen(
        [sys.executable, __file__, "--serve", str(port)],
        cwd=BACKEND, env=env, stdout=sys.stderr,
    )
    report = {"requests": []}
    try:
        with httpx.Client(base_url=f"http://127.0.0.1:{port}", timeout=120, trust_env=False) as client:
            for _ in range(600):
                if child.poll() is not None:
                    raise RuntimeError(f"Server exited with {child.returncode}")
                try:
                    report["before"] = client.get("/probe").json()
                    break
                except httpx.ConnectError:
                    time.sleep(0.1)
            else:
                raise RuntimeError("Server failed to start")
            assert report["before"]["model_loaded"]
            report["startup_rss_mib"], report["startup_hwm_mib"] = memory(child.pid)
            for image in images:
                with image.open("rb") as body:
                    started = time.monotonic()
                    pre_rss, _ = memory(child.pid)
                    # Linux 5+: reset this process's VmHWM to current RSS,
                    # so each request has its own kernel high-water mark.
                    Path(f"/proc/{child.pid}/clear_refs").write_text("5")
                    response = client.post(
                        "/api/v1/damage", data={"vehicle_type": "car"},
                        files={"image": (image.name, body, "image/jpeg")},
                    )
                    resident, high_water = memory(child.pid)
                response.raise_for_status()
                report["requests"].append({
                    "image": image.name, "pre_rss_mib": pre_rss,
                    "peak_rss_mib": high_water, "post_rss_mib": resident,
                    "seconds": time.monotonic() - started, "json": response.json(),
                })
            report["after"] = client.get("/probe").json()
    finally:
        child.terminate()
        child.wait(timeout=15)
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--serve", action="store_true")
    parser.add_argument("inputs", nargs="+")
    args = parser.parse_args()
    if args.serve:
        serve(int(args.inputs[0]))
    else:
        benchmark([Path(value).resolve() for value in args.inputs])
