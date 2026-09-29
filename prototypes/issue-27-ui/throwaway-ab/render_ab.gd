extends SceneTree
# THROWAWAY A/B/C/D: D adds a current-rifle silhouette without growing C housing.
# C/D outcomes deliberately match A, isolating the HUD variable.
const DIR := "res://prototypes/issue-27-ui/throwaway-ab/"

class Layout extends Control:
	var variant := "A"
	var fire_mode := "auto"
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
		if variant in ["C", "D", "E"]:
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
	func current_rifle(at: Vector2) -> void:
		# Original native pixel interpretation of #22 operative-sheet.png's rifle:
		# white receiver, cyan upper rail, dark short muzzle; no ammo/weapon switch.
		draw_set_transform(at)
		draw_rect(Rect2(0, 4, 14, 7), Color("607b88"))
		draw_rect(Rect2(2, 5, 10, 4), WHITE)
		draw_rect(Rect2(10, 2, 36, 11), Color("314c5b"))
		draw_rect(Rect2(12, 4, 32, 7), WHITE)
		draw_rect(Rect2(24, 0, 20, 5), Color("254653"))
		draw_rect(Rect2(26, 2, 16, 2), CYAN)
		draw_rect(Rect2(14, 9, 28, 2), Color("869da6"))
		draw_rect(Rect2(44, 4, 14, 7), DARK)
		draw_rect(Rect2(44, 5, 12, 4), Color("607b88"))
		draw_rect(Rect2(54, 6, 4, 3), Color("29434f"))
		draw_rect(Rect2(16, 11, 6, 5), Color("607b88"))
		draw_rect(Rect2(18, 11, 4, 4), Color("29434f"))
		draw_rect(Rect2(32, 11, 8, 3), Color("29434f"))
		draw_set_transform(Vector2.ZERO)
	func d_life() -> void:
		# One semantic life display; no duplicate fraction or resource counters.
		text("生命", 62, 342, 12, WHITE)
		for i in 3:
			var cell := Rect2(90 + i * 22, 333, 18, 9)
			draw_rect(cell.grow(1), DARK)
			if i < record.life:
				draw_rect(cell, AMBER if record.life == 1 else CYAN)
			else:
				draw_rect(cell, CYAN, false, 1)
	func e_resources() -> void:
		# Visual concepts only. The game has no semi/auto switch or ammo inventory.
		text("生命", 62, 342, 12, WHITE)
		for i in 3:
			var cell := Rect2(90 + i * 18, 333, 14, 9)
			draw_rect(cell.grow(1), DARK)
			if i < record.life:
				draw_rect(cell, CYAN)
			else:
				draw_rect(cell, Color("79949f"), false, 1)
		draw_rect(Rect2(144, 310, 1, 32), Color("425766"))
		for i in 3:
			var y := 310 + i * 11
			var filled := fire_mode == "auto" or i == 0
			var brass := Color("d6a368")
			# Flat open mouth, narrow case body, and projecting base rim (no bullet tip).
			draw_rect(Rect2(150, y, 4, 2), brass)
			draw_rect(Rect2(149, y + 2, 6, 6), brass, filled)
			if not filled:
				draw_rect(Rect2(150, y + 2, 4, 5), DARK)
			else:
				draw_rect(Rect2(150, y + 2, 1, 5), Color("f5c98c"))
			draw_rect(Rect2(148, y + 8, 8, 1), brass)
			draw_rect(Rect2(151, y, 2, 1), DARK)
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
				if variant == "C":
					text("生命", 62, 321, 12, WHITE)
					if record.life == 1:
						text("危险", 128, 321, 12, AMBER)
					lives(62, 328)
				else:
					current_rifle(Vector2(62, 310))
					if variant == "E":
						e_resources()
					else:
						if record.life == 1:
							text("危险", 128, 321, 12, AMBER)
						d_life()
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
		for variant in ["A", "B", "C", "D", "E-semi", "E-auto"]:
			var layout := Layout.new()
			layout.variant = "E" if variant.begins_with("E-") else variant
			layout.fire_mode = "semi" if variant == "E-semi" else "auto"
			layout.state = state
			layout.record = records[state]
			root.add_child(layout)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(DIR + "images/" + variant + "-" + state + ".png")
			layout.queue_free()
			await process_frame
		for pair in [["A", "B", "compare-"], ["A", "C", "compare-AC-"], ["C", "D", "compare-CD-"], ["D", "E-auto", "compare-DE-"], ["E-semi", "E-auto", "compare-modes-"]]:
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
