extends SceneTree
## Production level/input capture. The approved source is only a visual oracle.

const OUT := "res://docs/art/issue-33/"
const APPROVED := "res://art/entry_gate/b-left/left16/"
var records: Array[Dictionary] = []
var comparisons: Array[Dictionary] = []
var enemy_shots := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(640, 360)
	root.content_scale_size = Vector2i(640, 360)
	DirAccess.make_dir_recursive_absolute(OUT + "frames")
	for sequence in ["entry", "cancel", "boundary", "walk", "jump", "advance"]:
		await _sequence(sequence)
	await _outcomes()
	var file := FileAccess.open(OUT + "capture-results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"sequences": records, "approved_comparisons": comparisons}, "\t") + "\n")
	current_scene.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	call_deferred("_finish")


func _new_level() -> void:
	change_scene_to_file("res://scenes/level.tscn")
	await process_frame
	await process_frame
	enemy_shots = 0
	current_scene.get_node("BossSlot/DefenseMech").projectile_fired.connect(
		func(_projectile: Area2D) -> void: enemy_shots += 1)


func _step() -> void:
	await physics_frame
	await process_frame


func _sequence(sequence: String) -> void:
	await _new_level()
	var level := current_scene
	var actor := level.get_node("Operative/Operative") as CharacterBody2D
	var artwork := level.get_node("CombatEntry/Artwork") as Sprite2D
	var barrier := level.get_node("CombatEntry/Barrier/CollisionShape2D") as CollisionShape2D
	var passage := sequence == "walk" or sequence == "jump"
	actor.position = Vector2(3330 if passage else 3462, 252)
	var warning := -1
	var closure := -1
	var frame_count := 450 if sequence == "boundary" else 150
	for tick in frame_count:
		if tick == 30:
			Input.action_press("move_right")
			if sequence == "jump":
				Input.action_press("jump")
		if tick == 31:
			Input.action_release("jump")
			if not passage and sequence != "advance":
				Input.action_release("move_right")
		if passage and tick == 61:
			Input.action_release("move_right")
		if tick == 38 and sequence == "cancel":
			Input.action_press("move_left")
		if sequence == "cancel" and actor.position.x < 3463:
			Input.action_release("move_left")
		if tick == 60 and sequence == "boundary":
			Input.action_press("move_left")
		if tick == 102:
			Input.action_release("move_left")
		if tick == 65 and sequence == "entry":
			Input.action_press("shoot")
		if tick == 105:
			Input.action_release("shoot")
			Input.action_release("move_right")
		if tick == 282 and sequence == "boundary":
			Input.action_press("move_right")
			Input.action_press("shoot")
		if tick == 283 and sequence == "boundary":
			Input.action_release("move_right")
			Input.action_release("shoot")
			Input.action_press("move_left")
		if tick == 284 and sequence == "boundary":
			Input.action_release("move_left")
		await _step()
		if warning < 0 and artwork.frame in range(1, 7):
			warning = tick
		if closure < 0 and not barrier.disabled:
			closure = tick
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT + "frames/" + sequence + "-%03d.png" % tick)
		var state := ""
		if tick == 20:
			state = "open"
		elif warning >= 0 and tick == warning + 8:
			state = "warning"
		elif closure >= 0 and tick == closure + 4:
			state = "closed"
		elif passage and tick == 50:
			state = "crossing"
		elif tick == 125:
			state = "late"
		elif sequence == "boundary" and tick == 275:
			state = "rest-hit"
		elif sequence == "boundary" and tick == 430:
			state = "peek-hit"
		if not state.is_empty():
			await _save(sequence + "-" + state, sequence == "entry")
	var mech := level.get_node("BossSlot/DefenseMech") as DefenseMech
	records.append({"sequence": sequence, "frames": frame_count, "fps": 60,
		"warning_frame": warning, "closure_frame": closure, "actor_x": actor.position.x,
		"actor_health": actor.health, "mech_health": mech.health, "enemy_shots": enemy_shots,
		"camera_x": level.get_node("Camera2D").position.x, "mech_visible": mech.attack_enabled})
	print("CAPTURE ", records[-1])
	for action in ["move_left", "move_right", "jump", "shoot"]:
		Input.action_release(action)


func _outcomes() -> void:
	for outcome in ["death", "complete", "fall"]:
		await _new_level()
		var actor := current_scene.get_node("Operative/Operative") as CharacterBody2D
		actor.position = Vector2(3464, 252)
		for tick in 30:
			await _step()
		if outcome == "death":
			actor.invulnerability_duration = 0.0
			for hit in actor.health:
				actor.receive_hit()
		elif outcome == "complete":
			var mech := current_scene.get_node("BossSlot/DefenseMech") as DefenseMech
			for hit in mech.health:
				mech.receive_hit()
		else:
			await _new_level()
			current_scene.get_node("Operative/Operative").position = Vector2(1392, 425)
			for tick in 3:
				await _step()
		await _save(outcome)
		var event := InputEventKey.new()
		event.physical_keycode = KEY_R
		event.pressed = true
		Input.parse_input_event(event)
		await process_frame
		await process_frame
		event.pressed = false
		Input.parse_input_event(event)
		await _step()
		await _save("retry-" + outcome)


func _save(name: String, compare: bool = false) -> void:
	var level := current_scene
	level.process_mode = Node.PROCESS_MODE_DISABLED
	await process_frame
	await RenderingServer.frame_post_draw
	var actual := root.get_texture().get_image()
	actual.save_png(OUT + name + ".png")
	if compare:
		var artwork := level.get_node("CombatEntry/Artwork") as Sprite2D
		var frame := artwork.frame
		var texture := artwork.texture
		var state := "open" if frame == 0 else "closed" if frame == 7 else "warning-%d" % (frame - 1)
		artwork.texture = ImageTexture.create_from_image(Image.load_from_file(APPROVED + state + ".png"))
		artwork.hframes = 1
		artwork.frame = 0
		await process_frame
		await RenderingServer.frame_post_draw
		var expected := root.get_texture().get_image()
		expected.save_png(OUT + name + "-approved.png")
		var equal := actual.get_data() == expected.get_data()
		comparisons.append({"state": name, "source_pose": state, "pixels_identical": equal})
		artwork.texture = texture
		artwork.hframes = 8
		artwork.frame = frame
	level.process_mode = Node.PROCESS_MODE_INHERIT


func _finish() -> void:
	for comparison in comparisons:
		if not comparison.pixels_identical:
			push_error("Production gate differs from approved source: " + comparison.state)
			quit(1)
			return
	quit(0)
