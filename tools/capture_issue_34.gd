extends SceneTree
## Public-scene visual regression for enemy wreck occlusion.
## Fixtures disclose direct receive_hit setup; all images are production
## sprites rendered in the actual 640x360 level viewport.

const DEFAULT_OUTPUT := "res://docs/art/issue-34/after/soldier-standing"
const RAW_FRAME_ROOT := "res://.godot/issue-34-frames"

var output_dir := DEFAULT_OUTPUT
var enemy_kind := "soldier"
var actor: CharacterBody2D
var enemy: Node2D
var actor_sprite: Sprite2D
var wreck_sprite: Sprite2D
var wreck_position := Vector2.ZERO
var failures: Array[String] = []
var cases: Array[Dictionary] = []


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	for index in range(args.size() - 1):
		if args[index] == "--output":
			output_dir = args[index + 1]
		elif args[index] == "--enemy":
			enemy_kind = args[index + 1]
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(640, 360)
	root.content_scale_size = Vector2i(640, 360)
	var absolute_output := ProjectSettings.globalize_path(output_dir)
	DirAccess.make_dir_recursive_absolute(absolute_output)
	if enemy_kind not in ["soldier", "mech"]:
		_fail("--enemy must be soldier or mech")
		_finish()
		return
	var scene_error := change_scene_to_file("res://scenes/level.tscn")
	if scene_error != OK:
		_fail("Unable to load the production level: %s" % error_string(scene_error))
		_finish()
		return
	await process_frame
	await physics_frame
	await process_frame

	var level := current_scene
	actor = level.get_node("Operative/Operative") as CharacterBody2D
	var enemy_path := "Enemies/SoloSoldier" if enemy_kind == "soldier" else "BossSlot/DefenseMech"
	enemy = level.get_node(enemy_path) as Node2D
	actor_sprite = actor.get_node("Sprite") as Sprite2D
	wreck_sprite = enemy.get_node("Sprite") as Sprite2D
	if enemy_kind == "mech":
		enemy.set("attack_enabled", true)
	for hit in int(enemy.get("health")):
		enemy.call("receive_hit")
	await physics_frame
	var expected_wreck_frame := 6 if enemy_kind == "soldier" else 5
	if int(enemy.get("health")) != 0 or wreck_sprite.frame != expected_wreck_frame:
		_fail("Fixture failed to produce the production %s wreck" % enemy_kind)
		_finish()
		return
	wreck_position = enemy.global_position
	actor.global_position = enemy.global_position
	actor_sprite.frame = 0
	actor_sprite.flip_h = false
	var live_soldier_sprite := level.get_node("Enemies/PairOneA/Sprite") as Sprite2D
	if actor_sprite.z_index != 0 or live_soldier_sprite.z_index != 0:
		_fail("The fixture changed the operative or live-soldier layer")
	if enemy_kind == "mech" and not level.get_node("HUD/OutcomePanel").visible:
		_fail("Defeating the defense mech must preserve the victory panel")
	await process_frame
	await RenderingServer.frame_post_draw
	if enemy_kind == "soldier":
		actor.set_physics_process(false)

	var standing := await _capture_layer_set("standing", true, absolute_output)
	standing["actor_state"] = "standing"
	_check_comparison(standing, "standing")
	cases.append(standing)
	if enemy_kind == "soldier":
		for action in ["move_right", "move_left"]:
			var movement := await _walk_through_wreck(action, absolute_output)
			_check_comparison(movement, action)
			cases.append(movement)
			if actor.health != 3 or int(enemy.get("health")) != 0 \
				or enemy.global_position != wreck_position \
					or enemy.collision_layer != 0 or enemy.get_node("Muzzle").visible:
				_fail("Walking through the retained wreck changed health, position, collision, or fire state")
	var report := {
		"engine": Engine.get_version_info().string,
		"native_size": [640, 360],
		"renderer": "OpenGL Compatibility",
		"physics_ticks_per_second": Engine.physics_ticks_per_second,
		"fixture": "Production level; %s defeated with receive_hit; actor standing or moving through wreck with production input actions" % enemy_kind,
		"enemy_health": int(enemy.get("health")),
		"wreck_frame": wreck_sprite.frame,
		"wreck_position": [wreck_position.x, wreck_position.y],
		"actor_health": actor.health,
		"enemy_sprite_z_index": wreck_sprite.z_index,
		"operative_sprite_z_index": actor_sprite.z_index,
		"ground_z_index": (level.get_node("Ground") as CanvasItem).z_index,
		"background_z_index": (level.get_node("HangarFar") as CanvasItem).z_index,
		"live_soldier_z_index": (level.get_node("Enemies/PairOneA/Sprite") as Sprite2D).z_index,
		"outcome_panel_visible": level.get_node("HUD/OutcomePanel").visible,
		"cases": cases,
		"failures": failures,
		"output_dir": output_dir,
	}
	var report_file := FileAccess.open(absolute_output.path_join("pixel-comparison.json"), FileAccess.WRITE)
	if report_file == null:
		_fail("Unable to write pixel comparison report")
	else:
		report["failures"] = failures
		report_file.store_string(JSON.stringify(report, "\t") + "\n")
		report_file.close()
	print("ISSUE_34_PIXEL_COMPARISON ", JSON.stringify(report))
	_finish()


