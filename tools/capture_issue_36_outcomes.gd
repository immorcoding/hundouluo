extends "res://tools/capture_issue_36.gd"
## Initial teleport/public HP setup; winning collision, turning and R use Input.


func _initialize() -> void:
	Engine.physics_ticks_per_second = 120
	super._initialize()


func _run() -> void:
	root.size = Vector2i(640, 360)
	root.content_scale_size = Vector2i(640, 360)
	DirAccess.make_dir_recursive_absolute(out + "/frames")
	change_scene_to_file("res://scenes/level.tscn")
	await process_frame
	await process_frame
	var actor := current_scene.get_node("Operative/Operative") as CharacterBody2D
	var mech := current_scene.get_node("BossSlot/DefenseMech") as DefenseMech
	actor.position = Vector2(3700, 252)
	for tick in 4:
		await _step()
	for hit in mech.max_health - 1:
		mech.receive_hit()
	var fired: Array[Area2D] = []
	actor.projectile_fired.connect(func(projectile: Area2D) -> void:
		fired.append(projectile)
		emitted.append(projectile)
	)
	Input.action_press("shoot")
	await _step()
	Input.action_release("shoot")
	var body := mech.get_node("Body") as CollisionShape2D
	var edge := mech.global_position.x + body.position.x - (body.shape as RectangleShape2D).size.x / 2.0
	var turned := false
	for tick in 60:
		if not fired.is_empty() and is_instance_valid(fired[0]) and fired[0].position.x >= edge - 12:
			Input.action_press("move_left")
			turned = true
		await _step()
		if mech.health == 0:
			break
	Input.action_release("move_left")
	var trace: Array[Dictionary] = []
	if not turned or mech.health != 0 or not actor.get_node("Sprite").flip_h:
		failures.append("fixture did not turn before winning real collision")
	trace.append(await _capture_pair(actor, 0))
	if trace[-1].flash_count == 0:
		failures.append("victory fixture lacks frozen visible muzzle")
	for tick in 8:
		await _step()
	trace.append(await _capture_pair(actor, 1))
	await _retry()
	actor = current_scene.get_node("Operative/Operative") as CharacterBody2D
	actor.projectile_fired.connect(func(projectile: Area2D) -> void: emitted.append(projectile))
	if actor.health != 3 or actor.position.x != 140:
		failures.append("victory R did not rebuild normal starting actor")
	Input.action_press("shoot")
	await _step()
	Input.action_release("shoot")
	trace.append(await _capture_pair(actor, 2))
	# Public damage fixture makes the fatal event deterministic.
	actor.invulnerability_duration = 0.0
	for hit in 3:
		actor.receive_hit()
	await _step()
	trace.append(await _capture_pair(actor, 3))
	if actor.health != 0 or trace[-1].flash_count != 0:
		failures.append("death left a visible muzzle effect")
	await _retry()
	actor = current_scene.get_node("Operative/Operative") as CharacterBody2D
	actor.projectile_fired.connect(func(projectile: Area2D) -> void: emitted.append(projectile))
	if actor.health != 3 or actor.position.x != 140:
		failures.append("death R did not rebuild normal starting actor")
	Input.action_press("shoot")
	await _step()
	Input.action_release("shoot")
	trace.append(await _capture_pair(actor, 4))
	var file := FileAccess.open(out + "/trace.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(trace, "\t") + "\n")
	current_scene.queue_free()
	await process_frame
	await process_frame
	OS.delay_msec(150)
	for failure in failures:
		print("FAIL: ", failure)
	if failures.is_empty():
		print("PASS: visible muzzle attachment and stable gun pixels; victory/death/R")
	quit(0 if failures.is_empty() else 1)


func _retry() -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_R
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	await process_frame
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame
