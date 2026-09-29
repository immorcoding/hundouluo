extends SceneTree

# Offline review renderer only. Never attached to the production scene.
const OUT := "res://prototypes/issue-27-ui/"
const CASES := ["hud", "death", "complete", "start", "low-health", "fall"]

class ReviewUI extends Control:
	const CYAN := Color("8de4e8")
	const AMBER := Color("ffc578")
	const WHITE := Color("ecf7fa")
	const MUTED := Color("a7bac7")
	var state := "hud"
	var health := 3
	var boss_health := 78
	var boss_max := 120
	var font: SystemFont
	var panel: Texture2D

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		font = SystemFont.new()
		font.font_names = PackedStringArray(["Microsoft YaHei"])
		font.font_weight = 600
		var source := Image.load_from_file(OUT + "source/console-panel.png")
		# Keep source intact; draw the recorded panel region below.
		panel = ImageTexture.create_from_image(source)
		queue_redraw()

	func text_at(value: String, point: Vector2, size_px: int, color: Color) -> void:
		draw_string(font, point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, color)

	func centered(value: String, y: float, size_px: int, color: Color) -> void:
		var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
		text_at(value, Vector2(round((640 - width) / 2), y), size_px, color)

	func plate(rect: Rect2, accent: Color) -> void:
		draw_style_box(_plate_style(), rect)
		draw_rect(Rect2(rect.position + Vector2(0, 6), Vector2(2, rect.size.y - 12)), accent)

	func _plate_style() -> StyleBoxFlat:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("0b1b29")
		style.border_color = Color("446073")
		style.set_border_width_all(1)
		style.set_corner_radius_all(3)
		return style

	func _draw() -> void:
		if font == null:
			return
		var danger := health <= 1
		var life_color := AMBER if danger else CYAN
		plate(Rect2(12, 12, 174, 52), life_color)
		text_at("行动员", Vector2(24, 32), 13, WHITE)
		text_at("生命 %d / 3" % health, Vector2(110, 32), 11, MUTED)
		for i in 3:
			var rect := Rect2(24 + i * 27, 42, 21, 10)
			draw_rect(rect, life_color if i < health else Color("142838"))
			draw_rect(rect, life_color if i < health else Color("657b8a"), false, 1)
			if i >= health:
				draw_line(rect.position + Vector2(5, 7), rect.position + Vector2(15, 2), MUTED, 1)
		text_at("危险" if danger else "生命", Vector2(112, 52), 11, life_color)
		if state != "start" and state != "fall":
			plate(Rect2(350, 12, 278, 52), AMBER)
			text_at("防御机甲", Vector2(362, 32), 13, WHITE)
			text_at("%03d / %03d" % [boss_health, boss_max], Vector2(542, 32), 11, AMBER)
			draw_rect(Rect2(362, 44, 252, 8), Color("344552"))
			draw_rect(Rect2(362, 44, floor(252.0 * boss_health / boss_max), 8), AMBER)
			for i in range(1, 10):
				draw_line(Vector2(362 + round(i * 25.2), 44), Vector2(362 + round(i * 25.2), 52), Color("142430"), 1)
		if state in ["death", "fall", "complete"]:
			var success := state == "complete"
			var accent := CYAN if success else AMBER
			draw_rect(Rect2(0, 0, 640, 360), Color(0.015, 0.035, 0.065, 0.48))
			draw_texture_rect_region(panel, Rect2(146, 76, 348, 174), Rect2(20, 92, 1734, 682))
			draw_line(Vector2(188, 98), Vector2(452, 98), accent, 2)
			centered("任务完成" if success else "任务失败", 139, 27, accent)
			var reason := "防御机甲已击败" if success else ("跌落深渊" if state == "fall" else "生命耗尽")
			centered(reason, 170, 15, WHITE)
			draw_line(Vector2(190, 186), Vector2(450, 186), Color("3c5365"), 1)
			draw_rect(Rect2(208, 201, 24, 23), accent)
			text_at("R", Vector2(215, 218), 15, Color("10202c"))
			text_at("从关卡起点重试", Vector2(243, 218), 14, WHITE)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	for state in CASES:
		var level := (load("res://scenes/level.tscn") as PackedScene).instantiate()
		root.add_child(level)
		var actor := level.get_node("Operative/Operative") as CharacterBody2D
		var mech := level.get_node("BossSlot/DefenseMech") as DefenseMech
		# Actual level, actual sprites and actual existing gameplay transitions.
		actor.position = Vector2(1250 if state in ["start", "fall"] else 3700, 252)
		actor.invulnerability_duration = 0.0
		for tick in 4:
			await physics_frame
		if state not in ["start", "fall"]:
			for hit in 42:
				mech.receive_hit()
		if state == "low-health":
			actor.receive_hit()
			actor.receive_hit()
		if state == "death":
			for hit in 3:
				actor.receive_hit()
		elif state == "complete":
			for hit in mech.health:
				mech.receive_hit()
		elif state == "fall":
			actor.position = Vector2(1392, 425)
			for tick in 3:
				await physics_frame
		else:
			Input.action_press("shoot")
			for tick in 12:
				await physics_frame
			Input.action_release("shoot")
		level.process_mode = Node.PROCESS_MODE_DISABLED
		level.get_node("HUD").hide()
		await process_frame
		await RenderingServer.frame_post_draw
		if not _save("captures/" + state + ".png"):
			return
		var layer := CanvasLayer.new()
		layer.layer = 100
		root.add_child(layer)
		var ui := ReviewUI.new()
		ui.state = state
		ui.health = actor.health
		ui.boss_health = mech.health
		ui.boss_max = mech.max_health
		layer.add_child(ui)
		await process_frame
		await RenderingServer.frame_post_draw
		if not _save("previews/" + state + ".png"):
			return
		print("CAPTURE ", state, " life=", actor.health, " mech=", mech.health, "/", mech.max_health)
		layer.queue_free()
		level.queue_free()
		await process_frame
	quit(0)

func _save(relative_path: String) -> bool:
	var screenshot := root.get_texture().get_image()
	if screenshot.get_size() != Vector2i(640, 360):
		push_error("Review image must be exactly 640x360")
		quit(1)
		return false
	if screenshot.save_png(OUT + relative_path) != OK:
		push_error("Could not save " + relative_path)
		quit(1)
		return false
	return true
