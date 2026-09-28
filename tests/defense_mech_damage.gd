extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(640, 360)
	var encounter := (load("res://tests/defense_mech_encounter.tscn") as PackedScene).instantiate()
	root.add_child(encounter)
	var mech := encounter.get_node("DefenseMech") as DefenseMech
	var camera := encounter.get_node("Camera2D") as Camera2D
	var changes: Array[int] = []
	var deaths: Array[int] = []
	var shots: Array[int] = []
	mech.health_changed.connect(func(value: int) -> void: changes.append(value))
	mech.died.connect(func() -> void: deaths.append(1))
	mech.projectile_fired.connect(func(_projectile: Area2D) -> void: shots.append(1))
	camera.position.x = -500
	camera.force_update_scroll()
	for frame in 140:
		await physics_frame
	if not shots.is_empty() or mech.attack_enabled:
		_fail("镜头外不可蓄力或发弹")
		return
	camera.position.x = 0
	camera.force_update_scroll()
	for frame in 3:
		await physics_frame
	var friendly := (load("res://scenes/friendly_projectile.tscn") as PackedScene).instantiate() as Area2D
	friendly.global_position = mech.global_position + Vector2(-60, -38)
	encounter.get_node("Projectiles").add_child(friendly)
	for frame in 10:
		await physics_frame
		if mech.health < mech.max_health:
			break
	if changes != [mech.max_health - 1]:
		_fail("己方弹丸应实际命中机甲宽受击框并向 HUD 发出生命信号")
		return
	for frame in 115:
		await physics_frame
	mech.receive_hit()
	if changes.size() != 2 or changes[-1] != mech.max_health - 2:
		_fail("蓄力和射击空档中也必须持续可受击")
		return
	for hit in mech.health:
		mech.receive_hit()
	if mech.health != 0 or deaths.size() != 1 or changes[-1] != 0 \
			or (mech.get_node("Sprite") as Sprite2D).frame != 5:
		_fail("生命耗尽须只发一次死亡信号并停在倒地帧")
		return
	var shot_count := shots.size()
	for frame in 200:
		await physics_frame
	mech.receive_hit()
	if deaths.size() != 1 or shots.size() != shot_count or mech.health != 0:
		_fail("死亡后不能再攻击或重复受击／死亡")
		return
	print("PASS: 弹丸命中、全程生命信号、死亡终止")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
