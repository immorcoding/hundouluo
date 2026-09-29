extends SceneTree
## Review-only #32 viewport capture. Never installed into the production scene.
## Observe the actual #28 timer/collider; do not drive either from animation.

const ART := "res://art/entry_gate/"
var poses: Array[Texture2D] = []
var level: Node2D
var gate: Sprite2D
var output := "res://art/entry_gate/capture-frames/"


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	root.size = Vector2i(640, 360)
	DirAccess.make_dir_recursive_absolute(output)
	for file in ["open", "warning-0", "warning-1", "warning-2", "warning-3",
			"warning-4", "warning-5", "closed"]:
		var img := Image.load_from_file(ART + file + ".png")
		if img == null or img.get_size() != Vector2i(96, 252):
			push_error("Missing/invalid gate art: " + file)
			quit(1)
			return
		poses.append(ImageTexture.create_from_image(img))
	await _sequence(false)
	await _sequence(true)
	await _sequence(false, true)
	quit(0)


func _sequence(boundary: bool, retreat := false) -> void:
	level = (load("res://scenes/level.tscn") as PackedScene).instantiate()
	root.add_child(level)
	var actor := level.get_node("Operative/Operative") as CharacterBody2D
	# Suppress only the old marker/shutter drawings on this temporary instance.
	level.get_node("CombatEntry").hide()
	gate = Sprite2D.new()
	gate.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Frame pivot (64,252) aligns the 14px moving leaf to (3444,252).
	gate.position = Vector2(3428, 126)
	level.add_child(gate)
	# Draw behind the operative, mech and projectiles, above the existing deck.
	level.move_child(gate, level.get_node("Operative").get_index())
	actor.position = Vector2(3462, 252)
	actor.velocity = Vector2.ZERO
	var closed_frame := -1
	var warning_frame := -1
	var prefix := "retreat" if retreat else "boundary" if boundary else "scene"
	for tick in 132:
		if tick == 30:
			actor.position.x = 3464 if boundary or retreat else 3510
		if tick == 38 and retreat:
			Input.action_press("move_left")
		if retreat and actor.position.x < 3463:
			Input.action_release("move_left")
		if tick == 65 and not boundary and not retreat:
			Input.action_press("shoot")
		if tick == 92:
			Input.action_release("shoot")
		if boundary and tick == 65:
			Input.action_press("move_left")
		if tick == 90:
			Input.action_release("move_left")
		await physics_frame
		await process_frame
		var remaining: float = level.get("_entry_warning_remaining")
		var closed: bool = not level.get_node("CombatEntry/Barrier/CollisionShape2D").disabled
		var pose := 0
		if closed:
			pose = 7
			if closed_frame < 0:
				closed_frame = tick
		elif remaining >= 0.0:
			pose = 1 + clampi(int((1.0 - remaining / 0.22) * 6.0), 0, 5)
			if warning_frame < 0:
				warning_frame = tick
		gate.texture = poses[pose]
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		if img.get_size() != Vector2i(640, 360) or img.save_png(output + prefix + "-%03d.png" % tick) != OK:
			push_error("Native viewport capture failed")
			quit(1)
			return
		if tick == 20 or (warning_frame >= 0 and tick == warning_frame + 5) or (closed_frame >= 0 and tick == closed_frame + 4) or tick == 88:
			var name := "open" if tick == 20 else "warning" if tick == warning_frame + 5 else "closed" if tick == closed_frame + 4 else "combat"
			img.save_png(ART + prefix + "-" + name + ".png")
		if tick == 50 and not boundary and not retreat:
			# Same rendered pose/camera, only exchange the two visual treatments.
			# Pause the temporary level for this additional reference-only render.
			paused = true
			gate.hide()
			level.get_node("CombatEntry").show()
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(ART + "baseline-closed.png")
			level.get_node("CombatEntry").hide()
			gate.show()
			paused = false
		if retreat and tick == 48:
			img.save_png(ART + "retreat-cancelled.png")
	if warning_frame < 0 or (retreat and closed_frame >= 0) or (not retreat and closed_frame < 0):
		push_error("Unexpected real entry state sequence: " + prefix)
		quit(1)
		return
	var elapsed := str((closed_frame - warning_frame) / 60.0) if closed_frame >= 0 else "cancelled"
	print(prefix, ": warning frame=", warning_frame, " closed frame=", closed_frame,
		" elapsed=", elapsed, " actor x=", actor.position.x)
	Input.action_release("shoot")
	Input.action_release("move_left")
	level.queue_free()
	await process_frame
