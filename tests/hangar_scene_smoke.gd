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
		if rect == null or shape.global_position.y - rect.size.y / 2.0 != 252.0:
			_fail("ground visuals and collision top must agree")
			return
	if left.get_node("CollisionShape2D").global_position.x + 672.0 != 1344.0:
		_fail("left edge does not end at the visible gap")
		return
	if right.get_node("CollisionShape2D").global_position.x - 1440.0 != 1440.0:
		_fail("right edge does not begin at the visible landing")
		return
	if level.get_node("Ground/Tiles").get_child_count() != 10:
		_fail("warning tiles must cover only the two real gap walls")
		return
	if level.get_node("Ground/Deck").get_child_count() != 3:
		_fail("each collider must crop solid deck across art sections")
		return
	var regions: Array[Rect2] = []
	for section in level.get_node("Ground/Deck").get_children():
		regions.append(section.region_rect)
	if regions != [Rect2(0, 0, 1344, 108), Rect2(0, 0, 1440, 108), Rect2(0, 0, 1440, 108)]:
		_fail("painted deck regions do not match solid colliders and empty gap")
		return
	# Editing an exposed scene collider must also reposition its painted floor.
	var shifted := (load("res://scenes/level.tscn") as PackedScene).instantiate()
	(shifted.get_node("Ground/Right") as StaticBody2D).position.x += 24
	root.add_child(shifted)
	var has_shifted_tile := false
	for tile in shifted.get_node("Ground/Tiles").get_children():
		if tile.position == Vector2(1452, 264):
			_fail("visible floor remained at the old right collider edge")
			return
		if tile.position == Vector2(1476, 264) and tile.frame == 3:
			has_shifted_tile = true
			break
	if not has_shifted_tile:
		_fail("editing the right collider did not move its visible landing")
		return
	var shifted_deck := shifted.get_node("Ground/Deck").get_child(1) as Sprite2D
	if shifted_deck.region_rect != Rect2(24, 0, 1416, 108) or shifted_deck.position.x != 2172.0:
		_fail("editing the right collider did not move its continuous deck")
		return
	print("PASS: 640x360 hangar layers and gap visuals match terrain collision")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
