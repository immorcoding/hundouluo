"""Hand-authored rescue-bay pixel composition for the playable Godot layers.

All geometry, materials and lighting are original coordinates and deterministic
marks. This module never reads the generated C concept illustration.
"""

from pathlib import Path

from PIL import Image, ImageDraw


W, H = 1440, 360
C = {
    "abyss": "#0a1421", "navy": "#102338", "deep": "#172f45",
    "haze": "#35536a", "mist": "#5c7e97", "sky": "#85a9c4",
    "ice": "#b4d8e6", "shadow": "#122337", "iron": "#21384a",
    "steel": "#304c61", "edge": "#4c6e81", "edge_hi": "#7797a7",
    "cyan": "#84d9ee", "cyan_dark": "#327f9d", "amber": "#eda644",
    "orange": "#d86c38", "dark_amber": "#805638", "ink": "#07121f",
}


def box(draw, xy, color):
    draw.rectangle(xy, fill=C.get(color, color))


def poly(draw, points, color):
    draw.polygon(points, fill=C.get(color, color))


def stroke(draw, points, color, width=1):
    draw.line(points, fill=C.get(color, color), width=width, joint="curve")


def rivets(draw, x0, x1, y, step=24, color="edge_hi"):
    for x in range(x0, x1, step):
        box(draw, (x, y, x + 1, y + 1), color)


def material_grain(image, bounds, base_colors, highlight, recess):
    """Sparse deterministic 1px tooling marks only on selected metal planes."""
    pixels = image.load()
    x0, y0, x1, y1 = bounds
    allowed = {tuple(bytes.fromhex(C[name][1:])) + (255,) for name in base_colors}
    light = tuple(bytes.fromhex(C[highlight][1:])) + (255,)
    dark = tuple(bytes.fromhex(C[recess][1:])) + (255,)
    for y in range(y0, y1):
        for x in range(x0, x1):
            if pixels[x, y] not in allowed:
                continue
            key = ((x * 73856093) ^ (y * 19349663)) & 0xffff
            if key % 541 == 0:
                pixels[x, y] = light
            elif key % 401 == 0:
                pixels[x, y] = dark


def lit_panel(draw, xy, body="steel"):
    x0, y0, x1, y1 = xy
    box(draw, xy, "ink")
    box(draw, (x0 + 2, y0 + 2, x1 - 2, y1 - 2), body)
    stroke(draw, [(x0 + 3, y0 + 3), (x1 - 4, y0 + 3)], "edge_hi")
    stroke(draw, [(x1 - 3, y0 + 5), (x1 - 3, y1 - 4)], "shadow")
    box(draw, (x0 + 5, y1 - 7, x0 + 7, y1 - 5), "dark_amber")
    box(draw, (x1 - 8, y1 - 7, x1 - 6, y1 - 5), "edge_hi")


