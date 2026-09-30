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
	if hud.get_node("LifeDisplay/Life3").texture != load("res://assets/ui_v011/life-full.png") or hud.get_node("MechProgress").visible:
		_fail("开场 HUD 生命或机甲进度不正确")
		return
	for soldier in level.get_node("Enemies").get_children():
		for hit in soldier.health:
			soldier.receive_hit()
	await process_frame
	for soldier in level.get_node("Enemies").get_children():
		if soldier.health != 0 or soldier.get_node("Sprite").frame != 6:
			_fail("机械兵死亡应留在场景中作为倒地残骸")
			return
	if hud.get_node("OutcomePanel").visible or level.get_node("ExitDoor/DoorBlocker/CollisionShape2D").disabled:
		_fail("普通敌人全灭不应通关或开门")
		return
	actor.position = Vector2(3700, 252)
	actor.invulnerability_duration = 0.0
	actor.receive_hit()
	if hud.get_node("LifeDisplay/Life2").texture != load("res://assets/ui_v011/life-full.png") or hud.get_node("LifeDisplay/Life3").texture != load("res://assets/ui_v011/life-empty.png"):
		_fail("受击信号未更新 HUD")
		return
	actor.receive_hit()
	# The fatal hit must also work inside the real physics collision callback.
	var fatal_projectile := (load("res://scenes/enemy_projectile.tscn") as PackedScene).instantiate() as Area2D
	fatal_projectile.position = actor.position + Vector2(20, -18)
	fatal_projectile.direction = -1
	level.get_node("Projectiles").add_child(fatal_projectile)
	for tick in 20:
		await physics_frame
		await process_frame
		if actor.health == 0:
			break
	if not hud.get_node("OutcomePanel").visible or hud.get_node("LifeDisplay").visible or hud.get_node("OutcomePanel/ReasonLabel").text != "生命耗尽":
		_fail("生命归零未显示对应失败原因")
		return
	await _retry()
	level = current_scene
	if level == null or level.get_node("Operative/Operative").health != 3 or level.get_node("Enemies").get_child_count() != 5:
		_fail("终点生命死亡重试未恢复生命与敌人")
		return
	for soldier in level.get_node("Enemies").get_children():
		if soldier.health != soldier.max_health or soldier.get_node("Sprite").frame == 6:
			_fail("整关重试未恢复机械兵的生命和站姿")
			return
	if level.get_node("Operative/Operative").position.x != 140.0 or not level.get_node("HUD/LifeDisplay").visible or level.get_node("HUD/OutcomePanel").visible:
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
	var active_projectile := (load("res://scenes/enemy_projectile.tscn") as PackedScene).instantiate() as Area2D
	active_projectile.position = Vector2(3600, 100)
	level.get_node("Projectiles").add_child(active_projectile)
	var victory_health: int = actor.health
	var queued_projectile := (load("res://scenes/enemy_projectile.tscn") as PackedScene).instantiate() as Area2D
	queued_projectile.position = Vector2(3600, 80)
	level.get_node("Projectiles").add_child(queued_projectile)
	# A collision already queued in the same physics flush can arrive after win.
	# Deliver that public signal synchronously after the level's victory handler.
	mech.died.connect(func() -> void: queued_projectile.body_entered.emit(actor))
	for tick in mech.health - 1:
		mech.receive_hit()
	# Deliver the winning hit through normal input and projectile collision.
	Input.action_press("shoot")
	for tick in 60:
		await physics_frame
		await process_frame
		if mech.health == 0:
			break
	Input.action_release("shoot")
	if not level.get_node("HUD/OutcomePanel/TitleLabel").text.contains("任务完成"):
		_fail("击败机甲后未显示任务完成")
		return
	if actor.health != victory_health:
		_fail("通关确定后，同批已排队敌弹碰撞不可继续改变行动员生命")
		return
	var completed_position := actor.position
	var soldier := level.get_node("Enemies/PairTwoA") as MechanicalSoldier
	var soldier_position := soldier.position
	var projectile_position := active_projectile.position
	var fired := [0]
	actor.projectile_fired.connect(func(_projectile: Area2D) -> void: fired[0] += 1)
	Input.action_press("move_right")
	Input.action_press("shoot")
	for tick in 12:
		await physics_frame
	Input.action_release("move_right")
	Input.action_release("shoot")
	if actor.position != completed_position or fired[0] != 0 or soldier.position != soldier_position or active_projectile.position != projectile_position:
		_fail("通关遮罩下行动员、敌人或弹丸仍在运行")
		return
	await _retry()
	level = current_scene
	if level.get_node("BossSlot/DefenseMech").health != max_mech_health or level.get_node("ExitDoor/DoorBlocker/CollisionShape2D").disabled:
		_fail("通关重试未重置机甲和门")
		return
	print("PASS: 两种死因、死亡信号顺序、HUD、无限整关重试与通关")
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
	push_error(message)
	quit(1)


func _finish() -> void:
	quit(0)
