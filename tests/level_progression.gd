extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var level := (load("res://scenes/level.tscn") as PackedScene).instantiate()
	root.add_child(level)
	var actor := level.get_node("Operative/Operative") as CharacterBody2D
	var camera := level.get_node("Camera2D") as Camera2D
	var enemies := level.get_node("Enemies").get_children()
	if enemies.size() != 5:
		_fail("五段关卡应有五个实际机械兵")
		return
	var positions: Array[float] = []
	for enemy in enemies:
		if not enemy is MechanicalSoldier or enemy.target != actor:
			_fail("机械兵未接入行动员目标")
			return
		positions.append(enemy.position.x)
	if positions[0] >= 1100.0 or positions[1] <= 1700.0 or positions[4] >= 3500.0:
		_fail("教学单兵、单独缺口和后续组合段顺序不对")
		return
	var right_shape := level.get_node("Ground/Right/CollisionShape2D") as CollisionShape2D
	var right_end := right_shape.global_position.x + (right_shape.shape as RectangleShape2D).size.x / 2.0
	if right_end < 4200.0 or level.get_node_or_null("BossSlot") == null or level.get_node_or_null("ExitDoor") == null:
		_fail("终点缺少平地、机甲接缝或可见舱门")
		return
	if level.get_node("Ground/Deck").get_child_count() != 3:
		_fail("延长甲板应按 1440 像素美术分层裁切，缺口仍为空")
		return
	for tick in 4:
		await physics_frame
	if enemies[3].attack_enabled or enemies[4].attack_enabled:
		_fail("镜头外机械兵被允许攻击")
		return
	actor.position = Vector2(3700, 252)
	actor.velocity = Vector2.ZERO
	for tick in 3:
		await physics_frame
	if absf(camera.get_screen_center_position().y - 180.0) > 1.0:
		_fail("垂直镜头随行动员晃动")
		return
	if camera.get_screen_center_position().x < 3700.0:
		_fail("镜头没有跟随并预留前方视野")
		return
	actor.position = Vector2(4000, 252)
	actor.velocity = Vector2.ZERO
	for tick in 3:
		await physics_frame
	Input.action_press("move_right")
	for tick in 45:
		await physics_frame
	Input.action_release("move_right")
	if actor.position.x > 4070.0 or not actor.is_on_floor():
		_fail("终点舱门没有阻止行动员跑出连续平地")
		return
	var fall_events := [0]
	var death_events := [0]
	var event_order: Array[String] = []
	level.operative_fell.connect(func() -> void:
		fall_events[0] += 1
		event_order.append("fell"))
	actor.died.connect(func() -> void:
		death_events[0] += 1
		event_order.append("died"))
	actor.position = Vector2(1392, 425)
	actor.velocity = Vector2.ZERO
	for tick in 3:
		await physics_frame
	if fall_events[0] != 1 or death_events[0] != 1 or actor.health != 0 or event_order != ["fell", "died"]:
		_fail("唯一缺口跌落未恰好触发一次死亡事件")
		return
	print("PASS: 五段布置、五个机械兵、终点接缝、镜头和跌落事件")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
