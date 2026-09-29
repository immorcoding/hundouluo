extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var level := (load("res://scenes/level.tscn") as PackedScene).instantiate()
	root.add_child(level)
	var actor := level.get_node("Operative/Operative") as CharacterBody2D
	var mech := level.get_node("BossSlot/DefenseMech") as DefenseMech
	var soldier := level.get_node("Enemies/SoloSoldier") as MechanicalSoldier
	for tick in 5:
		await physics_frame
	var ground := level.get_node("Ground/Right/CollisionShape2D") as CollisionShape2D
	if ground.global_position.y - (ground.shape as RectangleShape2D).size.y / 2.0 != 252:
		_fail("视觉落地不得移动地面碰撞或改变跳距")
		return
	for frame in [0, 1, 2]:
		var foot := _opaque_foot(actor.get_node("Sprite") as Sprite2D, frame)
		if foot < 261 or foot > 265:
			_fail("行动员站立/跑动帧脚底须贴近亮甲板 y=263，当前 %d" % foot)
			return
	var mech_foot := _opaque_foot(mech.get_node("Sprite") as Sprite2D, 0)
	if mech_foot < 261 or mech_foot > 265:
		_fail("防御机甲脚底须贴近亮甲板 y=263，当前 %d" % mech_foot)
		return
	var soldier_foot := _opaque_foot(soldier.get_node("Sprite") as Sprite2D, 0)
	if soldier_foot != 257:
		_fail("机械兵现有视觉基准不可漂移，当前 %d" % soldier_foot)
		return
	print("PASS: 行动员跑动与机甲脚底视觉落地，碰撞地面未改")
	quit(0)


func _opaque_foot(sprite: Sprite2D, frame: int) -> int:
	var image := sprite.texture.get_image()
	var width := image.get_width() / sprite.hframes
	var bottom := 0
	for y in image.get_height():
		for x in width:
			if image.get_pixel(frame * width + x, y).a >= 0.8:
				bottom = y
	return roundi(sprite.global_position.y - image.get_height() / 2.0 + bottom)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
