"""Convert ONE COCO split. Copies images and generates detection labels.
Classes are assigned from --classes order, with exact COCO category name matching.
"""
import argparse
import json
import shutil
from pathlib import Path

p = argparse.ArgumentParser()
p.add_argument('--annotations', required=True)
p.add_argument('--images', required=True)
p.add_argument('--output', required=True)
p.add_argument('--split', choices=['train', 'val', 'test'], required=True)
p.add_argument('--classes', required=True, help='Comma-separated exact COCO category names')
a = p.parse_args()
d = json.loads(Path(a.annotations).read_text(encoding='utf-8'))
names = [x.strip() for x in a.classes.split(',')]
if len(names) != len(set(names)):
    raise ValueError('Duplicate class names.')
cat = {c['id']: names.index(c['name']) for c in d['categories'] if c['name'] in names}
if len(cat) != len(d['categories']) or set(names) != {c['name'] for c in d['categories']}:
    raise ValueError('Classes must match all COCO category names exactly.')
root = Path(a.images).resolve()
out = Path(a.output)
imgdir, labdir = out / 'images' / a.split, out / 'labels' / a.split
imgdir.mkdir(parents=True, exist_ok=True)
labdir.mkdir(parents=True, exist_ok=True)
labels = {im['id']: [] for im in d['images']}
images = {im['id']: im for im in d['images']}
for an in d['annotations']:
    if an.get('iscrowd', 0):
        raise ValueError('Crowd annotations require manual review; conversion stopped.')
    im = images[an['image_id']]
    x, y, w, h = an['bbox']
    W, H = im['width'], im['height']
    if W <= 0 or H <= 0 or w <= 0 or h <= 0 or x < 0 or y < 0 or x+w > W+.01 or y+h > H+.01:
        raise ValueError(f'Invalid box/image dimensions: {an["id"]}')
    labels[im['id']].append(f'{cat[an["category_id"]]} {(x+w/2)/W} {(y+h/2)/H} {w/W} {h/H}')
for ident, im in images.items():
    src = (root / im['file_name']).resolve()
    if not src.is_relative_to(root):
        raise ValueError('Image path escapes image folder.')
    name = str(ident)  # COCO image IDs avoid filename collisions within the split.
    shutil.copy2(src, imgdir / (name + src.suffix.lower()))
    (labdir / (name + '.txt')).write_text('\n'.join(labels[ident]), encoding='utf-8')
print('Converted', len(images), 'images. Class IDs:', dict(enumerate(names)))
