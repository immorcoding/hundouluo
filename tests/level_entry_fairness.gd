extends SceneTree
## Real projectile collisions at the closed entrance, with default tuning.

var shots := 0
var first_muzzle := Vector2.ZERO


func _initialize() -> void:
	call_deferred("_run")


func _record_shot(projectile: Area2D) -> void:
	if shots == 0:
		first_muzzle = projectile.global_position
	shots += 1


func _steps(count: int) -> void:
	for tick in count:
		await physics_frame
		await process_frame


func _run() -> void:
	root.size = Vector2i(640, 360)
	change_scene_to_file("res://scenes/level.tscn")
	await process_frame
	await process_frame
	var level := current_scene
	var actor := level.get_node("Operative/Operative") as CharacterBody2D
	var mech := level.get_node("BossSlot/DefenseMech") as DefenseMech
	var barrier := level.get_node("CombatEntry/Barrier/CollisionShape2D") as CollisionShape2D
	mech.projectile_fired.connect(_record_shot)
	actor.position = Vector2(3462, 252)
	await _steps(30)
	actor.position.x = 3464
	await _steps(30)
	Input.action_press("move_left")
	await _steps(42)
	Input.action_release("move_left")
	await _steps(180)
	var rest_x := actor.position.x
	var rest_health: int = actor.health
	var rest_shots := shots
	if barrier.disabled or absf(rest_x - 3415.075) > 0.2 or rest_health != 2 \
			or rest_shots != 3 or first_muzzle != Vector2(3768, 234):
		_fail("贴门必须受到原机甲齐射的真实伤害，不能成为零敌弹安全点")
		return
	# Reach the right-facing firing pose using one input frame, then retreat.
	Input.action_press("move_right")
	Input.action_press("shoot")
	await _steps(1)
	Input.action_release("move_right")
	Input.action_release("shoot")
	Input.action_press("move_left")
	await _steps(1)
	Input.action_release("move_left")
	await _steps(120)
	if mech.health != 41 or actor.health != 1 or shots != 6 or absf(actor.position.x - rest_x) > 0.2:
		_fail("普通输入探身射击再左退必须敌我都能有效命中")
		return
	print("FAIRNESS rest_x=", rest_x, " range_margin=", 420.0 - (3830.0 - rest_x),
		" enemy_muzzle=", first_muzzle, " rest_health=", rest_health,
		" final_health=", actor.health, " mech_health=", mech.health, " shots=", shots)
	# Jump while left-facing against the closed barrier; landing remains inside.
	Input.action_press("move_left")
	Input.action_press("jump")
	await _steps(1)
	Input.action_release("jump")
	var apex := actor.position.y
	for tick in 52:
		await _steps(1)
		apex = minf(apex, actor.position.y)
		if actor.position.x < 3415.0 or not mech.attack_enabled:
			_fail("贴门左向跳跃不可越过屏障或将机甲移出实际视口")
			return
	Input.action_release("move_left")
	if apex > 190 or not actor.is_on_floor() or not actor.get_node("Sprite").flip_h:
		_fail("未通过真实输入覆盖左向跳跃及落地")
		return
	print("PASS: x3396贴门交战、单帧探身射击与左向跳跃均可反击且不可左退")
	current_scene.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	call_deferred("quit", 0)


func _fail(message: String) -> void:
	for action in ["move_left", "move_right", "shoot", "jump"]:
		Input.action_release(action)
	push_error(message)
	quit(1)
