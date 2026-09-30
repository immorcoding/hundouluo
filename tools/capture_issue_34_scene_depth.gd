extends SceneTree
## Compare the unchanged live scene composition before and after static Z bands.

var _paced_frames := 0
var _last_process_start_usec := 0
var _last_sleep_usec := 0
var _output_dir := "res://docs/art/issue-34/scene-config-comparison/after"


func _initialize() -> void:
	_last_process_start_usec = Time.get_ticks_usec()
	process_frame.connect(_pace_to_real_60_hz)
	var args := OS.get_cmdline_user_args()
	for index in range(args.size() - 1):
		if args[index] == "--output":
			_output_dir = args[index + 1]
	call_deferred("_capture")


func _pace_to_real_60_hz() -> void:
	var frame_start_usec := Time.get_ticks_usec()
	var sleep_usec := 16667
	if _last_process_start_usec > 0:
		var previous_interval := frame_start_usec - _last_process_start_usec
		var previous_work := maxi(0, previous_interval - _last_sleep_usec)
		sleep_usec = maxi(0, 16667 - previous_work)
	var sleep_start_usec := Time.get_ticks_usec()
	if sleep_usec > 0:
		OS.delay_usec(sleep_usec)
	_last_sleep_usec = Time.get_ticks_usec() - sleep_start_usec
	_last_process_start_usec = frame_start_usec
	_paced_frames += 1


func _capture() -> void:
	root.size = Vector2i(640, 360)
	root.content_scale_size = Vector2i(640, 360)
	var error := change_scene_to_file("res://scenes/level.tscn")
	if error != OK:
		push_error("Unable to open production level: %s" % error_string(error))
		quit(1)
		return
	await process_frame
	await physics_frame
	await process_frame
	var level := current_scene
	if level == null:
		push_error("Production level did not load")
		quit(1)
		return
	var actor := level.get_node("Operative/Operative") as CharacterBody2D
	var actor_sprite := actor.get_node("Sprite") as Sprite2D
	var soldier := level.get_node("Enemies/SoloSoldier") as MechanicalSoldier
	var soldier_sprite := soldier.get_node("Sprite") as Sprite2D
	var camera := level.get_node("Camera2D") as Camera2D
	level.set_process(false)
	level.set_physics_process(false)
	actor.set_process(false)
	actor.set_physics_process(false)
	soldier.set_process(false)
	soldier.set_physics_process(false)
	soldier.attack_enabled = false
	(level.get_node("BossSlot/DefenseMech") as DefenseMech).set_physics_process(false)
	var center := soldier.global_position
	actor.global_position = center
	camera.global_position = Vector2(center.x, 180.0)
	camera.force_update_scroll()
	actor_sprite.frame = 0
	actor_sprite.flip_h = false
	soldier_sprite.frame = 1
	soldier_sprite.flip_h = false
	soldier.get_node("Muzzle").visible = false
	await process_frame
	var measurement_start_frame := _paced_frames
	var measurement_start_usec := Time.get_ticks_usec()
	_last_process_start_usec = measurement_start_usec
	_last_sleep_usec = 0
	for frame in 30:
		await process_frame
	var elapsed_ms := float(Time.get_ticks_usec() - measurement_start_usec) / 1000.0
	var frame_count := _paced_frames - measurement_start_frame
	await RenderingServer.frame_post_draw
	var output_path := ProjectSettings.globalize_path(_output_dir)
	DirAccess.make_dir_recursive_absolute(output_path)
	var alive := root.get_texture().get_image()
	if alive.get_size() != Vector2i(640, 360):
		push_error("Unexpected live scene viewport size: %s" % alive.get_size())
		quit(1)
		return
	alive.save_png(output_path.path_join("alive.png"))
	actor_sprite.visible = false
	var soldier_only := await _capture_frame()
	soldier_only.save_png(output_path.path_join("soldier-only.png"))
	actor_sprite.visible = true
	soldier_sprite.visible = false
	var operative_only := await _capture_frame()
	operative_only.save_png(output_path.path_join("operative-only.png"))
	actor_sprite.visible = false
	var background := await _capture_frame()
	background.save_png(output_path.path_join("background.png"))
	var report := {
		"native_size": [640, 360],
		"operative_sprite_z": actor_sprite.z_index,
		"live_soldier_sprite_z": soldier_sprite.z_index,
		"background_z": (level.get_node("HangarFar") as CanvasItem).z_index,
		"ground_z": (level.get_node("Ground") as CanvasItem).z_index,
		"paced_process_frames": frame_count,
		"elapsed_ms": elapsed_ms,
		"average_ms_per_process_frame": elapsed_ms / maxf(float(frame_count), 1.0),
		"output_dir": _output_dir
	}
	var file := FileAccess.open(output_path.path_join("scene-state.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	print("PASS: captured live operative/soldier and background at ", _output_dir,
			" pacing_ms_per_frame=", report["average_ms_per_process_frame"])
	quit(0)


func _capture_frame() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
