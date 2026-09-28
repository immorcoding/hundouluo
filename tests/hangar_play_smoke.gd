extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var level := (load("res://scenes/level.tscn") as PackedScene).instantiate()
	root.add_child(level)
	var actor := level.get_node("Operative/Operative") as CharacterBody2D
	for tick in 5:
		await physics_frame
	if not actor.is_on_floor():
		_fail("operative is not standing on the painted hangar floor")
		return
	var start_x := actor.position.x
	Input.action_press("move_right")
	Input.action_press("jump")
	Input.action_press("shoot")
	for tick in 8:
		await physics_frame
	Input.action_release("move_right")
	Input.action_release("jump")
	Input.action_release("shoot")
	if actor.position.x <= start_x or actor.position.y >= 288:
		_fail("operative cannot move and jump in the art acceptance scene")
		return
	if level.get_node("Projectiles").get_child_count() == 0:
		_fail("operative cannot shoot in the art acceptance scene")
		return
	actor.position = Vector2(816, 260)
	actor.velocity = Vector2.ZERO
	for tick in 17:
		await physics_frame
	if actor.position.y <= 288:
		_fail("painted gap has an invisible floor")
		return
	print("PASS: hangar scene supports run/jump/fire and its visible gap is open")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
