extends SceneTree
# THROWAWAY: two proportions of the user's four-zone sketch, not variants F/G.
const OLD := preload("res://prototypes/issue-27-ui/throwaway-ab/render_ab.gd")
const OUT := "res://prototypes/issue-27-ui/throwaway-block-layout/"

class BlockLayout extends OLD.Layout:
	var proportion := "compact"
	func metal(rect: Rect2) -> void:
		draw_rect(rect, DARK)
		draw_rect(rect.grow(-1), Color("7e909e"), false, 1)
		draw_rect(rect.grow(-2), Color("344859"), false, 2)
		draw_rect(rect.grow(-4), Color("10202c"))
		for x in [rect.position.x + 4, rect.end.x - 6]:
			draw_rect(Rect2(x, rect.position.y + 4, 2, 2), Color("a6b6bf"))
			draw_rect(Rect2(x, rect.end.y - 6, 2, 2), Color("566b7c"))
	func gun_part(at: Vector2, scale_factor: float, rect: Rect2, color: Color) -> void:
		draw_rect(Rect2((at + rect.position * scale_factor).round(), (rect.size * scale_factor).round()), color)
	func gun(at: Vector2, scale_factor: float) -> void:
		gun_part(at, scale_factor, Rect2(0,4,14,7), Color("718a95"))
		gun_part(at, scale_factor, Rect2(2,5,10,4), WHITE)
		gun_part(at, scale_factor, Rect2(10,2,36,11), Color("344b5b"))
		gun_part(at, scale_factor, Rect2(12,4,32,7), WHITE)
		gun_part(at, scale_factor, Rect2(24,0,20,5), Color("254653"))
		gun_part(at, scale_factor, Rect2(26,2,16,2), CYAN)
		gun_part(at, scale_factor, Rect2(14,9,28,2), Color("869da6"))
		gun_part(at, scale_factor, Rect2(44,4,14,7), Color("607b88"))
		gun_part(at, scale_factor, Rect2(54,6,4,3), Color("29434f"))
		gun_part(at, scale_factor, Rect2(16,11,6,5), Color("718a95"))
		gun_part(at, scale_factor, Rect2(18,11,4,4), Color("29434f"))
		gun_part(at, scale_factor, Rect2(32,11,8,3), Color("29434f"))
	func casing(at: Vector2, filled: bool, scale_factor: int) -> void:
		# Horizontal casing silhouette, stacked vertically like the actual sketch.
		# Narrow open mouth left, cylinder centre, projecting base rim right.
		var brass := Color("d6a368")
		draw_set_transform(at, 0, Vector2(scale_factor, scale_factor))
		draw_rect(Rect2(0,2,3,3), brass)
		draw_rect(Rect2(3,1,13,5), brass)
		draw_rect(Rect2(16,0,2,7), brass)
		if not filled:
			draw_rect(Rect2(4,2,11,3), DARK)
		else:
			draw_rect(Rect2(4,1,10,1), Color("f4c990"))
		draw_rect(Rect2(0,3,2,1), DARK)
		draw_set_transform(Vector2.ZERO)
	func _draw() -> void:
		draw_texture(background, Vector2.ZERO)
		var roomy := proportion == "roomy"
		var box := Rect2(12, 260, 240, 88) if roomy else Rect2(12, 276, 204, 72)
		metal(box)
		var face := Rect2(20, 268, 64, 72) if roomy else Rect2(20, 284, 48, 56)
		# A separate vertical portrait compartment; no sketch labels in the UI.
		draw_rect(face, Color("263e4c"))
		draw_rect(face, Color("526d7d"), false, 1)
		var portrait_dest := Rect2(face.position + Vector2(2, 6), Vector2(60,60)) if roomy else Rect2(face.position + Vector2(2,6), Vector2(44,44))
		draw_texture_rect_region(portrait, portrait_dest, Rect2(310,184,656,632))
		var mid_x := 96 if roomy else 80
		var top := 276 if roomy else 290
		gun(Vector2(mid_x, top), 1.5 if roomy else 1.25)
		var ammo_x := 208 if roomy else 182
		var ammo_y := 272 if roomy else top
		for i in 3:
			casing(Vector2(ammo_x, ammo_y + i * (16 if roomy else 10)), fire_mode == "auto" or i == 0, 2 if roomy else 1)
		# Broad, clearly separated health cells form a second horizontal tier.
		var cell_width := 42 if roomy else 36
		var cell_height := 14 if roomy else 12
		var life_y := 324 if roomy else 326
		draw_rect(Rect2(mid_x, life_y - 6, cell_width * 3 + 8, 1), Color("344b5a"))
		for i in 3:
			var cell := Rect2(mid_x + i * (cell_width + 4), life_y, cell_width, cell_height)
			draw_rect(cell.grow(1), Color("536c78"))
			draw_rect(cell, CYAN if i < record.life else DARK)
		if record.get("boss_visible", true):
			text("防御机甲", 224, 24, 12, WHITE)
			text("%d/%d" % [record.boss, record.max], 376, 24, 12, AMBER)
			progress(224,31,192)

func _initialize() -> void:
	call_deferred("render")
func render() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OLD.DIR + "captures/states.json"))
	for state in ["normal","combat","low","gap-left"]:
		for mode in ["semi","auto"]:
			for proportion in ["compact","roomy"]:
				root.content_scale_size = Vector2i(640,360)
				var ui := BlockLayout.new()
				ui.variant = "C"
				ui.state = state
				ui.record = data[state]
				ui.fire_mode = mode
				ui.proportion = proportion
				root.add_child(ui)
				await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(OUT + "images/" + proportion + "-" + mode + "-" + state + ".png")
				ui.queue_free()
				await process_frame
			root.content_scale_size = Vector2i(1280,360)
			var pair := Control.new()
			root.add_child(pair)
			for i in 2:
				var picture := TextureRect.new()
				picture.texture = ImageTexture.create_from_image(Image.load_from_file(OUT + "images/" + ("compact" if i==0 else "roomy") + "-" + mode + "-" + state + ".png"))
				picture.position = Vector2(i*640,0)
				pair.add_child(picture)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OUT + "images/compare-" + mode + "-" + state + ".png")
			pair.queue_free()
			await process_frame
	quit()
