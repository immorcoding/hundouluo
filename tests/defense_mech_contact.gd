extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(640, 360)
	var encounter := (load("res://tests/defense_mech_encounter.tscn") as PackedScene).instantiate()
	root.add_child(encounter)
	var operative := encounter.get_node("Operative") as CharacterBody2D
	var mech := encounter.get_node("DefenseMech") as DefenseMech
	var camera := encounter.get_node("Camera2D") as Camera2D
	var changes: Array[int] = []
	operative.health_changed.connect(func(value: int) -> void: changes.append(value))
	camera.position.x = -500
	camera.force_update_scroll()
	for frame in 3:
		await physics_frame
	operative.global_position = mech.global_position + Vector2(-56, 0)
	for frame in 4:
		await physics_frame
	if operative.health != 3:
		_fail("未入镜的机甲不能通过接触伤害玩家")
		return
	operative.global_position.x = -160
	for frame in 4:
		await physics_frame
	camera.position.x = 0
	camera.force_update_scroll()
	for frame in 3:
		await physics_frame
	operative.global_position = mech.global_position + Vector2(-56, 0)
	for frame in 12:
		await physics_frame
	if operative.health != 2 or changes != [2]:
		_fail("机甲实体接触须通过行动员入口只造成一次伤害：%s" % [changes])
		return
	print("PASS: 未入镜安全、入镜机甲接触造成一次伤害")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
