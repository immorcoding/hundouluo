extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var encounter := (load("res://tests/defense_mech_encounter.tscn") as PackedScene).instantiate()
	root.add_child(encounter)
	var mech := encounter.get_node("DefenseMech") as DefenseMech
	var muzzle := mech.get_node("Muzzle") as Sprite2D
	if muzzle == null or muzzle.texture == null or muzzle.frame != 28:
		_fail("防御机甲应使用完整的获批蓄力环")
		return
	var saw_progress := false
	var shot_positions: Array[Vector2] = []
	mech.projectile_fired.connect(func(projectile: Area2D) -> void:
		shot_positions.append(projectile.global_position)
		if projectile.visual_variant != 1:
			_fail("机甲须使用宽轮廓敌弹")
	)
	for tick in 100:
		await physics_frame
		if muzzle.visible and muzzle.frame > 28:
			saw_progress = true
		if shot_positions.size() >= 1:
			break
	if not saw_progress or shot_positions.is_empty() \
			or absf(shot_positions[0].y - muzzle.global_position.y) > 8.0:
		_fail("蓄力环须渐进显示在原低弹道，不能暗改命中路线")
		return
	print("PASS: 完整蓄力环、机甲宽弹及原低弹道")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
