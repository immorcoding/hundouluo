extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _steps(count: int) -> void:
	for tick in count:
		await physics_frame
		await process_frame


func _run() -> void:
	root.size = Vector2i(640, 360)
	for jumping in [false, true]:
		change_scene_to_file("res://scenes/level.tscn")
		await process_frame
		await process_frame
		var level := current_scene
		var actor := level.get_node("Operative/Operative") as CharacterBody2D
		var barrier := level.get_node("CombatEntry/Barrier/CollisionShape2D") as CollisionShape2D
		actor.position = Vector2(3330, 252)
		await _steps(4)
		Input.action_press("move_right")
		if jumping:
			Input.action_press("jump")
		await _steps(1)
		Input.action_release("jump")
		var top := 360.0
		for tick in 30:
			await _steps(1)
			var sprite := actor.get_node("Sprite") as Sprite2D
			top = minf(top, sprite.global_position.y + sprite.get_rect().position.y)
			if not barrier.disabled:
				_fail("未到入场阈值的正常跑跳不应关门")
				return
		Input.action_release("move_right")
		if actor.position.x < 3435 or top < 104 or actor.health != 3 or actor.get_node("Sprite").flip_h:
			_fail("开放门洞右向跑跳必须通过，跳跃轮廓不得进入上墙体")
			return
		await _steps(25)
		Input.action_press("move_left")
		if jumping:
			Input.action_press("jump")
		await _steps(1)
		Input.action_release("jump")
		await _steps(32)
		Input.action_release("move_left")
		await _steps(25)
		if actor.position.x > 3335 or not actor.is_on_floor() or not barrier.disabled \
				or not actor.get_node("Sprite").flip_h:
			_fail("开放门洞左向跑跳与落地必须通过，不增加实体侧墙")
			return
		print("PASS passage jumping=", jumping, " final_x=", actor.position.x, " min_sprite_top=", top)
	current_scene.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	call_deferred("quit", 0)


func _fail(message: String) -> void:
	for action in ["move_left", "move_right", "jump"]:
		Input.action_release(action)
	push_error(message)
	quit(1)
