extends Control

# Review-only, editable, integer-pixel UI. Never attach to the production HUD.
const ROOT := "res://prototypes/issue-27-ui/"
const FONT_PATH := ROOT + "source/fonts/fusion-pixel-12px-proportional-zh_hans.otf"
const CYAN := Color("8de9ed")
const CYAN_DARK := Color("287f91")
const AMBER := Color("ffcb7b")
const AMBER_DARK := Color("926036")
const WHITE := Color("e5f2f2")
const MUTED := Color("9aafbd")
const INK := Color("09141f")
const REQUIRED_GLYPHS := "行动员生命危险防御机甲任务失败完成跌落深渊耗尽从关卡起点重试已击败护甲解除全部生命剩余目标停止威胁R0123456789/"
var state := "hud"
var health := 3
var boss_health := 78
var boss_max := 120
var show_boss := true
var font: FontFile
var panel: Texture2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	font = FontFile.new()
	font.data = FileAccess.get_file_as_bytes(FONT_PATH)
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.hinting = TextServer.HINTING_NONE
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	font.oversampling = 1.0
	font.allow_system_fallback = false
	for character in REQUIRED_GLYPHS:
		assert(font.has_char(character.unicode_at(0)), "Missing glyph: " + character)
	panel = ImageTexture.create_from_image(Image.load_from_file(ROOT + "source/console-panel.png"))
	queue_redraw()

func text_at(value: String, point: Vector2, size_px: int = 12, color: Color = WHITE) -> void:
	draw_string(font, point + Vector2(0, 1), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, INK)
	draw_string(font, point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, color)

func bevel(rect: Rect2, color: Color, cut: int = 4) -> void:
	# Stepped corners: no subpixel diagonal strokes or antialiasing.
	var x := rect.position.x
	var y := rect.position.y
	var w := rect.size.x
	var h := rect.size.y
	draw_rect(Rect2(x + cut, y, w - cut * 2, h), color)
	draw_rect(Rect2(x, y + cut, w, h - cut * 2), color)
	draw_rect(Rect2(x + 2, y + 2, w - 4, h - 4), color)

func screw(x: int, y: int) -> void:
	draw_rect(Rect2(x, y, 3, 3), INK)
	draw_rect(Rect2(x, y, 2, 1), Color("b0bec8"))
	draw_rect(Rect2(x + 1, y + 2, 2, 1), Color("344657"))

func chassis(rect: Rect2) -> void:
	bevel(Rect2(rect.position + Vector2(0, 2), rect.size), Color("030b12"))
	bevel(rect, Color("101b29"))
	bevel(rect.grow(-1), Color("738494"))
	bevel(rect.grow(-2), Color("34495d"))
	bevel(rect.grow(-4), Color("172a3b"))
	bevel(rect.grow(-6), Color("0b1927"), 2)
	# Short machined seams on the outer skin, not across the information.
	for x in [int(rect.position.x + 22), int(rect.end.x - 34)]:
		draw_rect(Rect2(x, rect.position.y + 2, 12, 2), Color("1b2b3b"))
		draw_rect(Rect2(x + 1, rect.position.y + 2, 9, 1), Color("536b7f"))
	for x in [int(rect.position.x + 3), int(rect.end.x - 6)]:
		screw(x, int(rect.position.y + 6))
		screw(x, int(rect.end.y - 9))

func cell(at: Vector2, filled: bool, accent: Color, shade: Color) -> void:
	bevel(Rect2(at, Vector2(28, 18)), Color("425b6e"), 3)
	bevel(Rect2(at + Vector2(1, 1), Vector2(26, 16)), INK, 2)
	if filled:
		bevel(Rect2(at + Vector2(3, 3), Vector2(22, 12)), shade, 2)
		draw_rect(Rect2(at + Vector2(5, 4), Vector2(18, 8)), accent)
		draw_rect(Rect2(at + Vector2(6, 4), Vector2(16, 1)), WHITE)
		draw_rect(Rect2(at + Vector2(5, 12), Vector2(18, 2)), shade)
	else:
		draw_rect(Rect2(at + Vector2(5, 7), Vector2(18, 3)), Color("243848"))
		for x in [7, 13, 19]:
			draw_rect(Rect2(at + Vector2(x, 5), Vector2(2, 7)), Color("3d5363"))
	# Armor retaining clips keep each life visibly separate.
	draw_rect(Rect2(at + Vector2(0, 7), Vector2(3, 4)), Color("92a6b4"))
	draw_rect(Rect2(at + Vector2(25, 7), Vector2(3, 4)), Color("92a6b4"))

func warning(at: Vector2, color: Color) -> void:
	# Original native pixel warning symbol, not a character in a fallback font.
	for row in 6:
		draw_rect(Rect2(at + Vector2(6 - row, row * 2), Vector2(row * 2 + 1, 2)), color)
	draw_rect(Rect2(at + Vector2(6, 4), Vector2(1, 4)), INK)
	draw_rect(Rect2(at + Vector2(6, 10), Vector2(1, 1)), INK)

