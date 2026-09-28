extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1152, 648)
	var encounter := (load("res://tests/mechanical_encounter.tscn") as PackedScene).instantiate()
	var soldier := encounter.get_node("Enemies/MechanicalSoldier") as CharacterBody2D
	var operative := encounter.get_node("Operative/Operative") as CharacterBody2D
	operative.global_position = Vector2(140, 0)
	root.add_child(encounter)
	var changes: Array[int] = []
	operative.health_changed.connect(func(value: int) -> void: changes.append(value))
	for frame in 15:
		await physics_frame
	if operative.health != 2 or changes != [2]:
		_fail("一次身体接触应只造成一次有效受击，生命：%s" % [changes])
		return
	soldier.global_position.x = 800
	var projectile_scene := load("res://scenes/enemy_projectile.tscn") as PackedScene
	var projectile := projectile_scene.instantiate() as Area2D
	projectile.global_position = operative.global_position + Vector2(0, -18)
	encounter.get_node("Projectiles").add_child(projectile)
	for frame in 4:
		await physics_frame
	if operative.health != 2:
		_fail("身体接触后的短暂无敌应挡住紧接而来的敌弹")
		return
	for frame in 25:
		await physics_frame
	if operative.health != 2:
		_fail("持续接触不能在短暂无敌后自动重复扣血")
		return
	for frame in 20:
		await physics_frame
	projectile = projectile_scene.instantiate() as Area2D
	projectile.global_position = operative.global_position + Vector2(0, -18)
	encounter.get_node("Projectiles").add_child(projectile)
	for frame in 4:
		await physics_frame
	if operative.health != 1 or changes != [2, 1]:
		_fail("无敌结束后的新敌弹应造成一次新的有效受击：%s" % [changes])
		return
	print("PASS: 接触与敌弹各造成单次受击，行动员短暂无敌生效")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
