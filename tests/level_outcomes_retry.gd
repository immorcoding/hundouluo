extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	change_scene_to_file("res://scenes/level.tscn")
	await process_frame
	await process_frame
	var level := current_scene
	var actor := level.get_node("Operative/Operative") as CharacterBody2D
	var hud := level.get_node("HUD")
	if not hud.get_node("LifeLabel").text.contains("3") or hud.get_node("MechProgress").visible:
		_fail("开场 HUD 生命或机甲进度不正确")
		return
	for soldier in level.get_node("Enemies").get_children():
		for hit in soldier.health:
			soldier.receive_hit()
	await process_frame
	if hud.get_node("OutcomePanel").visible or level.get_node("ExitDoor/DoorBlocker/CollisionShape2D").disabled:
		_fail("普通敌人全灭不应通关或开门")
		return
	actor.position = Vector2(3700, 252)
	actor.invulnerability_duration = 0.0
	actor.receive_hit()
	if not hud.get_node("LifeLabel").text.contains("2"):
		_fail("受击信号未更新 HUD")
		return
	actor.receive_hit()
	actor.receive_hit()
	if not hud.get_node("OutcomePanel").visible or not hud.get_node("OutcomePanel/ReasonLabel").text.contains("生命"):
		_fail("生命归零未显示对应失败原因")
		return
	await _retry()
	level = current_scene
	if level == null or level.get_node("Operative/Operative").health != 3 or level.get_node("Enemies").get_child_count() != 5:
		_fail("终点生命死亡重试未恢复生命与敌人")
		return
	if level.get_node("Operative/Operative").position.x != 140.0:
		_fail("终点死亡未从起点重试")
		return
	actor = level.get_node("Operative/Operative") as CharacterBody2D
	var events: Array[String] = []
	var stray_projectile := (load("res://scenes/enemy_projectile.tscn") as PackedScene).instantiate() as Area2D
	stray_projectile.position = Vector2(200, 100)
	level.get_node("Projectiles").add_child(stray_projectile)
	level.operative_fell.connect(func() -> void: events.append("fell"))
	actor.health_changed.connect(func(value: int) -> void:
		if value == 0: events.append("health"))
	actor.died.connect(func() -> void: events.append("died"))
	actor.position = Vector2(1392, 425)
	for tick in 3:
		await physics_frame
	if events != ["fell", "health", "died"] or not level.get_node("HUD/OutcomePanel/ReasonLabel").text.contains("跌落"):
		_fail("跌落死亡信号顺序或死因不正确")
		return
	await _retry()
	level = current_scene
	actor = level.get_node("Operative/Operative") as CharacterBody2D
	if actor.position.x != 140.0 or actor.health != 3 or level.get_node("Projectiles").get_child_count() != 0:
		_fail("跌落后重试未从起点清空状态")
		return
	var mech := level.get_node("BossSlot/DefenseMech") as DefenseMech
	var max_mech_health := mech.max_health
	actor.position = Vector2(3700, 252)
	for tick in 4:
		await physics_frame
	if not level.get_node("HUD/MechProgress").visible:
		_fail("进入终点后未显示机甲生命")
		return
	mech.receive_hit()
	if level.get_node("HUD/MechProgress").value != mech.max_health - 1:
		_fail("机甲血量信号未更新进度")
		return
	for tick in mech.health:
		mech.receive_hit()
	if not level.get_node("HUD/OutcomePanel/TitleLabel").text.contains("任务完成"):
		_fail("击败机甲后未显示任务完成")
		return
	await _retry()
	level = current_scene
	if level.get_node("BossSlot/DefenseMech").health != max_mech_health or level.get_node("ExitDoor/DoorBlocker/CollisionShape2D").disabled:
		_fail("通关重试未重置机甲和门")
		return
	print("PASS: 两种死因、死亡信号顺序、HUD、无限整关重试与通关")
	quit(0)


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
