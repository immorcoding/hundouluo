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
for name in ('combat.png', 'mech.png', 'charge.png'):
    with Image.open(PREVIEWS / name) as image:
        assert image.size == (640, 360)
for name in ('combat.gif', 'mech.gif'):
    with Image.open(PREVIEWS / name) as image:
        assert image.size == (640, 360) and image.info['loop'] == 0
        duration = 0
        for index in range(image.n_frames):
            image.seek(index)
            duration += image.info['duration']
        assert duration == 4000, (name, duration)
print('PASS: source alpha, 32 nonempty padded frames, metadata, native captures, 4-second loops')
