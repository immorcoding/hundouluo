"""Validate delivery boundaries and native-scale assets, without editing images."""
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / 'assets/combat_v011'
PREVIEWS = ROOT / 'previews/combat_v011'
metadata = json.loads((ASSETS / 'atlas.json').read_text())
with Image.open(ASSETS / 'source.png') as source:
    assert source.mode == 'RGBA' and source.getchannel('A').getextrema() == (0, 255)
with Image.open(ASSETS / 'atlas.png') as atlas:
    assert atlas.size == (192, 320) and atlas.mode == 'RGBA'
    for row in range(8):
        for col in range(4):
            frame = atlas.crop((col*48, row*40, (col+1)*48, (row+1)*40))
            bounds = frame.getchannel('A').getbbox()
            assert bounds is not None, (row, col)
            assert bounds[0] > 0 and bounds[1] > 0 and bounds[2] < 48 and bounds[3] < 40, (row, col, bounds)
assert len(metadata['rows']) == 8
charge_width, charge_height = metadata['rows'][7]['max_size']
assert 0.9 <= charge_width / charge_height <= 1.1, 'Charge ring was clipped into a flattened shape'
for name in ('combat.png', 'mech.png', 'charge.png', 'muzzle.png'):
    with Image.open(PREVIEWS / name) as image:
        assert image.size == (640, 360)
with Image.open(PREVIEWS / 'muzzle.png') as image:
    # Frame 7, 33 ms after enemy firing: warm projectile/flash must touch the
    # visible barrel corridor at y=215, not the old gameplay lane at y=234.
    mouth = image.crop((389, 208, 413, 222)).convert('RGB')
    assert sum(r > 150 and r > g * 1.4 and r > b * 1.5
               for r, g, b in mouth.getdata()) >= 3, 'Shot missing from visible soldier muzzle'
for name in ('combat.gif', 'mech.gif'):
    with Image.open(PREVIEWS / name) as image:
        assert image.size == (640, 360) and image.info['loop'] == 0
        duration = 0
        for index in range(image.n_frames):
            image.seek(index)
            duration += image.info['duration']
        assert duration == 4000, (name, duration)
print('PASS: source alpha, 32 nonempty padded frames, metadata, native captures, 4-second loops')
