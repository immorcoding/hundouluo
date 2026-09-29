extends SceneTree


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	root.size = Vector2i(640, 360)
	for state in ["before", "after"]:
		var level := (load("res://scenes/level.tscn") as PackedScene).instantiate()
		root.add_child(level)
		var actor := level.get_node("Operative/Operative") as CharacterBody2D
		if state == "before":
			actor.get_node("Sprite").position.y = -30
			level.get_node("BossSlot/DefenseMech/Sprite").position.y = -45
			level.get_node("CombatEntry").visible = false
		await process_frame
		await process_frame
		if not _save("start-" + state):
			return
		actor.position = Vector2(3510, 252)
		actor.velocity = Vector2.ZERO
		for tick in (3 if state == "before" else 22):
			await physics_frame
		await process_frame
		if not _save("mech-" + state):
			return
		level.queue_free()
		await process_frame
	quit(0)


func _save(name: String) -> bool:
	var image := root.get_texture().get_image()
	if image.get_size() != Vector2i(640, 360):
		push_error("Expected a 640x360 viewport; got " + str(image.get_size()))
		quit(1)
		return false
	var path := "res://docs/art/issue-28-" + name + ".png"
	if image.save_png(path) != OK:
		push_error("Could not capture " + path)
		quit(1)
		return false
	print("Captured actual Godot viewport: ", path)
	return true
