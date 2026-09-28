extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1152, 648)
	var encounter := (load("res://tests/mechanical_encounter.tscn") as PackedScene).instantiate()
	root.add_child(encounter)
	var soldier := encounter.get_node("Enemies/MechanicalSoldier") as CharacterBody2D
	var operative := encounter.get_node("Operative/Operative") as CharacterBody2D
	var camera := encounter.get_node("Camera2D") as Camera2D
	var projectiles := encounter.get_node("Projectiles")
	operative.global_position = Vector2(0, 0)
	camera.global_position = Vector2(0, -80)
	var muzzle := soldier.get_node_or_null("Muzzle") as CanvasItem
	if muzzle == null:
		_fail("机械兵缺少可见枪口预告")
		return
	var warned := false
	for frame in 100:
		await physics_frame
		if muzzle.visible:
			warned = true
			if projectiles.get_child_count() != 0:
				_fail("枪口预告尚未结束就已出现敌弹")
				return
			break
	if not warned:
		_fail("进入可见范围后没有枪口预告")
		return
	# 离开镜头的预告必须取消；再次入镜才能从头开始预告。
	camera.global_position = Vector2(1400, -80)
	camera.force_update_scroll()
	for frame in 35:
		await physics_frame
		if (frame > 1 and muzzle.visible) or projectiles.get_child_count() != 0:
			_fail("预告中移出镜头后仍发射敌弹")
			return
	camera.global_position = Vector2(0, -80)
	camera.force_update_scroll()
	var warning_frames := 0
	var warned_again := false
	while projectiles.get_child_count() == 0 and warning_frames < 90:
		await physics_frame
		warning_frames += 1
		warned_again = warned_again or muzzle.visible
	if projectiles.get_child_count() == 0 or warning_frames < 8 or not warned_again:
		_fail("敌弹未在足够可察觉的预告后发射")
		return
	var bullet := projectiles.get_child(0) as Area2D
	if bullet == null or bullet.global_position.x >= soldier.global_position.x:
		_fail("敌弹未水平朝行动员发射")
		return
	encounter.queue_free()
	await physics_frame

	encounter = (load("res://tests/mechanical_encounter.tscn") as PackedScene).instantiate()
	soldier = encounter.get_node("Enemies/MechanicalSoldier") as CharacterBody2D
	operative = encounter.get_node("Operative/Operative") as CharacterBody2D
	camera = encounter.get_node("Camera2D") as Camera2D
	projectiles = encounter.get_node("Projectiles")
	operative.global_position = Vector2(0, 0)
	camera.global_position = Vector2(1400, -80)
	root.add_child(encounter)
	muzzle = soldier.get_node_or_null("Muzzle") as CanvasItem
	for frame in 160:
		await physics_frame
		if muzzle.visible or projectiles.get_child_count() != 0 or operative.health != 3:
			_fail("机械兵离开镜头时不能预告、发弹或伤害行动员")
			return
	print("PASS: 入镜预告早于水平敌弹，镜头外不会袭击")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