def background_depth(image):
    d = ImageDraw.Draw(image)
    for y0, y1, color in ((0, 43, "navy"), (44, 94, "deep"),
                          (95, 168, "haze"), (169, 237, "deep"),
                          (238, 359, "abyss")):
        box(d, (0, y0, W - 1, y1), color)
    # A deep, illuminated circular rescue dock occupies the right-hand bay.
    for bounds, fill in (
        ((790, -170, 1490, 319), "shadow"),
        ((812, -151, 1466, 303), "steel"),
        ((832, -133, 1445, 285), "edge"),
        ((854, -116, 1427, 269), "haze"),
        ((879, -98, 1401, 251), "mist"),
        ((904, -80, 1375, 237), "sky"),
    ):
        d.ellipse(bounds, fill=C[fill])
    for inset in (14, 38, 72):
        d.arc((790 + inset, -170 + inset // 2, 1490 - inset,
               319 - inset // 2), 174, 344, fill=C["edge_hi"], width=2)
    # Staggered, translucent-at-distance trusses give that bright aperture scale.
    for x in (963, 1047, 1143, 1245, 1333):
        box(d, (x, 14, x + 7, 245), "haze")
        box(d, (x + 2, 22, x + 3, 229), "sky")
    for y in (43, 88, 139, 190):
        box(d, (920, y, 1393, y + 4), "haze")
        box(d, (926, y, 1384, y), "ice")
    for x in (971, 1152, 1328):
        poly(d, [(x, 14), (x + 10, 14), (x + 28, 172),
                 (x + 16, 172)], "steel")
        box(d, (x + 4, 27, x + 6, 162), "mist")
        for y in (61, 112, 158):
            box(d, (x + 6, y, x + 17, y + 2), "edge_hi")
    # Deep gantry running through the aperture; its fine rails remain behind play.
    box(d, (931, 174, 1374, 180), "steel")
    box(d, (938, 171, 1367, 172), "ice")
    for x in range(948, 1362, 27):
        box(d, (x, 155, x + 2, 171), "edge")
        box(d, (x + 5, 177, x + 13, 178), "shadow")
    box(d, (962, 181, 1358, 189), "shadow")
    for x in (1015, 1196, 1330):
        box(d, (x, 190, x + 9, 234), "steel")
        box(d, (x + 2, 194, x + 4, 229), "edge_hi")
    box(d, (1082, 185, 1141, 210), "iron")
    box(d, (1091, 188, 1132, 193), "edge")
    for x in (1097, 1110, 1124):
        box(d, (x, 199, x + 4, 201), "amber")
    for x in (954, 1025, 1231, 1345):
        box(d, (x, 211, x + 31, 230), "shadow")
        box(d, (x + 3, 214, x + 28, 225), "steel")
        box(d, (x + 5, 216, x + 12, 217), "edge_hi")
    # A large left-side maintenance bay recedes behind the silhouette.
    poly(d, [(154, 30), (735, 30), (777, 77), (777, 245),
             (126, 245), (126, 77)], "iron")
    poly(d, [(185, 45), (714, 45), (750, 81), (750, 232),
             (155, 232), (155, 81)], "steel")
    poly(d, [(222, 59), (682, 59), (715, 89), (715, 217),
             (188, 217), (188, 89)], "haze")
    for x in (224, 340, 610, 690):
        box(d, (x, 66, x + 8, 228), "steel")
        box(d, (x + 2, 72, x + 3, 213), "edge")
    for y in (82, 174, 217):
        box(d, (180, y, 715, y + 3), "edge")
        box(d, (193, y, 690, y), "edge_hi")
    # Subdued translucent stepped light avoids a flat opaque triangle.
    light = Image.new("RGBA", image.size, (0, 0, 0, 0))
    ld = ImageDraw.Draw(light)
    for x, reach in ((264, 224), (675, 216), (1110, 238)):
        ld.polygon([(x - 7, 36), (x + 7, 36), (x + 69, reach),
                    (x - 64, reach)], fill=(170, 215, 230, 36))
        ld.polygon([(x - 3, 36), (x + 3, 36), (x + 26, reach),
                    (x - 29, reach)], fill=(185, 227, 240, 27))
        ld.rectangle((x - 11, 36, x + 11, 39), fill=(188, 237, 245, 210))
    image.alpha_composite(light)
    # Restore selected beams in front of the rays, maintaining structural depth.
    for x in (224, 690):
        box(d, (x, 54, x + 8, 226), "steel")
    for y in (80, 210):
        stroke(d, [(164, y), (734, y)], "edge", 3)
    # Sparse panel scratches, rivets and offset maintenance seams.
    for x in range(192, 721, 47):
        for y in (100, 153, 206):
            box(d, (x, y, x + 8, y), "edge_hi")
            box(d, (x + 2, y + 4, x + 3, y + 5), "steel")
    for x in range(887, 1380, 61):
        for y in (72, 124, 175, 219):
            box(d, (x, y, x + 14, y + 1), "mist")
            box(d, (x + 17, y + 5, x + 19, y + 7), "haze")
    # Industrial wall remains low-contrast under the collision-aligned deck.
    for x in range(0, W, 88):
        box(d, (x, 275, x + 12, 359), "deep")
        box(d, (x + 3, 280, x + 5, 359), "steel")
        for y in (286, 322):
            box(d, (x + 27, y, x + 42, y + 2), "cyan_dark")
    for y in (284, 337):
        box(d, (0, y, W - 1, y + 3), "steel")


def parked_rescue_machine(image):
    """A 200px distant docked machine, not an enemy sprite or collision target."""
    d = ImageDraw.Draw(image)
    # Overhead gantry, chains, cables and suspended shoulders.
    box(d, (363, 24, 627, 37), "shadow")
    box(d, (382, 25, 601, 28), "edge")
    for x in (402, 582):
        box(d, (x, 37, x + 6, 78), "shadow")
        box(d, (x + 2, 39, x + 3, 76), "edge_hi")
    for points in (
        [(405, 87), (373, 130), (371, 190), (387, 203)],
        [(583, 87), (620, 128), (626, 187), (606, 204)],
    ):
        stroke(d, points, "shadow", 6)
        stroke(d, points, "edge", 2)
    # Broad angled body; multiple dark value planes imply armor and scale.
    poly(d, [(418, 77), (453, 63), (537, 63), (579, 77), (599, 111),
             (582, 166), (551, 184), (446, 184), (411, 160), (397, 115)], "shadow")
    poly(d, [(425, 81), (461, 68), (535, 68), (570, 82), (583, 110),
             (565, 156), (541, 172), (448, 172), (425, 155), (412, 111)], "steel")
    poly(d, [(436, 83), (463, 72), (475, 100), (458, 126),
             (419, 119)], "edge")
    poly(d, [(562, 83), (535, 72), (522, 100), (543, 126),
             (579, 119)], "edge")
    lit_panel(d, (455, 106, 538, 156), "iron")
    box(d, (481, 115, 511, 124), "shadow")
    box(d, (486, 116, 507, 119), "cyan_dark")
    box(d, (477, 136, 518, 139), "edge")
    for x in (464, 470, 521, 528):
        box(d, (x, 110, x + 2, 148), "steel")
        box(d, (x, 117, x + 2, 119), "edge_hi")
    for y in (128, 144):
        box(d, (474, y, 521, y + 1), "shadow")
    box(d, (483, 143, 510, 145), "edge")
    for x in (488, 494, 500, 506):
        box(d, (x, 148, x + 2, 151), "shadow")
    # Dark cockpit is visibly unoccupied and far behind the playable enemies.
    lit_panel(d, (469, 51, 526, 88), "shadow")
    box(d, (478, 61, 516, 69), "cyan_dark")
    box(d, (486, 62, 503, 63), "cyan")
    box(d, (475, 79, 520, 82), "edge")
    box(d, (478, 56, 487, 57), "edge_hi")
    box(d, (510, 56, 517, 57), "edge_hi")
    box(d, (481, 72, 513, 73), "steel")
    # Distinct articulated arms with hands, feet and hydraulic joints.
    for flip in (-1, 1):
        cx = 499 + flip * 96
        poly(d, [(cx - 24, 86), (cx + 15, 90), (cx + 22, 115),
                 (cx + 10, 148), (cx - 18, 143), (cx - 28, 113)], "shadow")
        lit_panel(d, (cx - 19, 98, cx + 12, 132), "steel")
        box(d, (cx - 8, 113, cx + 2, 116), "edge_hi")
        box(d, (cx - 10, 104, cx + 4, 105), "shadow")
        box(d, (cx - 13, 123, cx + 8, 124), "edge")
        box(d, (cx - 16, 131, cx - 13, 134), "dark_amber")
        poly(d, [(cx - 16, 141), (cx + 10, 143), (cx + 16, 183),
                 (cx - 12, 194), (cx - 24, 176)], "iron")
        box(d, (cx - 8, 151, cx + 2, 174), "steel")
        box(d, (cx - 14, 185, cx + 10, 198), "shadow")
        box(d, (cx - 5, 188, cx + 4, 190), "edge")
        for y in (156, 163, 170):
            box(d, (cx - 5, y, cx + 5, y + 1), "edge")
    for x in (439, 529):
        poly(d, [(x, 166), (x + 27, 166), (x + 35, 215),
                 (x + 27, 226), (x - 4, 223), (x - 10, 213)], "shadow")
        poly(d, [(x + 4, 171), (x + 23, 171), (x + 26, 210),
                 (x + 15, 217), (x, 211)], "steel")
        box(d, (x + 2, 188, x + 21, 190), "edge")
        box(d, (x + 5, 177, x + 8, 184), "edge_hi")
        box(d, (x + 18, 181, x + 20, 186), "shadow")
        box(d, (x - 5, 207, x + 26, 209), "iron")
        box(d, (x - 12, 222, x + 37, 230), "shadow")
        box(d, (x - 5, 223, x + 30, 224), "edge_hi")
    for x in (433, 467, 516, 552):
        box(d, (x, 89, x + 3, 92), "dark_amber")
        box(d, (x + 2, 148, x + 4, 150), "edge_hi")
    # Foreground dock rails veil the lower machine, giving true depth.
    box(d, (341, 230, 648, 239), "shadow")
    box(d, (341, 230, 648, 231), "edge_hi")
    for x in range(347, 644, 27):
        box(d, (x, 217, x + 2, 230), "edge")
    box(d, (347, 216, 641, 218), "edge_hi")


def far_layer():
    image = Image.new("RGBA", (W, H), C["abyss"])
    background_depth(image)
    parked_rescue_machine(image)
    material_grain(image, (155, 48, 735, 230),
                   ("steel", "haze", "iron"), "edge_hi", "shadow")
    material_grain(image, (395, 55, 613, 228),
                   ("steel", "shadow", "iron"), "edge", "ink")
    material_grain(image, (844, 10, 1400, 233),
                   ("haze", "mist"), "sky", "steel")
    return image


def structural_column(draw, x, wide=False):
    width = 61 if wide else 39
    box(draw, (x - 9, 0, x + width + 10, 15), "ink")
    box(draw, (x, 0, x + width, 248), "ink")
    box(draw, (x + 5, 0, x + width - 5, 248), "iron")
    box(draw, (x + 9, 2, x + 14, 244), "edge")
    box(draw, (x + width - 10, 5, x + width - 8, 241), "steel")
    for y in (47, 116, 187):
        box(draw, (x + 4, y, x + width - 5, y + 3), "shadow")
        box(draw, (x + 6, y + 1, x + width - 9, y + 1), "edge")
        rivets(draw, x + 7, x + width - 7, y + 5, 16, "edge_hi")
    box(draw, (x - 8, 202, x + width + 8, 215), "ink")
    box(draw, (x - 6, 204, x + width + 5, 207), "steel")
    # Consistent fixture on each load-bearing column.
    box(draw, (x + width - 15, 81, x + width - 4, 109), "ink")
    box(draw, (x + width - 13, 85, x + width - 6, 104), "edge")
    box(draw, (x + width - 11, 88, x + width - 7, 96), "cyan")


def catwalk(draw, x0, x1, y):
    box(draw, (x0, y, x1, y + 8), "ink")
    box(draw, (x0 + 3, y + 1, x1 - 4, y + 3), "steel")
    box(draw, (x0 + 5, y - 24, x1 - 6, y - 22), "edge_hi")
    for x in range(x0 + 7, x1 - 5, 19):
        box(draw, (x, y - 22, x + 2, y - 1), "steel")
        box(draw, (x + 4, y + 5, x + 11, y + 6), "edge")
    for x in range(x0 + 11, x1 - 15, 82):
        box(draw, (x, y + 2, x + 6, y + 3), "amber")
        box(draw, (x + 29, y + 9, x + 35, y + 18), "shadow")
    stroke(draw, [(x0 + 10, y + 8), (x0 + 50, y + 34)], "steel", 3)
    stroke(draw, [(x1 - 10, y + 8), (x1 - 50, y + 34)], "steel", 3)


def mid_layer():
    image = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(image)
    # Asymmetric close framing, not a wallpaper of evenly spaced posts.
    poly(d, [(0, 0), (140, 0), (140, 32), (104, 66),
             (104, 232), (0, 232)], "ink")
    poly(d, [(0, 8), (111, 8), (111, 28), (82, 58),
             (82, 223), (0, 223)], "iron")
    for x in (20, 55):
        box(d, (x, 16, x + 5, 216), "steel")
    for y in (45, 112, 181):
        box(d, (0, y, 81, y + 4), "shadow")
        rivets(d, 12, 77, y + 6, 18)
    lit_panel(d, (36, 75, 87, 153), "steel")
    # Rescue emblem is a geometric in-world symbol, not external typography.
    box(d, (52, 90, 70, 137), "ice")
    box(d, (38, 105, 83, 121), "ice")
    box(d, (56, 94, 65, 132), "cyan")
    box(d, (42, 109, 79, 117), "cyan")
    structural_column(d, 147, wide=True)
    structural_column(d, 718)
    structural_column(d, 1322, wide=True)
    # Short overhead catwalks alternate with open negative space around actors.
    catwalk(d, 222, 359, 175)
    catwalk(d, 600, 704, 145)
    catwalk(d, 789, 962, 166)
    catwalk(d, 1154, 1303, 182)
    # Hoist, repair arms and compact service pods, all raised off the floor.
    box(d, (668, 0, 732, 18), "shadow")
    box(d, (674, 5, 726, 8), "edge")
    box(d, (696, 18, 702, 91), "steel")
    box(d, (691, 80, 707, 107), "ink")
    box(d, (694, 84, 704, 100), "dark_amber")
    stroke(d, [(693, 102), (685, 112), (687, 119), (703, 119)], "amber", 3)
    for x, y in ((312, 35), (882, 52), (1073, 47), (1245, 27)):
        box(d, (x - 17, y - 3, x + 17, y + 3), "ink")
        box(d, (x - 13, y - 1, x + 12, y + 1), "ice")
        box(d, (x - 11, y + 4, x + 10, y + 5), "cyan_dark")
    for x, y in ((275, 201), (644, 215), (946, 205), (1258, 212)):
        box(d, (x, y, x + 28, y + 32), "ink")
        box(d, (x + 3, y + 3, x + 24, y + 29), "steel")
        box(d, (x + 8, y + 6, x + 18, y + 8), "edge_hi")
        box(d, (x + 10, y + 15, x + 17, y + 18), "amber")
        box(d, (x + 6, y + 26, x + 10, y + 27), "shadow")
    # A few clipped distant crates, recessed so they cannot imply playable floor.
    for x in (13, 391, 839, 1195):
        box(d, (x, 228, x + 53, 252), "shadow")
        box(d, (x + 3, 230, x + 49, 248), "iron")
        box(d, (x + 7, 233, x + 13, 244), "steel")
        box(d, (x + 39, 234, x + 44, 244), "edge")
        box(d, (x + 18, 239, x + 31, 241), "edge")
    # Discrete halo steps around actual fixtures, not uniform global tint.
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    for x, y in ((312, 38), (882, 55), (1073, 50), (1245, 30)):
        gd.rectangle((x - 17, y, x + 17, y + 42), fill=(140, 215, 243, 12))
        gd.rectangle((x - 9, y, x + 9, y + 25), fill=(160, 226, 245, 22))
    for x in (767, 864):
        gd.rectangle((x - 16, 220, x + 16, 252), fill=(240, 160, 68, 18))
        gd.rectangle((x - 6, 232, x + 6, 249), fill=(255, 183, 76, 29))
        box(d, (x - 3, 225, x + 3, 230), "ink")
        box(d, (x - 2, 225, x + 2, 228), "amber")
    image.alpha_composite(glow)
    material_grain(image, (0, 0, W, 253),
                   ("iron", "steel"), "edge", "shadow")
    return image


def deck_layer():
    """One continuous, authored machine deck; collision spans crop out the gap."""
    image = Image.new("RGBA", (W, 108), C["ink"])
    d = ImageDraw.Draw(image)
    box(d, (0, 0, W - 1, 5), "edge_hi")
    box(d, (0, 1, W - 1, 2), "ice")
    box(d, (0, 6, W - 1, 12), "steel")
    box(d, (0, 13, W - 1, 17), "shadow")
    # Varied walkway slabs and staggered joints, not square wallpaper tiles.
    x = 0
    slab_widths = (42, 56, 37, 49, 63, 44, 58, 39)
    i = 0
    while x < W:
        right = min(W - 1, x + slab_widths[i % len(slab_widths)] - 2)
        box(d, (x + 1, 7, right, 11), "edge")
        box(d, (x + 4, 8, right - 4, 8), "edge_hi")
        box(d, (x + 7, 14, x + 9, 15), "dark_amber")
        box(d, (right - 9, 14, right - 7, 15), "edge_hi")
        x = right + 2
        i += 1
    box(d, (0, 18, W - 1, 31), "iron")
    box(d, (0, 19, W - 1, 20), "steel")
    box(d, (0, 30, W - 1, 33), "ink")
    for x in range(15, W, 79):
        lit_panel(d, (x, 23, x + 47, 31), "steel")
        box(d, (x + 9, 25, x + 25, 25), "cyan_dark")
    # Large bays, trusses and shadowed voids span several 24px tiles each.
    for bay, width in ((0, 152), (152, 178), (330, 154), (484, 205),
                       (689, 165), (854, 194), (1048, 186), (1234, 206)):
        end = min(W - 1, bay + width - 1)
        box(d, (bay + 4, 36, end - 4, 104), "shadow")
        box(d, (bay + 13, 48, end - 14, 88), "abyss")
        box(d, (bay + 15, 49, end - 16, 51), "steel")
        box(d, (bay + 17, 83, end - 17, 86), "iron")
        stroke(d, [(bay + 15, 41), (end - 16, 96)], "steel", 7)
        stroke(d, [(bay + 17, 42), (end - 14, 96)], "edge", 1)
        stroke(d, [(end - 14, 41), (bay + 16, 96)], "steel", 6)
        box(d, (bay + 3, 35, bay + 12, 107), "ink")
        box(d, (bay + 5, 38, bay + 9, 101), "steel")
        box(d, (end - 11, 35, end - 2, 107), "ink")
        box(d, (end - 9, 38, end - 5, 101), "edge")
        box(d, (bay + 19, 60, bay + 30, 65), "cyan_dark")
        box(d, (end - 39, 60, end - 28, 65), "dark_amber")
        rivets(d, bay + 22, end - 18, 39, 37, "edge_hi")
    box(d, (0, 34, W - 1, 38), "steel")
    box(d, (0, 102, W - 1, 107), "ink")
    for x in (83, 306, 580, 816, 1007, 1316):
        box(d, (x, 43, x + 42, 80), "ink")
        box(d, (x + 3, 46, x + 39, 76), "iron")
        box(d, (x + 8, 50, x + 35, 52), "edge")
        for y in (58, 63, 68):
            box(d, (x + 10, y, x + 31, y + 1), "steel")
        box(d, (x + 8, 73, x + 12, 74), "cyan_dark")
    return image


def render_hangar(output: Path):
    far_layer().save(output / "hangar_far.png", optimize=True)
    mid_layer().save(output / "hangar_mid.png", optimize=True)
    deck_layer().save(output / "hangar_deck.png", optimize=True)
