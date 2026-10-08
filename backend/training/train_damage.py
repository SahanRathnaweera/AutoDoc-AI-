import argparse
import shutil
from ultralytics import YOLO
from app.common import ROOT, MODELS

p = argparse.ArgumentParser()
p.add_argument('--vehicle', choices=['car', 'bike'], required=True)
p.add_argument('--data', required=True)
p.add_argument('--epochs', type=int, default=50)
p.add_argument('--batch', type=int, default=8)
p.add_argument('--device', default='cpu')
a = p.parse_args()
model = YOLO('yolov8n.pt')
model.train(data=str((ROOT / a.data).resolve()), epochs=a.epochs, imgsz=640,
    batch=a.batch, device=a.device, seed=42, project=str(ROOT / 'runs'),
    name=a.vehicle + '_damage_v1')
best = model.trainer.best
MODELS.mkdir(exist_ok=True)
target = MODELS / f'{a.vehicle}_damage_v1.pt'
shutil.copy2(best, target)
YOLO(str(target)).val(data=str((ROOT / a.data).resolve()), split='test', device=a.device)
print('Saved:', target)
