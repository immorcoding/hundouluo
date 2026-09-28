extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if get_root().content_scale_size != Vector2i(640, 360):
		_fail("logical viewport must be 640x360")
		return
	if ProjectSettings.get_setting("display/window/stretch/scale_mode") != "integer":
		_fail("window must use integer pixel scaling")
		return
	var level := (load("res://scenes/level.tscn") as PackedScene).instantiate()
	root.add_child(level)
	for node_path in ["HangarFar", "HangarMid", "Ground", "Ground/Left", "Ground/Right"]:
		if level.get_node_or_null(node_path) == null:
			_fail("missing editable scene layer: " + node_path)
			return
	var left := level.get_node("Ground/Left") as StaticBody2D
	var right := level.get_node("Ground/Right") as StaticBody2D
	if left.collision_layer != 4 or right.collision_layer != 4:
		_fail("ground must use terrain collision layer")
		return
	for segment in [left, right]:
		var shape := segment.get_node("CollisionShape2D") as CollisionShape2D
		var rect := shape.shape as RectangleShape2D
		if rect == null or shape.global_position.y - rect.size.y / 2.0 != 288.0:
			_fail("ground visuals and collision top must agree")
			return
	if left.get_node("CollisionShape2D").global_position.x + 384.0 != 768.0:
		_fail("left edge does not end at the visible gap")
		return
	if right.get_node("CollisionShape2D").global_position.x - 288.0 != 864.0:
		_fail("right edge does not begin at the visible landing")
		return
	if level.get_node("Ground/Tiles").get_child_count() != 168:
		_fail("floor tiles must exactly cover both solid segments, not the gap")
		return
	# Editing an exposed scene collider must also reposition its painted floor.
	var shifted := (load("res://scenes/level.tscn") as PackedScene).instantiate()
	(shifted.get_node("Ground/Right") as StaticBody2D).position.x += 24
	root.add_child(shifted)
	var has_shifted_tile := false
	for tile in shifted.get_node("Ground/Tiles").get_children():
		if tile.position == Vector2(876, 300):
			_fail("visible floor remained at the old right collider edge")
			return
		if tile.position == Vector2(900, 300) and tile.frame == 3:
			has_shifted_tile = true
			break
	if not has_shifted_tile:
		_fail("editing the right collider did not move its visible landing")
		return
	print("PASS: 640x360 hangar layers and gap visuals match terrain collision")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
