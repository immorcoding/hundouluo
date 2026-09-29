extends SceneTree
# THROWAWAY A/B/C: compare lightweight A with conventional bottom-left portrait C.
# C outcomes deliberately match A, isolating the HUD variable.
const DIR := "res://prototypes/issue-27-ui/throwaway-ab/"

class Layout extends Control:
	var variant := "A"
	var state := "combat"
	var record: Dictionary
	var background: Texture2D
	var font: FontFile
	var panel: Texture2D
	var portrait: Texture2D
	const WHITE := Color("e5f2f2")
	const CYAN := Color("8de9ed")
	const AMBER := Color("ffcb7b")
	const DARK := Color("09141f")
	func _ready() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		font = FontFile.new()
		font.data = FileAccess.get_file_as_bytes("res://prototypes/issue-27-ui/source/fonts/fusion-pixel-12px-proportional-zh_hans.otf")
		font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		font.hinting = TextServer.HINTING_NONE
		font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		font.oversampling = 1
		font.allow_system_fallback = false
		background = ImageTexture.create_from_image(Image.load_from_file(DIR + "captures/" + state + ".png"))
		panel = ImageTexture.create_from_image(Image.load_from_file("res://prototypes/issue-27-ui/source/console-panel.png"))
		if variant == "C":
			portrait = ImageTexture.create_from_image(Image.load_from_file(DIR + "source/operative-portrait.png"))
	func text(value: String, x: int, y: int, size_px: int, color: Color) -> void:
		draw_string_outline(font, Vector2(x, y), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, 2, DARK)
		draw_string(font, Vector2(x, y), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, color)
	func centered(value: String, y: int, size_px: int, color: Color) -> void:
		text(value, int(320 - font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x / 2), y, size_px, color)
	func lives(x: int, y: int) -> void:
		for i in 3:
			var cell := Rect2(x + i * 24, y, 18, 10)
			draw_rect(cell.grow(1), DARK)
			if i < record.life:
				draw_rect(cell, AMBER if record.life == 1 else CYAN)
			else:
				draw_rect(cell, CYAN, false, 1)
	func progress(x: int, y: int, width: int) -> void:
		draw_rect(Rect2(x - 1, y - 1, width + 2, 8), DARK)
		draw_rect(Rect2(x, y, width, 6), Color("31434e"))
		if record.boss > 0:
			draw_rect(Rect2(x, y, maxi(1, int(width * float(record.boss) / record.max)), 6), AMBER)
	func _draw() -> void:
		draw_texture(background, Vector2.ZERO)
		if state not in ["failure", "complete"]:
			var boss_visible: bool = record.get("boss_visible", true)
			if variant == "A":
				text("生命", 16, 27, 12, WHITE)
				lives(52, 17)
				if record.life == 1:
					text("危险", 132, 27, 12, AMBER)
				if boss_visible:
					text("防御机甲", 432, 24, 12, WHITE)
					text("%d/%d" % [record.boss, record.max], 584, 24, 12, AMBER)
					progress(432, 31, 192)
			elif variant == "B":
				draw_rect(Rect2(12, 12, 124, 30), Color("10212e"))
				text("生命", 20, 31, 12, WHITE)
				lives(56, 21)
				if record.life == 1:
					text("危险", 144, 31, 12, AMBER)
				if boss_visible:
					draw_rect(Rect2(424, 12, 204, 30), Color("10212e"))
					text("防御机甲", 432, 27, 12, WHITE)
					text("%d/%d" % [record.boss, record.max], 584, 27, 12, AMBER)
					progress(432, 33, 188)
			else:
				# C: one compact metal housing, down in the deck fascia region.
				draw_rect(Rect2(12, 304, 152, 44), DARK)
				draw_rect(Rect2(13, 305, 150, 42), Color("657a8b"), false, 1)
				draw_rect(Rect2(14, 307, 148, 39), Color("142532"))
				draw_rect(Rect2(16, 307, 143, 1), Color("9aafbd"))
				draw_texture_rect_region(portrait, Rect2(18, 309, 36, 36), Rect2(310, 184, 656, 632))
				text("生命", 62, 321, 12, WHITE)
				if record.life == 1:
					text("危险", 128, 321, 12, AMBER)
				lives(62, 328)
				if boss_visible:
					text("防御机甲", 224, 24, 12, WHITE)
					text("%d/%d" % [record.boss, record.max], 376, 24, 12, AMBER)
					progress(224, 31, 192)
		else:
			var success := state == "complete"
			var title := "任务完成" if success else "任务失败"
			var reason := "防御机甲已击败" if success else "生命耗尽"
			var accent := CYAN if success else AMBER
			draw_rect(Rect2(0, 0, 640, 360), Color(0.015, 0.035, 0.065, 0.30))
			if variant != "B":
				centered(title, 142, 24, accent)
				centered(reason, 170, 12, WHITE)
				draw_rect(Rect2(304, 190, 32, 1), accent)
				centered("R 从关卡起点重试", 222, 12, WHITE)
			else:
				# One container only; no badge, keycap, nested button or progress decoration.
				draw_texture_rect_region(panel, Rect2(160, 108, 320, 144), Rect2(20, 92, 1734, 682))
				text(title, 192, 152, 24, accent)
				text(reason, 192, 180, 12, WHITE)
				text("R 从关卡起点重试", 192, 222, 12, WHITE)

func _initialize() -> void:
	call_deferred("render")
func render() -> void:
	var records: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIR + "captures/states.json"))
	for state in ["normal", "low", "combat", "gap-left", "failure", "complete"]:
		root.content_scale_size = Vector2i(640, 360)
		for variant in ["A", "B", "C"]:
			var layout := Layout.new()
			layout.variant = variant
			layout.state = state
			layout.record = records[state]
			root.add_child(layout)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(DIR + "images/" + variant + "-" + state + ".png")
			layout.queue_free()
			await process_frame
		for pair in [["A", "B", "compare-"], ["A", "C", "compare-AC-"]]:
			root.content_scale_size = Vector2i(1280, 360)
			var both := Control.new()
			root.add_child(both)
			for i in 2:
				var sprite := TextureRect.new()
				sprite.texture = ImageTexture.create_from_image(Image.load_from_file(DIR + "images/" + pair[i] + "-" + state + ".png"))
				sprite.position = Vector2(i * 640, 0)
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				both.add_child(sprite)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(DIR + "images/" + pair[2] + state + ".png")
			both.queue_free()
			await process_frame
	quit()
