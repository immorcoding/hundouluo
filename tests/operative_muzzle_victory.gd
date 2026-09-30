extends SceneTree
## Victory may disable the actor between physics and idle processing. Fixture
## uses initial teleport/public mech hits; the winning shot and turn use Input.

func _initialize() -> void:
	Engine.physics_ticks_per_second = 120
	call_deferred("_run")


func _run() -> void:
	change_scene_to_file("res://scenes/level.tscn")
	await process_frame
	await process_frame
	var actor := current_scene.get_node("Operative/Operative") as CharacterBody2D
	var mech := current_scene.get_node("BossSlot/DefenseMech") as DefenseMech
	actor.position = Vector2(3700, 252)
	for tick in 4:
		await physics_frame
		await process_frame
	for hit in mech.max_health - 1:
		mech.receive_hit()
	var fired: Array[Area2D] = []
	actor.projectile_fired.connect(func(projectile: Area2D) -> void: fired.append(projectile))
	Input.action_press("shoot")
	await physics_frame
	await process_frame
	Input.action_release("shoot")
	# Turn as soon as the shot approaches the real mech collider. The winning
	# collision occurs on a later physics flush; an idle callback can be skipped.
	var body := mech.get_node("Body") as CollisionShape2D
	var shape := body.shape as RectangleShape2D
	var edge := mech.global_position.x + body.position.x - shape.size.x / 2.0
	var turned := false
	for tick in 60:
		if not fired.is_empty() and is_instance_valid(fired[0]) and fired[0].position.x >= edge - 12:
			Input.action_press("move_left")
			turned = true
		await physics_frame
		await process_frame
		await create_timer(0.0).timeout
		if mech.health == 0:
			break
	Input.action_release("move_left")
	var failures: Array[String] = []
	if not turned or mech.health != 0 or not actor.get_node("Sprite").flip_h:
		failures.append("fixture did not turn before real winning projectile collision")
	var sprite := actor.get_node("Sprite") as Sprite2D
	var barrel := actor.global_position + Vector2(-31, -24)
	var flashes := 0
	for child in current_scene.find_children("*", "Sprite2D", true, false):
		if child.get_script() == load("res://scripts/combat_flash.gd") and child.frame in range(12, 16) \
				and child.is_visible_in_tree():
			flashes += 1
			if child.global_position.distance_to(barrel) > 1.0 or child.global_transform.x.x >= 0:
				failures.append("victory froze muzzle away from visible turned gun")
	if flashes == 0 or sprite.frame not in [1, 2]:
		failures.append("fixture lacks visible running muzzle at victory")
	current_scene.queue_free()
	await process_frame
	await process_frame
	OS.delay_msec(150)
	for failure in failures:
		print("FAIL: ", failure)
	if failures.is_empty():
		print("PASS: 真实弹丸获胜前变向，冻结枪口仍对齐当前枪形")
	quit(0 if failures.is_empty() else 1)
