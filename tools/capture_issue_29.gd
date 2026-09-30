extends SceneTree

var output_prefix := "res://docs/art/issue-29-"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() == 2 and args[0] == "--output-prefix":
		output_prefix = args[1]
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
	var feedback := level.get_node("CombatFeedback") as Node2D
	for tick in 18:
		await physics_frame
		if _has_impact(feedback):
			break
	for tick in 3:
		await physics_frame
	await process_frame
	if not _has_impact(feedback) or not _save("enemy-hit"):
		push_error("Could not capture a real enemy impact")
		quit(1)
		return
	for tick in 14:
		await physics_frame
	var wall_shot := (load("res://scenes/friendly_projectile.tscn") as PackedScene).instantiate() as Area2D
	wall_shot.global_position = Vector2(720, 258)
	actor.projectile_fired.emit(wall_shot)
	for tick in 8:
		await physics_frame
		if _has_impact(feedback):
			break
	for tick in 3:
		await physics_frame
	await process_frame
	if not _has_impact(feedback) or not _save("wall-hit"):
		push_error("Could not capture a real terrain impact")
		quit(1)
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
	level.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	call_deferred("quit", 0)


func _has_impact(feedback: Node2D) -> bool:
	for child in feedback.get_children():
		if child is Sprite2D:
			return true
	return false


func _save(name: String) -> bool:
	var image := root.get_texture().get_image()
	if image.get_size() != Vector2i(640, 360):
		push_error("Expected 640x360; got " + str(image.get_size()))
		quit(1)
		return false
	var path := output_prefix + name + ".png"
	if image.save_png(path) != OK:
		push_error("Could not capture " + path)
		quit(1)
		return false
	print("Captured live Godot viewport: ", path)
	return true
