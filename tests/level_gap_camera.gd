extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var level := (load("res://scenes/level.tscn") as PackedScene).instantiate()
	root.add_child(level)
	var actor := level.get_node("Operative/Operative") as CharacterBody2D
	var camera := level.get_node("Camera2D") as Camera2D
	var enemies := level.get_node("Enemies").get_children()
	for x in [140.0, 1010.0, 1250.0, 1770.0, 2050.0, 2500.0, 3000.0, 3700.0, 4200.0]:
		actor.position = Vector2(x, 252)
		actor.velocity = Vector2.ZERO
		for tick in 3:
			await physics_frame
		camera.force_update_scroll()
		var half_view := camera.get_viewport_rect().size / camera.zoom / 2.0
		var center := camera.get_screen_center_position()
		var visible_area := Rect2(center - half_view, half_view * 2.0)
		var visible_soldiers := 0
		for enemy in enemies:
			if enemy.is_fully_visible_in(visible_area):
				visible_soldiers += 1
			elif enemy.attack_enabled:
				_fail("屏外机械兵被允许攻击")
				return
		if visible_soldiers > 2:
			_fail("同屏超过两个机械兵")
			return
		if x == 1010.0 and (not visible_area.has_point(Vector2(1344, 252)) or
				not visible_area.has_point(Vector2(1440, 252))):
			_fail("接近缺口时两侧边缘未同时入镜")
			return
		if x == 4200.0 and (center.x != 4000.0 or not visible_area.has_point(Vector2(4130, 180))):
			_fail("镜头未在终点止住或舱门未入镜")
			return
	# A jump begun on flat run-up must land on the far side without a
	# pixel-perfect takeoff from the very edge.
	actor.position = Vector2(1305, 252)
	actor.velocity = Vector2.ZERO
	for tick in 3:
		await physics_frame
	Input.action_press("move_right")
	Input.action_press("jump")
	await physics_frame
	Input.action_release("jump")
	for tick in 51:
		await physics_frame
	Input.action_release("move_right")
	if actor.position.x <= 1460.0 or not actor.is_on_floor() or actor.health == 0:
		_fail("平坦助跑的正常跳跃未安全落在另一侧")
		return
	print("PASS: 缺口两侧可见、常规跳跃落地、同屏上限与终点镜头")
	quit(0)


func _fail(message: String) -> void:
	Input.action_release("move_right")
	Input.action_release("jump")
	push_error(message)
	quit(1)
