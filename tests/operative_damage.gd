extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var operative := (load("res://scenes/operative.tscn") as PackedScene).instantiate()
	root.add_child(operative)
	if not operative.has_signal("health_changed") or not operative.has_signal("died"):
		_fail("行动员缺少供关卡接收的生命或死亡信号")
		return
	var health_events: Array[int] = []
	var deaths := [0]
	var shots := [0]
	operative.health_changed.connect(func(value: int) -> void: health_events.append(value))
	operative.died.connect(func() -> void: deaths[0] += 1)
	operative.projectile_fired.connect(func(projectile: Area2D) -> void:
		shots[0] += 1
		projectile.queue_free()
	)
	operative.invulnerability_duration = 0.15
	if operative.health != 3:
		_fail("行动员初始生命不是 3")
		return
	operative.receive_hit()
	operative.receive_hit()
	if operative.health != 2 or health_events != [2]:
		_fail("有效命中应只扣 1 点，紧接的命中不连扣")
		return
	for frame in 12:
		await physics_frame
	operative.receive_hit()
	if operative.health != 1:
		_fail("短暂无敌结束后应该能再次受击")
		return
	for frame in 12:
		await physics_frame
	operative.receive_hit()
	operative.receive_hit()
	if operative.health != 0 or health_events != [2, 1, 0] or deaths[0] != 1:
		_fail("耗尽生命应只通知关卡一次死亡；事件：%s" % [health_events])
		return
	Input.action_press("shoot")
	for frame in 6:
		await physics_frame
	Input.action_release("shoot")
	if shots[0] != 0:
		_fail("死亡后仍在发弹")
		return
	print("PASS: 3 点生命、短暂无敌、生命与死亡信号")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
