extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	change_scene_to_file("res://scenes/level.tscn")
	await process_frame
	await process_frame
	var level := current_scene
	var actor := level.get_node("Operative/Operative") as CharacterBody2D
	var mech := level.get_node("BossSlot/DefenseMech") as DefenseMech
	var mech_max_health := mech.max_health
	var barrier := level.get_node_or_null("CombatEntry/Barrier/CollisionShape2D") as CollisionShape2D
	var artwork := level.get_node_or_null("CombatEntry/Artwork") as Sprite2D
	if barrier == null or artwork == null or not barrier.disabled or artwork.frame != 0:
		_fail("终点战斗区需要初始可见入口、尚未闭合的闸门")
		return
	actor.position = Vector2(3400, 252)
	for tick in 5:
		await physics_frame
	if mech.attack_enabled or not barrier.disabled:
		_fail("机甲未完整可见时不得关入口或发起攻击")
		return
	actor.position = Vector2(3462, 252)
	for tick in 5:
		await physics_frame
	if mech.attack_enabled or not barrier.disabled:
		_fail("入口触发边界左侧不可留出可射击的机甲战空间")
		return
	# This is the first playable band where the full mech can be seen.
	# The old x=3510 trigger left a shoot-and-retreat loophole here.
	actor.position = Vector2(3464, 252)
	actor.velocity = Vector2.ZERO
	var charges := [0]
	var shots := [0]
	mech.charge_started.connect(func() -> void: charges[0] += 1)
	mech.projectile_fired.connect(func(_projectile: Area2D) -> void: shots[0] += 1)
	for tick in 4:
		await physics_frame
	if not mech.attack_enabled or charges[0] == 0 or not barrier.disabled:
		_fail("双方入镜先显示蓄力预告，入口不得立刻关闭")
		return
	var closure_frame := -1
	for tick in 45:
		await physics_frame
		if not barrier.disabled:
			closure_frame = tick
			break
	if closure_frame < 6 or artwork.frame != 7 or shots[0] != 0:
		_fail("可见蓄力预告后、首发弹丸前才闭合左入口")
		return
	Input.action_press("move_left")
	for tick in 38:
		await physics_frame
	Input.action_release("move_left")
	if absf(actor.position.x - 3415.075) > 0.2 or not mech.attack_enabled or mech.health != mech.max_health:
		_fail("入口须阻止左退，保持机甲完整入镜且不可从屏外受击")
		return
	actor.invulnerability_duration = 0.0
	for hit in actor.health:
		actor.receive_hit()
	await _retry()
	level = current_scene
	if level == null or not level.get_node("CombatEntry/Barrier/CollisionShape2D").disabled \
			or level.get_node("CombatEntry/Artwork").frame != 0 \
			or level.get_node("BossSlot/DefenseMech").health != mech_max_health:
		_fail("死亡重试须重新打开入口并复位机甲")
		return
	print("PASS: 双方入镜预告后入口闭合，退避边界与重试复位")
	current_scene.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	call_deferred("_finish")


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


func _fail(message: String) -> void:
	Input.action_release("move_left")
	push_error(message)
	quit(1)


func _finish() -> void:
	quit(0)
