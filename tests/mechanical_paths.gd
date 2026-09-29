extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1152, 648)
	var scene := load("res://tests/mechanical_encounter.tscn") as PackedScene
	if scene == null:
		_fail("机械兵可重复交战场景无法加载")
		return
	var encounter := scene.instantiate()
	root.add_child(encounter)
	var soldier := encounter.get_node("Enemies/MechanicalSoldier") as CharacterBody2D
	var operative := encounter.get_node("Operative/Operative") as CharacterBody2D
	var start_x := soldier.position.x
	for frame in 40:
		await physics_frame
	if absf(soldier.position.x - start_x) < 3.0 or absf(soldier.position.x - start_x) > 90.0:
		_fail("机械兵未缓慢巡逻")
		return
	Input.action_press("shoot")
	var defeated := false
	for frame in 220:
		await physics_frame
		if soldier.health == 0:
			defeated = true
			break
	Input.action_release("shoot")
	if not defeated:
		_fail("行动员弹丸未能击败机械兵")
		return
	encounter.queue_free()
	await physics_frame

	encounter = scene.instantiate()
	root.add_child(encounter)
	soldier = encounter.get_node("Enemies/MechanicalSoldier") as CharacterBody2D
	operative = encounter.get_node("Operative/Operative") as CharacterBody2D
	Input.action_press("move_right")
	var passed := false
	var jumped := false
	for frame in 180:
		if not jumped and operative.global_position.x > 20.0 and operative.is_on_floor():
			Input.action_press("jump")
			jumped = true
		await physics_frame
		Input.action_release("jump")
		if operative.global_position.x > soldier.global_position.x + 50.0:
			passed = true
			break
	Input.action_release("move_right")
	if not passed or soldier.health == 0:
		_fail("行动员未能绕过仍存活的机械兵")
		return
	print("PASS: 机械兵缓慢巡逻，行动员可击败或绕过")
	quit(0)


func _fail(message: String) -> void:
	Input.action_release("shoot")
	Input.action_release("move_right")
	push_error(message)
	quit(1)
