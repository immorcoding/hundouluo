extends SceneTree
## Paired real-level screenshots. Measurement pauses preserve the identical pose.

var out := "res://.scratch/issue-36/loop"
var ticks := 2
var movement := false
var shooting := true
var failures: Array[String] = []
var probe := "none"
var scenario := "spawn"
var full := false
var paired := true
var emitted: Array[Area2D] = []


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
		elif arg.begins_with("--ticks="):
			ticks = arg.trim_prefix("--ticks=").to_int()
		elif arg == "--move":
			movement = true
		elif arg == "--no-shot":
			shooting = false
		elif arg.begins_with("--probe="):
			probe = arg.trim_prefix("--probe=")
		elif arg.begins_with("--scenario="):
			scenario = arg.trim_prefix("--scenario=")
		elif arg == "--full":
			full = true
		elif arg == "--raw":
			paired = false
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("FAIL: this pixel regression requires actual graphical rendering")
		quit(1)
		return
	root.size = Vector2i(640, 360)
	root.content_scale_size = Vector2i(640, 360)
	DirAccess.make_dir_recursive_absolute(out + "/frames")
	change_scene_to_file("res://scenes/level.tscn")
	await process_frame
	await process_frame
	var actor := current_scene.get_node("Operative/Operative") as CharacterBody2D
	var sprite := actor.get_node("Sprite") as Sprite2D
	if scenario == "follow":
		actor.position = Vector2(470, 252)
	elif scenario == "fixed":
		actor.position = Vector2(3462, 252)
		Input.action_press("move_right")
		await _step()
		Input.action_release("move_right")
		for tick in 40:
			await _step()
	actor.projectile_fired.connect(func(projectile: Area2D) -> void:
		emitted.append(projectile)
		if probe == "no-projectile":
			projectile.hide()
		for node in actor.find_children("*", "Sprite2D", true, false):
			if node.get_script() == load("res://scripts/combat_flash.gd"):
				if probe == "behind":
					node.z_index = -1
				elif probe == "shift":
					node.position.x = 6
	)
	if shooting:
		Input.action_press("shoot")
	if movement:
		Input.action_press("move_right")
	var trace: Array[Dictionary] = []
	for tick in ticks:
		if full:
			_inputs(tick, actor)
		await _step()
		trace.append(await _capture_pair(actor, tick))
	var samples := 0
	var poses := {}
	for record in trace:
		samples += record.get("flash_count", 0)
		poses[str(record.pose) + ":" + str(record.flip)] = true
	if paired and shooting and samples == 0:
		failures.append("normal shoot Input did not produce any visible muzzle effect")
	if full:
		for key in ["0:false", "0:true", "3:false", "3:true", "5:true", "5:false"]:
			if not poses.has(key):
				failures.append("missing exercised pose " + key)
		if not actor.is_on_floor():
			failures.append("normal Input jump did not land")
	for action in ["shoot", "move_right", "move_left", "jump"]:
		Input.action_release(action)
	var file := FileAccess.open(out + "/trace.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(trace, "\t") + "\n")
	current_scene.queue_free()
	await process_frame
	await process_frame
	OS.delay_msec(150)
	for failure in failures:
		print("FAIL: ", failure)
	if failures.is_empty():
		print("PASS: visible muzzle attachment and stable gun pixels" if paired else "PASS: native unpaused Input loop")
	quit(0 if failures.is_empty() else 1)


func _capture_pair(actor: CharacterBody2D, tick: int) -> Dictionary:
	var sprite := actor.get_node("Sprite") as Sprite2D
	await RenderingServer.frame_post_draw
	var record := {"tick": tick, "pose": sprite.frame, "flip": sprite.flip_h,
		"sprite_origin": _xy(sprite.get_global_transform_with_canvas().origin)}
	var on := root.get_texture().get_image()
	if on.get_size() != Vector2i(640, 360) or on.save_png(out + "/frames/%03d-on.png" % tick) != OK:
		failures.append("native capture failed")
	if not paired:
		return record
	paused = true
	var flashes: Array[Sprite2D] = []
	var projectiles: Array[Area2D] = []
	for node in actor.find_children("*", "Sprite2D", true, false):
		if node.get_script() == load("res://scripts/combat_flash.gd") and node.is_visible_in_tree():
			flashes.append(node)
			node.hide()
	for projectile in emitted:
		if is_instance_valid(projectile) and projectile.is_visible_in_tree():
			projectiles.append(projectile)
			projectile.hide()
	await process_frame
	await RenderingServer.frame_post_draw
	var off := root.get_texture().get_image()
	if off.get_size() != Vector2i(640, 360) or off.save_png(out + "/frames/%03d-off.png" % tick) != OK:
		failures.append("native paired capture failed")
	if record.sprite_origin != _xy(sprite.get_global_transform_with_canvas().origin) or record.pose != sprite.frame:
		failures.append("paired pose moved during paused measurement")
	record["flash_count"] = flashes.size()
	record["projectile_count"] = projectiles.size()
	if not flashes.is_empty():
		_check_pixels(on, off, sprite, record)
	for node in flashes:
		node.show()
	for projectile in projectiles:
		projectile.show()
	paused = false
	return record


func _check_pixels(on: Image, off: Image, sprite: Sprite2D, record: Dictionary) -> void:
	# Independently inspected approved 72x60 sprite cells. These are source
	# pixel coordinates, not production muzzle_offsets or its calculations.
	var tips := [Vector2i(64, 22), Vector2i(67, 24), Vector2i(67, 24),
		Vector2i(59, 23), Vector2i(57, 23), Vector2i(62, 20)]
	var guns := [Rect2i(49, 19, 15, 7), Rect2i(51, 20, 16, 8),
		Rect2i(51, 20, 16, 8), Rect2i(46, 19, 13, 8),
		Rect2i(46, 19, 11, 8), Rect2i(49, 17, 13, 8)]
	var tip: Vector2i = tips[sprite.frame]
	var gun: Rect2i = guns[sprite.frame]
	var direction := -1 if sprite.flip_h else 1
	var artwork := sprite.texture.get_image()
	# Register the mask against the actual no-feedback sprite, independently of
	# Godot's half-pixel/tie handling. Search only the four adjacent raster cells.
	var raster_origin := _register_mask(off, sprite, gun, artwork)
	record["raster_origin"] = _xy(Vector2(raster_origin))
	var tip_screen := raster_origin + _source_pixel_offset(tip, sprite.flip_h)
	var changed := 0
	var rear := 1000
	var mask_pixels := 0
	var source_matches := 0
	var opaque_pixels := 0
	for y in range(gun.position.y, gun.end.y):
		for x in range(gun.position.x, gun.end.x):
			if artwork.get_pixel(sprite.frame * 72 + x, y).a < 0.99:
				continue
			var screen := raster_origin + _source_pixel_offset(Vector2i(x, y), sprite.flip_h)
			mask_pixels += 1
			var source := artwork.get_pixel(sprite.frame * 72 + x, y)
			if source.a == 1.0:
				opaque_pixels += 1
				var actual := off.get_pixelv(screen)
				if maxf(absf(actual.r - source.r), maxf(absf(actual.g - source.g), absf(actual.b - source.b))) < 0.005:
					source_matches += 1
			if on.get_pixelv(screen) != off.get_pixelv(screen):
				changed += 1
	for y in range(-6, 7):
		for x in range(-12, 17):
			var screen := tip_screen + Vector2i(direction * x, y)
			var a := on.get_pixelv(screen)
			var b := off.get_pixelv(screen)
			if a != b:
				rear = mini(rear, x)
	record["changed_gun_pixels"] = changed
	record["mask_pixels"] = mask_pixels
	record["source_matches"] = source_matches
	record["opaque_pixels"] = opaque_pixels
	if sprite.modulate == Color.WHITE and not current_scene.get_node("HUD/OutcomePanel").visible \
			and source_matches < opaque_pixels * 0.9:
		failures.append("independent gun mask does not match actual sprite pixels")
	record["visible_rear_error_px"] = rear
	if changed != 0:
		failures.append("tick%d gun body changed %d pixels" % [record.tick, changed])
	if absi(rear) > 1:
		failures.append("tick%d visible flash rear misses barrel edge by %dpx" % [record.tick, rear])


func _register_mask(off: Image, sprite: Sprite2D, gun: Rect2i, artwork: Image) -> Vector2i:
	var origin := sprite.get_global_transform_with_canvas().origin
	var best := Vector2i(origin.round())
	var best_error := INF
	for cy in [floori(origin.y), ceili(origin.y)]:
		for cx in [floori(origin.x), ceili(origin.x)]:
			var error := 0.0
			for y in range(gun.position.y, gun.end.y):
				for x in range(gun.position.x, gun.end.x):
					var source := artwork.get_pixel(sprite.frame * 72 + x, y)
					if source.a != 1.0:
						continue
					var screen := Vector2i(cx, cy) + _source_pixel_offset(Vector2i(x, y), sprite.flip_h)
					var actual := off.get_pixelv(screen)
					var expected := source * sprite.modulate
					error += absf(actual.r - expected.r) + absf(actual.g - expected.g) + absf(actual.b - expected.b)
			if error < best_error:
				best_error = error
				best = Vector2i(cx, cy)
	return best


func _source_pixel_offset(point: Vector2i, mirrored: bool) -> Vector2i:
	return Vector2i(35 - point.x if mirrored else point.x - 36, point.y - 30)


func _step() -> void:
	await physics_frame
	await process_frame
	await create_timer(0.0).timeout


func _inputs(tick: int, actor: CharacterBody2D) -> void:
	if tick == 5:
		Input.action_press("move_right")
	elif tick == 20:
		Input.action_press("jump")
	elif tick == 21:
		Input.action_release("jump")
	elif tick == 45:
		Input.action_release("move_right")
		Input.action_press("move_left")
	elif tick == 65:
		Input.action_press("jump")
	elif tick == 66:
		Input.action_release("jump")
	elif tick == 95:
		Input.action_release("move_left")
	elif tick == 125:
		actor.receive_hit()
	elif tick == 130:
		Input.action_press("move_right")
	elif tick == 145:
		Input.action_release("move_right")
		Input.action_press("move_left")
	elif tick == 155:
		Input.action_release("move_left")


func _xy(point: Vector2) -> Array:
	return [point.x, point.y]