func _walk_through_wreck(action: String, directory: String) -> Dictionary:
	var direction := 1 if action == "move_right" else -1
	Input.action_release("move_left")
	Input.action_release("move_right")
	actor.set_physics_process(true)
	actor.velocity = Vector2.ZERO
	actor.global_position = enemy.global_position - Vector2(64.0 * direction, 0.0)
	await _step()
	var start_x := actor.global_position.x
	await _save_motion_frame(action, 0)
	Input.action_press(action)
	var ticks := 0
	while ticks < 40 and direction * (actor.global_position.x - enemy.global_position.x) < 24.0:
		await _step()
		ticks += 1
		await _save_motion_frame(action, ticks)
	Input.action_release(action)
	var crossed_center := direction * (actor.global_position.x - enemy.global_position.x) >= 24.0
	if not crossed_center:
		_fail("Actioner did not walk through the wreck using %s" % action)
	actor.velocity = Vector2.ZERO
	actor.set_physics_process(false)
	actor_sprite.frame = 1
	var comparison := await _capture_layer_set(action, false, directory)
	comparison["actor_state"] = "running"
	comparison["input_action"] = action
	comparison["physics_ticks"] = ticks
	comparison["motion_frame_count"] = ticks + 1
	comparison["start_x"] = start_x
	comparison["end_x"] = actor.global_position.x
	comparison["crossed_center"] = crossed_center
	comparison["wreck_position_unchanged"] = enemy.global_position == wreck_position
	comparison["facing_left"] = actor_sprite.flip_h
	comparison["run_frame"] = actor_sprite.frame
	return comparison


func _save_motion_frame(action: String, frame_index: int) -> void:
	var directory := ProjectSettings.globalize_path(RAW_FRAME_ROOT.path_join(action))
	DirAccess.make_dir_recursive_absolute(directory)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image.get_size() != Vector2i(640, 360):
		_fail("Unexpected motion render size for %s" % action)
		return
	image.save_png(directory.path_join("frame-%03d.png" % frame_index))


func _capture_layer_set(case_name: String, save_components: bool, directory: String) -> Dictionary:
	actor_sprite.visible = false
	wreck_sprite.visible = false
	var background := await _capture(case_name + "-background", save_components, directory)
	wreck_sprite.visible = true
	var wreck_only := await _capture(case_name + "-wreck-only", save_components, directory)
	wreck_sprite.visible = false
	actor_sprite.visible = true
	var actor_only := await _capture(case_name + "-operative-only", save_components, directory)
	wreck_sprite.visible = true
	var combined := await _capture(case_name, true, directory)
	return _compare_layers(background, wreck_only, actor_only, combined)


func _capture(name: String, save_image: bool, directory: String) -> Image:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image.get_size() != Vector2i(640, 360):
		_fail("Unexpected render size for %s: %s" % [name, image.get_size()])
	if save_image:
		image.save_png(directory.path_join(name + ".png"))
	return image


func _compare_layers(background: Image, wreck: Image, actor_image: Image, combined: Image) -> Dictionary:
	var overlap_pixels := 0
	var operative_front_pixels := 0
	var wreck_front_pixels := 0
	var other_pixels := 0
	var operative_visible_pixels := 0
	var wreck_visible_pixels := 0
	for y in range(360):
		for x in range(640):
			var background_color := background.get_pixel(x, y)
			var wreck_color := wreck.get_pixel(x, y)
			var actor_color := actor_image.get_pixel(x, y)
			if wreck_color != background_color:
				wreck_visible_pixels += 1
			if actor_color != background_color:
				operative_visible_pixels += 1
			if actor_color == background_color or wreck_color == background_color \
					or actor_color == wreck_color:
				continue
			overlap_pixels += 1
			var combined_color := combined.get_pixel(x, y)
			if combined_color == actor_color:
				operative_front_pixels += 1
			elif combined_color == wreck_color:
				wreck_front_pixels += 1
			else:
				other_pixels += 1
	return {
		"overlap_pixels": overlap_pixels,
		"operative_front_pixels": operative_front_pixels,
		"wreck_front_pixels": wreck_front_pixels,
		"other_pixels": other_pixels,
		"operative_visible_pixels": operative_visible_pixels,
		"wreck_visible_pixels": wreck_visible_pixels,
		"operative_front_ratio": float(operative_front_pixels) / maxf(float(overlap_pixels), 1.0),
	}


func _check_comparison(comparison: Dictionary, case_name: String) -> void:
	if comparison["overlap_pixels"] < 8:
		_fail("%s had too few distinguishable overlap pixels: %d" % [case_name, comparison["overlap_pixels"]])
	elif comparison["operative_front_ratio"] < 0.95:
		_fail("Actioner was behind the wreck at %d/%d distinguishable pixels in %s" % [
			comparison["operative_front_pixels"], comparison["overlap_pixels"], case_name])
	if comparison["wreck_visible_pixels"] < 100:
		_fail("Retained wreck was not visible in %s" % case_name)
	if comparison.has("run_frame") and comparison["run_frame"] not in [1, 2]:
		_fail("Walking fixture did not render a production run frame in %s" % case_name)


func _step() -> void:
	await physics_frame
	await process_frame


func _fail(message: String) -> void:
	failures.append(message)
	push_error(message)


func _finish() -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	quit(0 if failures.is_empty() else 1)
