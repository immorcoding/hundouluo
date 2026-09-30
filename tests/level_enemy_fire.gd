extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var level := (load("res://scenes/level.tscn") as PackedScene).instantiate()
	root.add_child(level)
	var actor := level.get_node("Operative/Operative") as CharacterBody2D
	var soldier := level.get_node("Enemies/SoloSoldier") as MechanicalSoldier
	var projectiles := level.get_node("Projectiles")
	actor.position = Vector2(630, 252)
	var warned := false
	for tick in 20:
		await physics_frame
		warned = warned or soldier.get_node("Muzzle").visible
		if projectiles.get_child_count() != 0:
			_fail("关卡中的单兵未完成可见预告就开火")
			return
	if not warned:
		_fail("关卡中的单兵没有预告")
		return
	var fired := false
	for tick in 35:
		await physics_frame
		if projectiles.get_child_count() > 0:
			fired = true
			break
	if not fired:
		_fail("机械兵的敌弹未接入关卡弹丸槽")
		return
	print("PASS: 关卡实际机械兵完整入镜、预告后才将敌弹交给关卡")
	# Release the scene before quitting so active WAV playbacks can retire.
	level.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	call_deferred("quit", 0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
