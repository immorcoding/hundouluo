"""Encode existing Godot captures as looping GIFs; does not repaint any artwork."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent
for mode in ('combat', 'mech'):
    frames = []
    for index in range(48):
        with Image.open(ROOT / 'frames' / f'{mode}-{index:02d}.png') as image:
            assert image.size == (640, 360), image.size
            frames.append(image.convert('RGB'))
    frames[0].save(ROOT / f'{mode}.gif', save_all=True, append_images=frames[1:],
                   duration=[80, 80, 90] * 16, loop=0, disposal=2, optimize=False)
    print(f'Encoded {mode}: 48 native frames / 4 seconds')
