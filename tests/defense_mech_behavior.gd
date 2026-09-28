extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var mech_scene := load("res://scenes/defense_mech.tscn") as PackedScene
	if mech_scene == null:
		_fail("缺少可实例化的防御机甲场景")
		return
	var mech := mech_scene.instantiate() as StaticBody2D
	root.add_child(mech)
	var shape := (mech.get_node("Body") as CollisionShape2D).shape as RectangleShape2D
	if shape.size.x <= 28.0 or shape.size.y <= 42.0 or mech.max_health <= 3:
		_fail("机甲受击范围和生命必须明显大于机械兵")
		return
	var full_view := Rect2(Vector2(-320, -180), Vector2(640, 360))
	var cut_view := Rect2(Vector2(-250, -180), Vector2(200, 360))
	mech.update_visibility(cut_view)
	mech.receive_hit()
	if mech.attack_enabled or mech.health != mech.max_health:
		_fail("未完整入镜时不能激活或隔屏消耗生命")
		return
	mech.update_visibility(full_view)
	mech.receive_hit()
	if not mech.attack_enabled or mech.health != mech.max_health - 1:
		_fail("完整入镜后必须持续可受击")
		return
	print("PASS: 机甲体量、完整入镜激活和隔屏防护")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
