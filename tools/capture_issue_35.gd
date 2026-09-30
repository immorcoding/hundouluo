extends SceneTree
## Real level/Input/render loop. Follow/fixed fixtures teleport initially.
## Hurt uses public receive_hit. Gameplay tuning and resources stay unchanged.

const BARRELS := [Vector2(28, -26), Vector2(31, -24), Vector2(31, -24),
	Vector2(23, -25), Vector2(21, -25), Vector2(26, -28)]
var out := "res://docs/bugs/issue-35/after"
var ticks := 180
var mode := "full"
var probe := "none"
var scenario := "spawn"
var regression := false
var artifacts := true
var shots: Array[Dictionary] = []
var flying: Array[Dictionary] = []
var failures: Array[String] = []
var trace: Array[Dictionary] = []
var flash_samples := 0
var flight_samples := 0


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
		elif arg.begins_with("--ticks="):
			ticks = arg.trim_prefix("--ticks=").to_int()
		elif arg.begins_with("--mode="):
			mode = arg.trim_prefix("--mode=")
		elif arg.begins_with("--probe="):
			probe = arg.trim_prefix("--probe=")
		elif arg.begins_with("--scenario="):
			scenario = arg.trim_prefix("--scenario=")
		elif arg.begins_with("--physics-hz="):
			Engine.physics_ticks_per_second = arg.trim_prefix("--physics-hz=").to_int()
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(640, 360)
	root.content_scale_size = Vector2i(640, 360)
	if artifacts:
		DirAccess.make_dir_recursive_absolute(out + "/frames")
	if regression:
		for fixture in ["spawn", "follow", "fixed"]:
			scenario = fixture
			await _case()
	else:
		await _case()
	if artifacts:
		var file := FileAccess.open(out + "/trace.json", FileAccess.WRITE)
		file.store_string(JSON.stringify({"engine": Engine.get_version_info().string,
			"scenario": scenario, "mode": mode, "probe": probe,
			"physics_hz": Engine.physics_ticks_per_second, "native_size": [640, 360],
			"disclosure": "Spawn is normal level; follow teleports initially to (470,252); fixed to (3462,252), then normal input closes gate. Tick 125 calls public receive_hit for hurt pose; movement/firing use Input. No gameplay tuning.",
			"trace": trace, "shots": shots, "failures": failures,
			"flash_samples": flash_samples, "flight_samples": flight_samples}, "\t") + "\n")
		file.close()
	print("ISSUE35 shots=", shots.size(), " flashes=", flash_samples,
		" flight_samples=", flight_samples, " failures=", failures.size())
	for failure in failures.slice(0, 12):
		print("FAIL: ", failure)
	if failures.is_empty():
		print("PASS: 跑射/变向/跳跃落地/受击枪口对齐，弹丸独立飞行")
	quit(0 if failures.is_empty() else 1)


