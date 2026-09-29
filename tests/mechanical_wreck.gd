extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := load("res://tests/mechanical_encounter.tscn") as PackedScene
	var encounter := scene.instantiate()
	root.add_child(encounter)
	var soldier := encounter.get_node("Enemies/MechanicalSoldier") as MechanicalSoldier
	var actor := encounter.get_node("Operative/Operative") as CharacterBody2D
	var shots := [0]
	soldier.projectile_fired.connect(func(_projectile: Area2D) -> void: shots[0] += 1)
	for hit in soldier.health:
		soldier.receive_hit()
	if not is_instance_valid(soldier) or soldier.health != 0:
		_fail("机械兵归零后必须保留残骸")
		return
	var wreck_position := soldier.position
	var actor_health: int = actor.health
	actor.global_position = soldier.global_position
	for frame in 130:
		await physics_frame
	if not is_instance_valid(soldier) or soldier.position != wreck_position \
			or (soldier.get_node("Sprite") as Sprite2D).frame != 6 \
			or soldier.get_node("Muzzle").visible or shots[0] != 0 \
			or actor.health != actor_health or soldier.collision_layer != 0:
		_fail("倒地残骸不能巡逻、攻击、接触伤害或阻挡弹丸")
		return
	encounter.queue_free()
	await physics_frame
	encounter = scene.instantiate()
	root.add_child(encounter)
	soldier = encounter.get_node("Enemies/MechanicalSoldier") as MechanicalSoldier
	if soldier.health != soldier.max_health or soldier.get_node("Sprite").frame == 6 \
			or soldier.collision_layer != 2:
		_fail("重载场景须恢复可交战机械兵")
		return
	print("PASS: 机械兵倒地残骸惰性且场景重载复位")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
