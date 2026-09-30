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
	if not await _verify_production_depth_and_retry():
		return
	print("PASS: 机械兵残骸惰性、前后绘制层级和重试复位")
	quit(0)


func _verify_production_depth_and_retry() -> bool:
	change_scene_to_file("res://scenes/level.tscn")
	await process_frame
	await process_frame
	var level := current_scene
	if level == null:
		_fail("正式关卡未能加载")
		return false
	var actor := level.get_node("Operative/Operative") as CharacterBody2D
	var soldier := level.get_node("Enemies/SoloSoldier") as MechanicalSoldier
	for hit in soldier.health:
		soldier.receive_hit()
	await physics_frame
	if not _has_wreck_depth(level, soldier.get_node("Sprite") as Sprite2D) \
			or (level.get_node("Enemies/PairOneA/Sprite") as Sprite2D).z_index != 0:
		_fail("机械兵死亡应只下沉残骸，保留活敌的绘制层级")
		return false
	for hit in 3:
		actor.receive_hit()
		for frame in 43:
			await physics_frame
	if actor.health != 0 or not level.get_node("HUD/OutcomePanel").visible:
		_fail("正式关卡死亡 fixture 未触发 R 重试入口")
		return false
	await _retry()
	level = current_scene
	if level == null or not _has_default_world_depth(level) \
			or level.get_node("Operative/Operative").health != 3 \
			or level.get_node("Enemies/SoloSoldier").health != 3:
		_fail("机械兵残骸层级须由 R 重试重置")
		return false
	var mech := level.get_node("BossSlot/DefenseMech") as DefenseMech
	mech.attack_enabled = true
	for hit in mech.health:
		mech.receive_hit()
	await physics_frame
	if mech.health != 0 or not _has_wreck_depth(level, mech.get_node("Sprite") as Sprite2D) \
			or (level.get_node("Enemies/SoloSoldier/Sprite") as Sprite2D).z_index != 0:
		_fail("防御机甲死亡应只下沉残骸，保留活机械兵的绘制层级")
		return false
	await _retry()
	level = current_scene
	if level == null or not _has_default_world_depth(level) \
			or level.get_node("BossSlot/DefenseMech").health != 42:
		_fail("防御机甲残骸层级须由 R 重试重置")
		return false
	return true


func _has_wreck_depth(level: Node, wreck_sprite: Sprite2D) -> bool:
	for background_name in ["HangarFar", "HangarMid", "HangarFar2", "HangarMid2", "HangarFar3", "HangarMid3"]:
		if (level.get_node(background_name) as CanvasItem).z_index != -3:
			return false
	return (level.get_node("Ground") as CanvasItem).z_index == -2 \
			and wreck_sprite.z_index == -1


func _has_default_world_depth(level: Node) -> bool:
	for background_name in ["HangarFar", "HangarMid", "HangarFar2", "HangarMid2", "HangarFar3", "HangarMid3"]:
		if (level.get_node(background_name) as CanvasItem).z_index != 0:
			return false
	return (level.get_node("Ground") as CanvasItem).z_index == 0


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
	push_error(message)
	quit(1)
