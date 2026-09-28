"""Rebuild the hand-authored Issue #19 pixel atlases and an inspection scene.

Requires Pillow 10+; no downloaded assets are read. Coordinates and palette here
are the editable originals. Run: python tools/build_pixel_art.py
"""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "pixel"
PREVIEW = ROOT / "docs" / "art"

P = {
    "ink": "#17232f", "shadow": "#28394b", "steel": "#40566a",
    "steel_light": "#657d91", "fog": "#8498a4", "wall": "#34495b",
    "wall_light": "#4c6475", "wall_dark": "#253747",
    "white": "#ecf2e9", "cream": "#c4d7d9", "cyan": "#32c7d5",
    "cyan_light": "#a9f4ed", "cyan_dark": "#167d97",
    "orange": "#f07942", "red": "#d5473a", "red_dark": "#923b45",
    "amber": "#f3c65b", "amber_dark": "#a57839",
    "void": "#111d2b", "deep": "#1d2c3e",
}


def canvas(size):
    im = Image.new("RGBA", size, (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)


def box(d, xy, c):
    d.rectangle(xy, fill=P.get(c, c))


def poly(d, xy, c):
    d.polygon(xy, fill=P.get(c, c))


def operative(state):
    im, d = canvas((36, 48))
    dead = state == "down"
    if dead:
        # The low profile is intentionally wholly within the same grounded cell.
        box(d, (4, 36, 31, 43), "ink")
        box(d, (8, 36, 29, 41), "white")
        box(d, (12, 34, 20, 39), "cyan")
        box(d, (21, 35, 28, 39), "cyan_light")
        return im

    jump = state == "jump"
    stride = state in ("run_a", "run_b")
    dy = -3 if jump else 0
    # Legs remain two distinct pale shapes, with dark negative space between.
    if jump:
        box(d, (9, 35, 15, 39), "ink")
        box(d, (8, 37, 15, 42), "white")
        box(d, (19, 34, 25, 39), "ink")
        box(d, (20, 39, 29, 42), "white")
    elif state == "run_a":
        box(d, (8, 34, 15, 41), "ink")
        box(d, (4, 40, 15, 45), "white")
        box(d, (19, 34, 26, 42), "ink")
        box(d, (20, 42, 30, 46), "white")
    elif state == "run_b":
        box(d, (9, 34, 16, 43), "ink")
        box(d, (9, 42, 19, 46), "white")
        box(d, (20, 34, 27, 40), "ink")
        box(d, (25, 40, 32, 44), "white")
    else:
        box(d, (9, 34, 16, 43), "ink")
        box(d, (8, 42, 18, 46), "white")
        box(d, (20, 34, 27, 43), "ink")
        box(d, (19, 42, 29, 46), "white")
    # One tall, left-only tool pack, a counterweight to the forward visor.
    box(d, (1, 17 + dy, 10, 34 + dy), "ink")
    box(d, (3, 19 + dy, 8, 32 + dy), "steel")
    box(d, (3, 21 + dy, 5, 25 + dy), "amber")
    box(d, (5, 14 + dy, 7, 17 + dy), "ink")
    box(d, (5, 12 + dy, 6, 14 + dy), "cyan")
    # Rounded suit and helmet, drawn with stepped corners, not a hue swap.
    poly(d, [(10, 23 + dy), (12, 20 + dy), (24, 20 + dy),
             (28, 24 + dy), (28, 34 + dy), (24, 37 + dy),
             (11, 37 + dy), (8, 33 + dy), (8, 26 + dy)], "ink")
    box(d, (11, 24 + dy, 25, 33 + dy), "white")
    box(d, (10, 27 + dy, 13, 32 + dy), "cyan")
    box(d, (22, 25 + dy, 25, 32 + dy), "cyan_dark")
    box(d, (14, 34 + dy, 22, 36 + dy), "cyan")
    poly(d, [(11, 5 + dy), (14, 2 + dy), (23, 2 + dy),
             (27, 5 + dy), (28, 9 + dy), (28, 18 + dy),
             (25, 22 + dy), (12, 22 + dy), (8, 18 + dy),
             (8, 9 + dy)], "ink")
    box(d, (12, 5 + dy, 23, 7 + dy), "white")
    box(d, (10, 9 + dy, 26, 17 + dy), "cream")
    box(d, (13, 10 + dy, 27, 16 + dy), "cyan_dark")
    box(d, (15, 10 + dy, 27, 13 + dy), "cyan")
    box(d, (21, 10 + dy, 26, 11 + dy), "cyan_light")
    box(d, (12, 19 + dy, 24, 20 + dy), "white")
    box(d, (7, 26 + dy, 10, 32 + dy), "cream")
    # Arm and short utility emitter, not an oversized gun silhouette.
    box(d, (24, 25 + dy, 29, 31 + dy), "ink")
    box(d, (25, 25 + dy, 28, 28 + dy), "white")
    box(d, (28, 27 + dy, 33, 30 + dy), "steel")
    box(d, (33, 28 + dy, 35, 29 + dy), "cyan")
    if state == "fire":
        box(d, (32, 23, 34, 25), "amber")
        box(d, (34, 21, 35, 22), "amber")
    if state == "hurt":
        box(d, (11, 26, 24, 28), "amber")
        box(d, (12, 10, 15, 12), "white")
    if stride:
        box(d, (15, 32, 19, 33), "cyan_dark")
    return im


def soldier(state):
    im, d = canvas((36, 48))
    if state == "down":
        poly(d, [(4, 42), (8, 36), (28, 36), (32, 42)], "ink")
        box(d, (9, 38, 27, 42), "red")
        box(d, (14, 36, 18, 39), "orange")
        return im
    stride = state in ("walk_a", "walk_b")
    shift = -2 if state == "walk_a" else 2 if state == "walk_b" else 0
    # Backward-facing claw feet and a narrow waist distinguish it from operative.
    poly(d, [(11 + shift, 34), (16 + shift, 34), (17 + shift, 43),
             (11 + shift, 43), (5 + shift, 46), (3 + shift, 46),
             (8 + shift, 41)], "ink")
    poly(d, [(21 - shift, 34), (26 - shift, 34), (29 - shift, 43),
             (23 - shift, 46), (18 - shift, 45)], "ink")
    box(d, (10 + shift, 38, 14 + shift, 42), "orange")
    box(d, (23 - shift, 38, 26 - shift, 43), "red")
    poly(d, [(10, 22), (15, 19), (24, 20), (30, 26),
             (26, 34), (20, 37), (12, 34), (8, 28)], "ink")
    poly(d, [(11, 24), (20, 21), (27, 26), (24, 33),
             (17, 34), (10, 29)], "red")
    poly(d, [(18, 22), (27, 25), (23, 29), (16, 27)], "orange")
    # Security-family chevron is repeated at larger scale on the mech shell.
    box(d, (20, 27, 27, 33), "ink")
    poly(d, [(24, 28), (27, 31), (21, 31)], "orange")
    poly(d, [(22, 32), (26, 32), (24, 33)], "red")
    # Three sharp dorsal projections; an original shared security chevron.
    poly(d, [(10, 22), (7, 17), (16, 20)], "red_dark")
    poly(d, [(20, 20), (24, 13), (27, 23)], "red")
    poly(d, [(27, 24), (33, 19), (31, 30)], "red_dark")
    poly(d, [(11, 5), (19, 2), (29, 6), (27, 17),
             (19, 22), (10, 18), (7, 13)], "ink")
    poly(d, [(8, 12), (18, 3), (28, 7), (24, 15), (13, 17)], "orange")
    poly(d, [(8, 12), (14, 14), (12, 17), (6, 17)], "red_dark")
    box(d, (8, 14, 18, 16), "ink")
    box(d, (9, 14, 16, 14), "red")
    poly(d, [(21, 17), (25, 16), (25, 23), (18, 22)], "red_dark")
    # Left-pointing emitter and dark, distinctly mechanical elbow.
    box(d, (4, 27, 13, 31), "ink")
    box(d, (2, 28, 6, 30), "steel")
    box(d, (2, 29, 3, 29), "red")
    box(d, (8, 25, 11, 27), "orange")
    if state == "windup":
        box(d, (2, 27, 5, 31), "amber")
        box(d, (16, 14, 19, 15), "amber")
    if state == "fire":
        box(d, (0, 27, 3, 31), "amber")
    if state == "hurt":
        box(d, (15, 26, 21, 29), "white")
    if stride:
        box(d, (18, 30, 20, 31), "red_dark")
    return im


def defense_mech(state):
    im, d = canvas((80, 72))
    if state == "down":
        poly(d, [(5, 67), (14, 56), (30, 59), (40, 52),
                 (54, 61), (69, 57), (76, 67)], "ink")
        box(d, (26, 60, 58, 65), "shadow")
        box(d, (36, 59, 43, 62), "red")
        return im
    # Permanently planted articulated base; 2x the soldier's visual mass.
    poly(d, [(18, 49), (32, 49), (32, 59), (27, 65),
             (29, 68), (9, 68), (9, 62)], "ink")
    poly(d, [(51, 49), (65, 49), (69, 63), (73, 68),
             (50, 68), (47, 61)], "ink")
    box(d, (12, 62, 27, 65), "steel")
    box(d, (53, 62, 69, 65), "steel")
    box(d, (21, 51, 28, 60), "steel_light")
    box(d, (53, 51, 60, 60), "steel_light")
    # Broad, dark shoulders taper to the middle with angular cheek plates.
    poly(d, [(15, 12), (24, 7), (58, 7), (68, 13),
             (75, 24), (68, 48), (58, 55), (25, 55),
             (11, 47), (8, 28)], "ink")
    poly(d, [(17, 16), (27, 11), (56, 11), (65, 17),
             (69, 31), (63, 45), (54, 51), (27, 51),
             (14, 43), (12, 27)], "shadow")
    poly(d, [(19, 16), (34, 13), (34, 20), (20, 29), (13, 28)], "steel")
    poly(d, [(48, 13), (57, 13), (66, 21), (68, 30), (58, 27), (48, 20)], "steel")
    poly(d, [(15, 31), (28, 27), (32, 43), (22, 47), (13, 41)], "steel")
    poly(d, [(54, 28), (68, 30), (65, 43), (55, 47), (49, 42)], "steel")
    box(d, (24, 32, 26, 38), "steel_light")
    box(d, (59, 32, 61, 38), "steel_light")
    # Same enemy-family chevron, but no copied or third-party insignia.
    poly(d, [(58, 16), (61, 20), (55, 20)], "orange")
    poly(d, [(56, 21), (61, 21), (58, 24)], "red")
    # Central aperture is a visually dominant telegraph.
    box(d, (32, 25, 50, 44), "ink")
    box(d, (35, 28, 47, 41), "steel_light")
    core = "amber" if state in ("charge_a", "charge_b", "fire") else "orange"
    box(d, (38, 31, 44, 38), core)
    if state in ("charge_b", "fire"):
        box(d, (35, 27, 47, 28), "amber")
        box(d, (34, 40, 48, 41), "amber")
        box(d, (31, 31, 32, 38), "amber")
        box(d, (50, 31, 51, 38), "amber")
    # Low muzzle aims left: telegraph is visible even without color via flared prongs.
    box(d, (4, 43, 23, 51), "ink")
    box(d, (7, 45, 23, 48), "steel")
    box(d, (2, 41, 8, 52), "ink")
    box(d, (3, 44, 5, 49), "orange")
    if state == "fire":
        box(d, (0, 43, 3, 50), "amber")
    if state == "hurt":
        box(d, (33, 29, 47, 31), "white")
    return im


def tile(kind):
    im, d = canvas((24, 24))
    if kind.startswith("floor") or kind.startswith("gap"):
        box(d, (0, 0, 23, 23), "wall_dark")
        box(d, (0, 0, 23, 4), "steel_light")
        box(d, (0, 5, 23, 7), "ink")
        box(d, (2, 9, 21, 21), "wall")
        box(d, (2, 10, 21, 11), "steel")
        box(d, (5, 15, 7, 18), "steel_light")
        box(d, (16, 15, 18, 18), "steel_light")
        if kind == "floor_vent":
            box(d, (9, 12, 14, 21), "ink")
            for y in (14, 17, 20):
                box(d, (10, y, 13, y), "steel_light")
        if kind in ("gap_left", "gap_right"):
            x = 18 if kind == "gap_left" else 0
            box(d, (x, 0, x + 5, 7), "amber")
            box(d, (x + 1, 1, x + 2, 3), "ink")
            box(d, (x + 3, 4, x + 4, 6), "ink")
            box(d, (x, 8, x + 3, 23), "amber_dark")
        return im
    if kind in ("wall", "wall_vent", "repair"):
        box(d, (0, 0, 23, 23), "wall_dark")
        box(d, (2, 2, 21, 21), "wall")
        box(d, (4, 3, 20, 4), "wall_light")
        box(d, (2, 19, 21, 21), "shadow")
        box(d, (4, 17, 5, 18), "steel_light")
        box(d, (19, 17, 20, 18), "steel_light")
        if kind == "wall_vent":
            box(d, (6, 8, 18, 16), "ink")
            for x in (8, 11, 14, 17):
                box(d, (x, 9, x, 15), "steel")
        if kind == "repair":
            box(d, (9, 5, 14, 17), "steel_light")
            box(d, (7, 8, 16, 10), "steel_light")
            box(d, (10, 6, 13, 16), "cyan_dark")
            box(d, (8, 9, 15, 9), "cyan_dark")
        return im
    if kind == "rescue_sign":
        box(d, (2, 2, 21, 21), "ink")
        box(d, (4, 4, 19, 19), "steel")
        box(d, (10, 5, 13, 17), "cyan_light")
        box(d, (6, 9, 17, 12), "cyan_light")
        box(d, (10, 5, 13, 17), "cyan_light")
        return im
    if kind.startswith("beacon"):
        box(d, (8, 14, 15, 22), "ink")
        box(d, (10, 16, 13, 19), "steel_light")
        box(d, (7, 6, 16, 15), "ink")
        box(d, (9, 8, 14, 13), "red" if kind == "beacon_on" else "red_dark")
        if kind == "beacon_on":
            box(d, (10, 8, 12, 10), "amber")
            box(d, (5, 9, 6, 11), "red")
            box(d, (17, 9, 18, 11), "red")
        return im
    raise ValueError(kind)


def atlas(name, frames, size, fps, animations):
    image, _ = canvas((size[0] * len(frames), size[1]))
    for i, (_, frame) in enumerate(frames):
        image.alpha_composite(frame, (i * size[0], 0))
    image.save(OUT / f"{name}.png", optimize=True)
    return {
        "image": f"{name}.png", "frame_size": list(size),
        "layout": {"columns": len(frames), "rows": 1, "margin": 0, "separation": 0},
        "frames": {key: i for i, (key, _) in enumerate(frames)},
        "animations": animations, "suggested_fps": fps,
        "origin": "bottom-center", "facing": "right" if name == "operative" else "left",
        "filter": "nearest",
    }


def detailed_actor(image, name, state):
    """Re-ink original shapes at a denser grid; add hand-placed material marks."""
    size = {"operative": (48, 60), "mechanical_soldier": (48, 60),
            "defense_mech": (104, 90)}[name]
    image = image.resize(size, Image.Resampling.NEAREST)
    d = ImageDraw.Draw(image)
    if state == "down":
        return image
    if name == "operative":
        box(d, (17, 9, 28, 9), "white")
        box(d, (29, 16, 34, 17), "cyan_light")
        box(d, (7, 28, 9, 33), "cyan_dark")
        box(d, (5, 38, 9, 39), "steel_light")
        box(d, (15, 33, 17, 38), "cyan_light")
        box(d, (21, 47, 24, 49), "steel")
        box(d, (11, 55, 17, 55), "steel_light")
        box(d, (29, 55, 35, 55), "steel_light")
        box(d, (31, 34, 33, 35), "cyan_light")
    elif name == "mechanical_soldier":
        box(d, (14, 9, 19, 10), "amber")
        box(d, (27, 9, 31, 10), "red_dark")
        box(d, (23, 34, 25, 36), "amber")
        box(d, (16, 39, 20, 40), "red_dark")
        box(d, (12, 50, 15, 51), "amber_dark")
        box(d, (33, 51, 36, 52), "amber_dark")
        box(d, (32, 26, 34, 28), "red_dark")
    else:
        for x in (24, 70):
            box(d, (x, 22, x + 5, 23), "steel_light")
            box(d, (x + 2, 32, x + 4, 33), "ink")
            box(d, (x + 3, 49, x + 5, 52), "steel_light")
        box(d, (47, 16, 58, 17), "steel_light")
        box(d, (48, 59, 57, 60), "amber_dark")
        box(d, (18, 77, 29, 78), "steel_light")
        box(d, (76, 77, 87, 78), "steel_light")
        box(d, (52, 45, 54, 47), "white" if state.startswith("charge") else "red")
    return image


def hangar_layers():
    """Original editable pixel composition, not a resampled concept painting."""
    far, d = canvas((1440, 360))
    box(d, (0, 0, 1439, 359), "void")
    # A lower shaft remains visible *only* through the real terrain gap.
    for x in range(0, 1440, 144):
        box(d, (x + 12, 272, x + 28, 359), "deep")
        box(d, (x + 16, 281, x + 19, 359), "wall")
    for y in (300, 332):
        box(d, (0, y, 1439, y + 2), "wall_dark")
        for x in range(38, 1440, 192):
            box(d, (x, y + 5, x + 8, y + 7), "cyan_dark")
    box(d, (0, 0, 1439, 25), "ink")
    for x in range(0, 1440, 120):
        box(d, (x + 3, 6, x + 110, 9), "wall")
        box(d, (x + 12, 15, x + 15, 24), "steel")
        box(d, (x + 94, 15, x + 97, 24), "steel")
    # Wide bay opening and nested silhouettes provide scale without fighting sprites.
    box(d, (92, 38, 1020, 263), "wall_dark")
    box(d, (114, 51, 1001, 253), "deep")
    box(d, (150, 61, 946, 246), "wall")
    for x in (260, 744):
        box(d, (x, 66, x + 27, 236), "steel")
        box(d, (x + 5, 69, x + 22, 233), "wall_dark")
        box(d, (x + 9, 75, x + 11, 226), "wall_light")
    for y in (86, 202):
        box(d, (160, y, 937, y + 3), "steel")
        box(d, (165, y + 1, 931, y + 1), "steel_light")
    for x in range(172, 930, 84):
        box(d, (x, 66, x + 4, 238), "wall_dark")
        box(d, (x + 5, 78, x + 6, 225), "steel")
        box(d, (x - 12, 227, x + 27, 230), "steel")
    # A parked heavy rescue gantry, intentionally not a playable mech silhouette.
    box(d, (390, 110, 604, 156), "shadow")
    box(d, (412, 100, 580, 112), "steel")
    box(d, (438, 80, 554, 99), "wall_dark")
    box(d, (402, 157, 427, 215), "wall_dark")
    box(d, (568, 157, 593, 215), "wall_dark")
    box(d, (466, 158, 527, 202), "wall_dark")
    box(d, (471, 169, 521, 178), "steel")
    for x in range(400, 604, 28):
        box(d, (x, 111, x + 1, 153), "wall_light")
        box(d, (x + 4, 139, x + 14, 140), "steel")
    for x in (424, 487, 561):
        box(d, (x, 120, x + 7, 123), "amber_dark")
    box(d, (1064, 39, 1409, 267), "wall_dark")
    box(d, (1080, 55, 1393, 251), "steel")
    box(d, (1103, 66, 1371, 238), "deep")
    for x in range(1122, 1370, 38):
        box(d, (x, 70, x + 2, 234), "wall")
    for y in (95, 151, 207):
        box(d, (1106, y, 1369, y + 3), "wall")
        box(d, (1150, y + 1, 1180, y + 1), "cyan_dark")
    for x in range(1090, 1380, 55):
        box(d, (x, 244, x + 33, 248), "wall")
        box(d, (x + 4, 249, x + 7, 260), "shadow")
    far.save(OUT / "hangar_far.png", optimize=True)

    mid, d = canvas((1440, 288))
    for x in (28, 320, 682, 1028, 1376):
        box(d, (x, 0, x + 29, 255), "ink")
        box(d, (x + 4, 0, x + 24, 255), "shadow")
        box(d, (x + 7, 0, x + 10, 249), "steel")
        box(d, (x + 16, 91, x + 21, 96), "cyan_light")
        box(d, (x - 9, 192, x + 37, 198), "steel")
        box(d, (x - 7, 201, x + 36, 203), "ink")
        for y in (40, 133, 224):
            box(d, (x + 17, y, x + 19, y + 2), "amber_dark")
    for x in (126, 472, 828, 1172):
        box(d, (x, 131, x + 142, 136), "ink")
        box(d, (x + 5, 137, x + 137, 143), "steel")
        for rail in range(x + 10, x + 137, 21):
            box(d, (rail, 116, rail + 2, 130), "wall_light")
        box(d, (x + 8, 114, x + 135, 116), "wall_light")
        box(d, (x + 16, 145, x + 20, 159), "wall")
        box(d, (x + 117, 145, x + 121, 159), "wall")
        for bolt in range(x + 17, x + 140, 39):
            box(d, (bolt, 139, bolt + 1, 140), "amber_dark")
    # Hoist and rescue-cross panel, with the combat strip kept quiet.
    box(d, (764, 0, 821, 17), "ink")
    box(d, (787, 17, 792, 90), "steel")
    box(d, (775, 90, 804, 101), "shadow")
    box(d, (782, 101, 796, 113), "amber_dark")
    box(d, (173, 55, 219, 102), "ink")
    box(d, (178, 60, 214, 97), "steel")
    box(d, (192, 65, 199, 91), "cyan_light")
    box(d, (183, 74, 208, 81), "cyan_light")
    for x in (240, 624, 964, 1290):
        box(d, (x, 188, x + 18, 233), "wall_dark")
        box(d, (x + 4, 194, x + 15, 214), "steel")
        box(d, (x + 7, 197, x + 12, 201), "amber")
    # Small industrial conduits and braces sit above the combat silhouette.
    for x in (79, 399, 748, 1082):
        box(d, (x, 18, x + 4, 56), "wall_light")
        box(d, (x - 6, 54, x + 11, 57), "ink")
        box(d, (x - 4, 57, x + 9, 59), "steel")
    for x in (121, 460, 811, 1155):
        poly(d, [(x, 169), (x + 3, 169), (x + 50, 217),
                 (x + 47, 217)], "wall_dark")
        box(d, (x + 10, 181, x + 12, 183), "steel")
    mid.save(OUT / "hangar_mid.png", optimize=True)


def preview():
    # A composed art/legibility check, never a shipped level layout.
    im = Image.new("RGBA", (384, 216), P["void"])
    d = ImageDraw.Draw(im)
    for x in range(0, 384, 24):
        for y in range(0, 168, 24):
            im.alpha_composite(tile("wall_vent" if (x // 24 + y // 24) % 9 == 0 else "wall"), (x, y))
    for x in range(0, 384, 24):
        if x in (168, 192, 216):
            continue
        k = "gap_left" if x == 144 else "gap_right" if x == 240 else "floor_vent" if x % 96 == 0 else "floor"
        for y in (168, 192):
            im.alpha_composite(tile(k if y == 168 else "floor"), (x, y))
    for kind, pos in (("rescue_sign", (48, 72)), ("repair", (72, 120)),
                      ("beacon_on", (132, 144)), ("beacon_on", (252, 144))):
        im.alpha_composite(tile(kind), pos)
    im.alpha_composite(operative("run_a"), (92, 120))
    im.alpha_composite(soldier("windup"), (282, 120))
    im.alpha_composite(defense_mech("charge_b"), (304, 96))
    enlarged = im.resize((1152, 648), Image.Resampling.NEAREST)
    im.convert("RGB").save(PREVIEW / "scene-native.png", optimize=True)
    enlarged.convert("RGB").save(PREVIEW / "scene-3x.png", optimize=True)

    for name in ("operative", "mechanical_soldier", "defense_mech", "base_tiles"):
        with Image.open(OUT / f"{name}.png") as strip:
            backdrop = Image.new("RGBA", strip.size, P["wall_dark"])
            backdrop.alpha_composite(strip)
            backdrop.resize((strip.width * 3, strip.height * 3),
                            Image.Resampling.NEAREST).convert("RGB").save(
                                PREVIEW / f"{name}-frames-3x.png", optimize=True)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    PREVIEW.mkdir(parents=True, exist_ok=True)
    operative_frames = ["idle", "run_a", "run_b", "jump", "fire", "hurt", "down"]
    soldier_frames = ["idle", "walk_a", "walk_b", "windup", "fire", "hurt", "down"]
    mech_frames = ["idle", "charge_a", "charge_b", "fire", "hurt", "down"]
    tiles = ["floor", "floor_vent", "gap_left", "gap_right", "wall",
             "wall_vent", "repair", "rescue_sign", "beacon_off", "beacon_on"]
    metadata = {
        "operative": atlas("operative", [(n, detailed_actor(operative(n), "operative", n)) for n in operative_frames], (48, 60), 8,
                           {"idle": ["idle"], "run": ["run_a", "run_b"],
                            "jump": ["jump"], "fire": ["fire"], "hurt": ["hurt"], "down": ["down"]}),
        "mechanical_soldier": atlas("mechanical_soldier", [(n, detailed_actor(soldier(n), "mechanical_soldier", n)) for n in soldier_frames], (48, 60), 6,
                                    {"idle": ["idle"], "walk": ["walk_a", "walk_b"],
                                     "windup": ["windup"], "fire": ["fire"],
                                     "hurt": ["hurt"], "down": ["down"]}),
        "defense_mech": atlas("defense_mech", [(n, detailed_actor(defense_mech(n), "defense_mech", n)) for n in mech_frames], (104, 90), 5,
                              {"idle": ["idle"], "charge": ["charge_a", "charge_b"],
                               "fire": ["fire"], "hurt": ["hurt"], "down": ["down"]}),
        "base_tiles": atlas("base_tiles", [(n, tile(n)) for n in tiles], (24, 24), 1,
                            {"beacon": ["beacon_off", "beacon_on"]}),
    }
    for key in ("operative", "mechanical_soldier", "defense_mech"):
        metadata[key]["ground_baseline_y"] = metadata[key]["frame_size"][1] - 1
        metadata[key]["loop_notes"] = "down is terminal; hurt/fire are event frames"
    (OUT / "atlas.json").write_text(json.dumps(metadata, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    hangar_layers()
    preview()


if __name__ == "__main__":
    main()