func _case() -> void:
	_release()
	change_scene_to_file("res://scenes/level.tscn")
	await process_frame
	await process_frame
	var actor := current_scene.get_node("Operative/Operative") as CharacterBody2D
	var sprite := actor.get_node("Sprite") as Sprite2D
	var poses := {}
	var first_shot := shots.size()
	var first_flash_sample := flash_samples
	var camera_positions: Array[float] = []
	flying.clear()
	if scenario == "follow":
		actor.position = Vector2(470, 252)
	elif scenario == "fixed":
		actor.position = Vector2(3462, 252)
		Input.action_press("move_right")
		await _step()
		Input.action_release("move_right")
		for step in 40:
			await _step()
		_check(not current_scene.get_node("CombatEntry/Barrier/CollisionShape2D").disabled,
			"fixed fixture must close real gate")
	actor.projectile_fired.connect(func(projectile: Area2D) -> void:
		var origin := projectile.global_position
		var barrel := _barrel(actor, sprite)
		var shot := {"frame": Engine.get_physics_frames(), "origin": _xy(origin),
			"barrel": _xy(barrel), "birth_error": origin.distance_to(barrel),
			"direction": projectile.direction, "pose": sprite.frame}
		shots.append(shot)
		_check(origin.distance_to(barrel) <= 1.0, "birth misses atlas barrel")
		flying.append({"node": projectile, "shot": shot})
		if probe == "freeze-projectile":
			projectile.set_physics_process(false)
	)
	if mode != "no-shot":
		Input.action_press("shoot")
	if mode in ["minimal", "no-shot"]:
		Input.action_press("move_right")
	for tick in ticks:
		_inputs(tick, actor)
		await _step()
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
		var barrel := _barrel(actor, sprite)
		var record := {"scenario": scenario, "tick": tick,
			"physics_frame": Engine.get_physics_frames(), "actor": _xy(actor.position),
			"pose": sprite.frame, "direction": -1 if sprite.flip_h else 1,
			"on_floor": actor.is_on_floor(), "health": actor.health,
			"barrel": _xy(barrel), "screen_barrel": _xy(actor.get_canvas_transform() * barrel),
			"camera_x": current_scene.get_node("Camera2D").position.x}
		poses[str(sprite.frame) + ":" + str(record.direction)] = true
		camera_positions.append(record.camera_x)
		var flashes: Array = []
		for child in _flashes():
			var error := child.global_position.distance_to(barrel)
			flashes.append({"position": _xy(child.global_position),
				"screen": _xy(child.get_global_transform_with_canvas().origin),
				"frame": child.frame, "mirrored": child.global_transform.x.x < 0 or child.flip_h,
				"barrel_error": error})
			flash_samples += 1
			_check(error <= 1.0, "%s tick %d flash detached %.3f px" % [scenario, tick, error])
			_check((child.global_transform.x.x < 0 or child.flip_h) == sprite.flip_h,
				"flash points away from visible gun")
		record["flashes"] = flashes
		var projectiles: Array = []
		for item in flying:
			if not is_instance_valid(item.node):
				continue
			var projectile: Area2D = item.node
			if projectile.is_queued_for_deletion():
				continue
			var shot: Dictionary = item.shot
			var elapsed := Engine.get_physics_frames() - int(shot.frame)
			var expected := Vector2(shot.origin[0], shot.origin[1]) + Vector2(
				shot.direction * elapsed * 520.0 / Engine.physics_ticks_per_second, 0)
			var error := projectile.global_position.distance_to(expected)
			projectiles.append({"emission": shot, "elapsed_ticks": elapsed,
				"position": _xy(projectile.global_position), "flight_error": error})
			flight_samples += 1
			if probe != "freeze-projectile":
				_check(error < 0.05, "independent projectile flight changed: %.3f" % error)
		record["projectiles"] = projectiles
		trace.append(record)
		if artifacts and DisplayServer.get_name() != "headless":
			var image := root.get_texture().get_image()
			_check(image.get_size() == Vector2i(640, 360), "non-native viewport")
			_check(image.save_png(out + "/frames/%03d.png" % tick) == OK, "frame save failed")
		if probe == "follow-body":
			for child in _flashes():
				if child.get_parent() != actor:
					child.reparent(actor)
	if mode == "full" and ticks >= 160:
		_check(shots.size() > first_shot + 5, "continuous Input must produce repeated shots")
		_check(flash_samples > first_flash_sample, "muzzle feedback must actually be visible")
		for key in ["0:1", "1:1", "3:-1", "0:-1", "5:-1"]:
			if key == "1:1":
				_check(poses.has(key) or poses.has("2:1"), "missing running pose")
			else:
				_check(poses.has(key), "missing pose " + key)
		_check(actor.is_on_floor(), "jump must land on real terrain")
		if scenario == "follow":
			_check(camera_positions.max() > camera_positions.min(), "follow camera did not move")
		elif scenario == "fixed":
			_check(camera_positions.min() == 3580.0 and camera_positions.max() == 3580.0,
				"closed encounter camera did not stay fixed")
	_release()
	current_scene.queue_free()
	await process_frame
	await process_frame
	OS.delay_msec(150)


func _inputs(tick: int, actor: CharacterBody2D) -> void:
	if mode == "minimal" and tick == 1:
		Input.action_release("shoot")
	if mode != "full":
		return
	if tick == 5:
		Input.action_press("move_right")
	elif tick == 45:
		Input.action_release("move_right")
		Input.action_press("move_left")
	elif tick == 65:
		Input.action_press("jump")
	elif tick == 66:
		Input.action_release("jump")
	elif tick == 95:
		Input.action_release("move_left")
	elif tick == 125:
		actor.receive_hit()
	elif tick == 130:
		Input.action_press("move_right")
	elif tick == 145:
		Input.action_release("move_right")
		Input.action_press("move_left")
	elif tick == 155:
		Input.action_release("move_left")


func _step() -> void:
	await physics_frame
	await process_frame
	# process_frame fires before _process; timers fire after node callbacks.
	await create_timer(0.0).timeout


func _barrel(actor: CharacterBody2D, sprite: Sprite2D) -> Vector2:
	var point: Vector2 = BARRELS[sprite.frame]
	return actor.to_global(Vector2(-point.x if sprite.flip_h else point.x, point.y))


func _flashes() -> Array[Sprite2D]:
	var result: Array[Sprite2D] = []
	for child in current_scene.find_children("*", "Sprite2D", true, false):
		if child.get_script() == load("res://scripts/combat_flash.gd") and child.frame in range(12, 16) \
				and child.is_visible_in_tree():
			result.append(child)
	return result


func _release() -> void:
	for action in ["shoot", "move_right", "move_left", "jump"]:
		Input.action_release(action)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _xy(value: Vector2) -> Array:
	return [value.x, value.y]