func life_module() -> void:
	var danger := health <= 1
	var accent := AMBER if danger else CYAN
	chassis(Rect2(12, 10, 182, 52))
	text_at("行动员", Vector2(25, 28), 12, MUTED)
	text_at("%d/3" % health, Vector2(111, 28), 12, accent)
	if danger:
		text_at("危险", Vector2(151, 28), 12, AMBER)
	else:
		text_at("生命", Vector2(151, 28), 12, MUTED)
	for i in 3:
		cell(Vector2(25 + i * 36, 33), i < health, accent, AMBER_DARK if danger else CYAN_DARK)
	# Small identification grooves on the right, separate from the life slots.
	for y in [37, 41, 45]:
		draw_rect(Rect2(141, y, 30, 1), Color("30495b"))

func boss_module() -> void:
	chassis(Rect2(364, 10, 264, 52))
	warning(Vector2(377, 19), AMBER)
	text_at("防御机甲", Vector2(397, 29), 12, WHITE)
	text_at("%d/%d" % [boss_health, boss_max], Vector2(554, 29), 12, AMBER)
	meter(Rect2(377, 36, 238, 13), boss_health, boss_max)

func meter(rect: Rect2, value: int, maximum: int) -> void:
	bevel(rect, Color("516071"), 2)
	bevel(rect.grow(-1), Color("050e16"), 1)
	var inside := Rect2(rect.position + Vector2(3, 3), rect.size - Vector2(6, 6))
	draw_rect(inside, Color("243342"))
	# Keep 1/max visibly nonzero. Markers sit below fill, never erase it.
	var width := maxi(1, int(floor(inside.size.x * value / maximum))) if value > 0 else 0
	if width > 0:
		draw_rect(Rect2(inside.position, Vector2(width, inside.size.y)), AMBER_DARK)
		draw_rect(Rect2(inside.position, Vector2(width, 4)), AMBER)
		draw_rect(Rect2(inside.position, Vector2(width, 1)), Color("ffe2ae"))
	for i in range(1, 10):
		draw_rect(Rect2(rect.position.x + 3 + floor(i * inside.size.x / 10), rect.end.y + 2, 1, 2), Color("697e8b"))

func status_badge(at: Vector2, success: bool) -> void:
	chassis(Rect2(at, Vector2(40, 40)))
	if success:
		# Pixel check mark, distinct silhouette from a warning triangle.
		for i in 4:
			draw_rect(Rect2(at + Vector2(10 + i * 2, 19 + i * 2), Vector2(3, 3)), CYAN)
		for i in 7:
			draw_rect(Rect2(at + Vector2(16 + i * 2, 25 - i * 2), Vector2(3, 3)), CYAN)
	else:
		draw_set_transform(at + Vector2(7, 7), 0, Vector2(2, 2))
		warning(Vector2.ZERO, AMBER)
		draw_set_transform(Vector2.ZERO)

func outcome() -> void:
	var success := state == "complete"
	var accent := CYAN if success else AMBER
	draw_rect(Rect2(0, 0, 640, 360), Color(0.015, 0.035, 0.065, 0.40))
	# EXACT same source, sample rect and outer placement as the approved failure frame.
	draw_texture_rect_region(panel, Rect2(146, 76, 348, 174), Rect2(20, 92, 1734, 682))
	status_badge(Vector2(190, 112), success)
	text_at("任务完成" if success else "任务失败", Vector2(244, 138), 24, accent)
	text_at("防御机甲已击败" if success else ("跌落深渊" if state == "fall" else "生命耗尽"), Vector2(245, 159), 12, WHITE)
	if success:
		text_at("0/%d" % boss_max, Vector2(404, 159), 12, CYAN)
		# Cleared progress rail visually differs from the failure caution strip.
		draw_rect(Rect2(192, 175, 256, 1), Color("345364"))
		for x in [192, 276, 360, 444]:
			draw_rect(Rect2(x, 173, 4, 4), CYAN)
	else:
		for x in range(192, 448, 8):
			draw_rect(Rect2(x, 175, 4, 2), AMBER_DARK)
	chassis(Rect2(200, 192, 240, 34))
	bevel(Rect2(211, 199, 23, 20), Color("526c7d"), 2)
	bevel(Rect2(212, 200, 21, 18), Color("192e3c"), 2)
	text_at("R", Vector2(220, 214), 12, accent)
	text_at("从关卡起点重试", Vector2(249, 214), 12, WHITE)

func _draw() -> void:
	if font == null:
		return
	if state in ["death", "fall", "complete"]:
		outcome()
	else:
		life_module()
		if show_boss:
			boss_module()
