extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(640, 360)
	var encounter := (load("res://tests/defense_mech_encounter.tscn") as PackedScene).instantiate()
	root.add_child(encounter)
	var operative := encounter.get_node("Operative") as CharacterBody2D
	var mech := encounter.get_node("DefenseMech") as DefenseMech
	var fired: Array[Area2D] = []
	mech.projectile_fired.connect(func(projectile: Area2D) -> void:
		fired.append(projectile)
	)
	for frame in 90:
		await physics_frame
		if not fired.is_empty():
			break
	if fired.is_empty():
		_fail("完整入镜后没有发射可跳过的低弹")
		return
	var first_shot := fired[0]
	for frame in 20:
		await physics_frame
	Input.action_press("jump")
	await physics_frame
	Input.action_release("jump")
	var passed := false
	for frame in 65:
		await physics_frame
		if is_instance_valid(first_shot) and first_shot.global_position.x < operative.global_position.x - 20.0:
			passed = true
			break
	if not passed or operative.health != 3:
		_fail("普通跳跃应避过低弹且不造成必吃伤害")
		return
	print("PASS: 低弹可由普通跳跃规避")
	quit(0)


func _fail(message: String) -> void:
	Input.action_release("jump")
	push_error(message)
	quit(1)
