extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(640, 360)
	var encounter := (load("res://tests/defense_mech_encounter.tscn") as PackedScene).instantiate()
	root.add_child(encounter)
	var mech := encounter.get_node("DefenseMech") as DefenseMech
	var muzzle := mech.get_node("Muzzle") as CanvasItem
	var fired_at: Array[int] = []
	var shot_positions: Array[Vector2] = []
	var shot_directions: Array[int] = []
	mech.projectile_fired.connect(func(projectile: Area2D) -> void:
		fired_at.append(Engine.get_physics_frames())
		shot_positions.append(projectile.global_position)
		shot_directions.append(projectile.direction)
	)
	var saw_charge := false
	for frame in 300:
		await physics_frame
		if muzzle.visible and mech.get_node("Sprite").frame in [1, 2]:
			saw_charge = true
		if fired_at.size() >= 4:
			break
	if not saw_charge or fired_at.size() < 4:
		_fail("须有可见蓄力和重复弹丸组")
		return
	if fired_at[0] < 35 or fired_at[1] - fired_at[0] < 8 \
			or fired_at[2] - fired_at[1] < 8 or fired_at[3] - fired_at[2] < 100:
		_fail("应先明显蓄力、间隔发射三发，再留出足够射击空档：%s" % [fired_at])
		return
	for index in shot_positions.size():
		if shot_positions[index].y > mech.global_position.y - 10.0 \
				or shot_positions[index].y < mech.global_position.y - 30.0 \
				or shot_directions[index] != -1:
			_fail("弹丸组应偏低并朝玩家水平方向发射")
			return
	var camera := encounter.get_node("Camera2D") as Camera2D
	camera.position.x = -500
	camera.force_update_scroll()
	for frame in 100:
		await physics_frame
	if fired_at.size() != 4 or muzzle.visible:
		_fail("机甲离镜后必须取消未完成的弹丸组")
		return
	camera.position.x = 0
	camera.force_update_scroll()
	var reentry_frame := Engine.get_physics_frames()
	for frame in 90:
		await physics_frame
		if fired_at.size() == 5:
			break
	if fired_at.size() != 5 or fired_at[4] - reentry_frame < 35:
		_fail("重新入镜须从完整蓄力开始，不能立刻发弹")
		return
	print("PASS: 可见蓄力、三发低弹、空档及离镜取消／重新预告")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
