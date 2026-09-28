extends SceneTree


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	print("Godot window: ", DisplayServer.window_get_size(), "; logical viewport: ", root.content_scale_size)
	var level := (load("res://scenes/level.tscn") as PackedScene).instantiate()
	root.add_child(level)
	var actor := level.get_node("Operative/Operative") as CharacterBody2D
	for shot in [{"x": 310.0, "file": "hangar-godot-combat.png"},
			{"x": 690.0, "file": "hangar-godot-gap.png"},
			{"x": 970.0, "file": "hangar-godot-mech.png"}]:
		actor.position = Vector2(shot.x, 252)
		actor.velocity = Vector2.ZERO
		await process_frame
		await process_frame
		var path: String = "res://docs/art/" + shot.file
		var error := root.get_texture().get_image().save_png(path)
		if error != OK:
			push_error("Could not capture Godot viewport: " + path)
			quit(1)
			return
		print("Captured actual Godot viewport: ", path)
	actor.position = Vector2(705, 252)
	actor.velocity = Vector2.ZERO
	for tick in 3:
		await physics_frame
	Input.action_press("move_right")
	Input.action_press("jump")
	Input.action_press("shoot")
	for tick in 12:
		await physics_frame
	Input.action_release("move_right")
	Input.action_release("jump")
	Input.action_release("shoot")
	await process_frame
	var action_path := "res://docs/art/hangar-godot-action.png"
	if root.get_texture().get_image().save_png(action_path) != OK:
		push_error("Could not capture Godot action viewport")
		quit(1)
		return
	print("Captured actual Godot action viewport: ", action_path)
	quit(0)
