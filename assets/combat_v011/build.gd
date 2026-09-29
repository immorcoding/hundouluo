extends SceneTree

const OUT := "res://assets/combat_v011/"
const NAMES := ["friendly", "soldier", "mech", "friendly_muzzle", "enemy_muzzle", "armor_hit", "wall_hit", "mech_charge"]
const SIZES := [Vector2i(18, 8), Vector2i(14, 8), Vector2i(22, 10), Vector2i(20, 14), Vector2i(20, 14), Vector2i(24, 24), Vector2i(18, 18), Vector2i(32, 32)]

func _initialize() -> void:
	var source := Image.load_from_file(OUT + "source.png")
	if source == null or source.detect_alpha() == Image.ALPHA_NONE:
		push_error("Missing transparent source")
		quit(1)
		return
	var cell := Vector2i(source.get_width() / 4, source.get_height() / 8)
	var atlas := Image.create(192, 320, false, Image.FORMAT_RGBA8)
	var manifest := {"cell": [48, 40], "columns": 4, "rows": [], "filter": "nearest", "pivot": [24, 20]}
	for row in 8:
		var bounds := Rect2i()
		var frames: Array[Image] = []
		for col in 4:
			var frame := source.get_region(Rect2i(Vector2i(col, row) * cell, cell))
			frames.append(frame)
			# Measure solid artwork, excluding nearly invisible generator fringe.
			var measure := frame.duplicate() as Image
			for y in measure.get_height():
				for x in measure.get_width():
					if measure.get_pixel(x, y).a < 0.3:
						measure.set_pixel(x, y, Color.TRANSPARENT)
			var used := measure.get_used_rect()
			bounds = used if col == 0 else bounds.merge(used)
		if bounds.size.x == 0 or bounds.size.y == 0:
			push_error("Empty row")
			quit(1)
			return
		var ratio := minf(float(SIZES[row].x) / bounds.size.x, float(SIZES[row].y) / bounds.size.y)
		var size := Vector2i(maxi(1, roundi(bounds.size.x * ratio)), maxi(1, roundi(bounds.size.y * ratio)))
		for col in 4:
			var frame := frames[col].get_region(bounds)
			frame.resize(size.x, size.y, Image.INTERPOLATE_NEAREST)
			atlas.blit_rect(frame, Rect2i(Vector2i.ZERO, size), Vector2i(col * 48 + 24 - size.x / 2, row * 40 + 20 - size.y / 2))
		manifest.rows.append({"name": NAMES[row], "row": row, "max_size": [size.x, size.y]})
	if atlas.save_png(OUT + "atlas.png") != OK:
		quit(1)
		return
	var file := FileAccess.open(OUT + "atlas.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t") + "\n")
	print("Built independent combat atlas 192x320")
	quit()
