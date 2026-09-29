extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	stage.add_child((load("res://tests/operative_floor.tscn") as PackedScene).instantiate())
	var actor := (load("res://scenes/operative.tscn") as PackedScene).instantiate()
	stage.add_child(actor)
	actor.position.y = -30
	var sprite := actor.get_node("Sprite") as Sprite2D
	var image := sprite.texture.get_image()
	# Visually inspected barrel ends, in the actor's local coordinates. These
	# separately check scene data against emitted projectiles and atlas pixels.
	var expected := [Vector2(28, -26), Vector2(31, -24), Vector2(31, -24),
			Vector2(23, -25), Vector2(21, -25), Vector2(26, -28)]
	for frame in expected.size():
		var point: Vector2 = expected[frame]
		var pixel := Vector2i(frame * 72 + 36 + int(point.x) - 1,
				30 + int(point.y - sprite.position.y))
		if image.get_pixelv(pixel).a < 0.9:
			_fail("muzzle point no longer touches the visible barrel, frame " + str(frame))
			return
	var seen := {}
	var errors: Array[String] = []
	actor.projectile_fired.connect(func(projectile: Area2D) -> void:
		var frame := sprite.frame
		var direction := -1 if sprite.flip_h else 1
		var local: Vector2 = actor.to_local(projectile.global_position)
		var point: Vector2 = expected[frame]
		if not local.is_equal_approx(Vector2(direction * point.x, point.y)):
			errors.append("spawn misses frame's muzzle: " + str(frame))
		seen[str(frame) + ":" + str(direction)] = true
		projectile.free()
	)
	for tick in 20:
		await physics_frame
	actor.fire_interval = 0.01
	Input.action_press("shoot")
	for tick in 3:
		await physics_frame
	Input.action_press("move_right")
	for tick in 20:
		await physics_frame
	Input.action_press("jump")
	for tick in 3:
		await physics_frame
	Input.action_release("jump")
	Input.action_release("move_right")
	Input.action_press("move_left")
	for tick in 3:
		await physics_frame
	Input.action_release("move_left")
	Input.action_release("shoot")
	if not errors.is_empty():
		_fail(errors[0])
		return
	for key in ["0:1", "1:1", "2:1", "3:1", "3:-1"]:
		if not seen.has(key):
			_fail("did not exercise muzzle state " + key)
			return
	print("PASS: atlas barrels match standing/running/jumping and mirrored projectile origins")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
