extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _steps(count: int) -> void:
	for tick in count:
		await physics_frame
		await process_frame


func _new_level() -> Node:
	change_scene_to_file("res://scenes/level.tscn")
	await process_frame
	await process_frame
	return current_scene


func _run() -> void:
	root.size = Vector2i(640, 360)
	var level := await _new_level()
	var actor := level.get_node("Operative/Operative") as CharacterBody2D
	var artwork := level.get_node("CombatEntry/Artwork") as Sprite2D
	var barrier := level.get_node("CombatEntry/Barrier/CollisionShape2D") as CollisionShape2D
	var mech := level.get_node("BossSlot/DefenseMech") as DefenseMech
	actor.position = Vector2(3464, 252)
	var warning_tick := -1
	var closure_tick := -1
	var frames: Array[int] = []
	for tick in 40:
		await _steps(1)
		if artwork.frame in range(1, 7):
			if warning_tick < 0:
				warning_tick = tick
			if not barrier.disabled or not mech.get_node("Muzzle").visible:
				_fail("静音警告全程须可见机甲蓄力，屏障尚未阻挡")
				return
			if not artwork.frame in frames:
				frames.append(artwork.frame)
		if not barrier.disabled:
			closure_tick = tick
			break
	if frames != [1, 2, 3, 4, 5, 6] or closure_tick - warning_tick != 14 or artwork.frame != 7:
		_fail("原0.22秒警告须逐帧显示六张获批下降帧后闭合（60Hz量化14步）")
		return
	# Back away at early, middle and final warning poses with ordinary input.
	for pose in [1, 3, 6]:
		level = await _new_level()
		actor = level.get_node("Operative/Operative") as CharacterBody2D
		artwork = level.get_node("CombatEntry/Artwork") as Sprite2D
		barrier = level.get_node("CombatEntry/Barrier/CollisionShape2D") as CollisionShape2D
		var camera := level.get_node("Camera2D") as Camera2D
		actor.position = Vector2(3464, 252)
		var reached := false
		for tick in 25:
			await _steps(1)
			if artwork.frame == pose:
				reached = true
				break
		if not reached:
			_fail("未到达需覆盖的退避警告姿态")
			return
		Input.action_press("move_left")
		await _steps(8)
		Input.action_release("move_left")
		await _steps(20)
		camera.force_update_scroll()
		if not barrier.disabled or artwork.frame != 0 or camera.get_screen_center_position().x >= 3570:
			_fail("警告中真实左退须取消闭门并保留水平跟随")
			return
	print("PASS: 六帧下降/14步警告；早、中、末期左退取消且不锁镜头")
	current_scene.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	call_deferred("quit", 0)


func _fail(message: String) -> void:
	Input.action_release("move_left")
	push_error(message)
	quit(1)
