extends SceneTree
## Public scene state and ordinary movement, without calling level internals.


func _initialize() -> void:
	call_deferred("_run")


func _steps(count: int) -> void:
	for tick in count:
		await physics_frame
		await process_frame


func _run() -> void:
	root.size = Vector2i(640, 360)
	change_scene_to_file("res://scenes/level.tscn")
	await process_frame
	await process_frame
	var level := current_scene
	var actor := level.get_node("Operative/Operative") as CharacterBody2D
	var camera := level.get_node("Camera2D") as Camera2D
	var mech := level.get_node("BossSlot/DefenseMech") as DefenseMech
	var barrier := level.get_node("CombatEntry/Barrier/CollisionShape2D") as CollisionShape2D
	actor.position = Vector2(3464, 252)
	await _steps(5)
	if not barrier.disabled or not mech.get_node("Muzzle").visible:
		_fail("入场须保留可见预告与开放入口")
		return
	await _steps(20)
	Input.action_press("move_right")
	await _steps(70)
	Input.action_release("move_right")
	camera.force_update_scroll()
	var center := camera.get_screen_center_position()
	if barrier.disabled or center.x != 3580.0 or actor.position.x < 3650:
		_fail("入口闭合后向右推进须保持水平镜头中心3580")
		return
	var view := Rect2(center - Vector2(320, 180), Vector2(640, 360))
	for path in ["CombatEntry/Artwork", "Operative/Operative/Sprite", "BossSlot/DefenseMech/Sprite"]:
		var sprite := level.get_node(path) as Sprite2D
		var bounds := Rect2(sprite.to_global(sprite.get_rect().position), sprite.get_rect().size)
		if not view.encloses(bounds):
			_fail("固定640×360视口必须完整容纳门体、行动员与防御机甲：" + path)
			return
	# Closed death and completion freeze the encounter; R creates a fresh run.
	for outcome in ["death", "complete"]:
		if outcome == "death":
			actor.invulnerability_duration = 0.0
			# Let the earlier real projectile's existing invulnerability expire.
			await _steps(50)
			for hit in actor.health:
				actor.receive_hit()
		else:
			for hit in mech.health:
				mech.receive_hit()
		var frozen := actor.position
		Input.action_press("move_right")
		await _steps(10)
		Input.action_release("move_right")
		if actor.position != frozen or camera.position.x != 3580.0 or barrier.disabled:
			_fail("闭门后的死亡/通关应冻结关卡并保持稳定镜头")
			return
		await _retry()
		level = current_scene
		actor = level.get_node("Operative/Operative") as CharacterBody2D
		camera = level.get_node("Camera2D") as Camera2D
		mech = level.get_node("BossSlot/DefenseMech") as DefenseMech
		barrier = level.get_node("CombatEntry/Barrier/CollisionShape2D") as CollisionShape2D
		if actor.position.x != 140 or actor.health != 3 or not barrier.disabled \
				or camera.position.x != 320 or level.get_node("CombatEntry/Artwork").frame != 0:
			_fail("R重试须恢复起点、开放门体和未锁定镜头")
			return
		actor.position = Vector2(700, 252)
		await _steps(4)
		if camera.position.x != 815.0:
			_fail("R重试后镜头须继续跟随行动员")
			return
		actor.position = Vector2(3464, 252)
		await _steps(30)
		if barrier.disabled or camera.position.x != 3580.0:
			_fail("新一轮警告闭合须再次锁定镜头")
			return
	print("PASS: 闭门固定镜头、三者完整入镜、死亡/通关冻结及R恢复跟随")
	current_scene.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	call_deferred("quit", 0)


func _retry() -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_R
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	await process_frame
	event.pressed = false
	Input.parse_input_event(event)
	await _steps(2)


func _fail(message: String) -> void:
	Input.action_release("move_right")
	push_error(message)
	quit(1)
