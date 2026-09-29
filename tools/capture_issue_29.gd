extends SceneTree


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	root.size = Vector2i(640, 360)
	var level := (load("res://scenes/level.tscn") as PackedScene).instantiate()
	root.add_child(level)
	var actor := level.get_node("Operative/Operative") as CharacterBody2D
	actor.position = Vector2(680, 252)
	actor.velocity = Vector2.ZERO
	for tick in 3:
		await physics_frame
	var friendly := (load("res://scenes/friendly_projectile.tscn") as PackedScene).instantiate() as Area2D
	friendly.global_position = actor.to_global(Vector2(30, -31))
	actor.projectile_fired.emit(friendly)
	for tick in 5:
		await physics_frame
	await process_frame
	if not _save("combat"):
		return
	actor.position = Vector2(3700, 252)
	actor.velocity = Vector2.ZERO
	for tick in 26:
		await physics_frame
	await process_frame
	if not _save("charge"):
		return
	for tick in 42:
		await physics_frame
	await process_frame
	if not _save("mech-shot"):
		return
	quit(0)


func _save(name: String) -> bool:
	var image := root.get_texture().get_image()
	if image.get_size() != Vector2i(640, 360):
		push_error("Expected 640x360; got " + str(image.get_size()))
		quit(1)
		return false
	var path := "res://docs/art/issue-29-" + name + ".png"
	if image.save_png(path) != OK:
		push_error("Could not capture " + path)
		quit(1)
		return false
	print("Captured live Godot viewport: ", path)
	return true
