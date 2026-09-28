extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var level := (load("res://scenes/level.tscn") as PackedScene).instantiate()
	root.add_child(level)
	var actor := level.get_node("Operative/Operative") as CharacterBody2D
	var mech := level.get_node_or_null("BossSlot/DefenseMech") as DefenseMech
	if mech == null or mech.target != actor:
		_fail("终点机甲未连接行动员")
		return
	var door := level.get_node("ExitDoor/DoorBlocker/CollisionShape2D") as CollisionShape2D
	if door.disabled:
		_fail("击败机甲前门挡已放行")
		return
	var projectile := (load("res://scenes/enemy_projectile.tscn") as PackedScene).instantiate() as Area2D
	projectile.global_position = Vector2(3770, 222)
	mech.projectile_fired.emit(projectile)
	if projectile.get_parent() != level.get_node("Projectiles") or projectile.global_position != Vector2(3770, 222):
		_fail("机甲弹丸未保持世界位置进入 Projectiles")
		return
	projectile.queue_free()
	actor.position = Vector2(3400, 252)
	for tick in 4:
		await physics_frame
	if mech.attack_enabled:
		_fail("机甲未完整入镜却激活")
		return
	mech.receive_hit()
	if mech.health != mech.max_health:
		_fail("屏外机甲能被击伤")
		return
	actor.position = Vector2(3700, 252)
	for tick in 4:
		await physics_frame
	if not mech.attack_enabled:
		_fail("机甲完整入镜后未激活")
		return
	mech.receive_hit()
	if mech.health != mech.max_health - 1:
		_fail("入镜机甲未受击")
		return
	for tick in mech.health:
		mech.receive_hit()
	await physics_frame
	if not door.disabled or not level.get_node("HUD").get_node("OutcomePanel").visible:
		_fail("机甲击败后未开门并展示任务完成")
		return
	print("PASS: 机甲像素视口、弹丸接线、击败门槛")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
