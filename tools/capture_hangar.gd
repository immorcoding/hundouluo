extends SceneTree


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	print("Godot window: ", DisplayServer.window_get_size(), "; logical viewport: ", root.content_scale_size)
	var level := (load("res://scenes/level.tscn") as PackedScene).instantiate()
	root.add_child(level)
	var actor := level.get_node("Operative/Operative") as CharacterBody2D
	for shot in [{"x": 310.0, "file": "hangar-godot-combat.png"},
			{"x": 690.0, "file": "hangar-godot-gap.png"}]:
		actor.position = Vector2(shot.x, 288)
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
	quit(0)
