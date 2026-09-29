extends SceneTree
## #32 throwaway A/B art fixture. The saved level and its collider are untouched.
## Only this temporary instance translates CombatEntry together with its art.

const ART := "res://art/entry_gate/ab/"
const CANDIDATE_X := 3412.0
const FRAMES := 150
var poses := {}
var level: Node2D
var gate: Sprite2D


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	root.size = Vector2i(640, 360)
	for variant in ["A", "B"]:
		var textures: Array[Texture2D] = []
		for name in ["open", "warning-0", "warning-1", "warning-2", "warning-3", "warning-4", "warning-5", "closed"]:
			var img := Image.load_from_file(ART + variant + "/" + name + ".png")
			if img == null or img.get_size() != Vector2i(128, 288):
				push_error("Invalid A/B asset: " + variant + "/" + name)
				quit(1)
				return
			textures.append(ImageTexture.create_from_image(img))
		poses[variant] = textures
		DirAccess.make_dir_recursive_absolute(ART + "capture-frames/" + variant)
	for sequence in ["entry", "cancel", "boundary", "passage-walk", "passage-jump"]:
		if not await _sequence(sequence):
			quit(1)
			return
	quit(0)


func _sequence(sequence: String) -> bool:
	level = (load("res://scenes/level.tscn") as PackedScene).instantiate()
	root.add_child(level)
	var actor := level.get_node("Operative/Operative") as CharacterBody2D
	var entry := level.get_node("CombatEntry") as Node2D
	# The candidate's visible shutter and existing 14x148 temporary collider
	# move as one. Commit/cancel x=3463, warning 0.22, camera min=3580 stay original.
	entry.position.x = CANDIDATE_X
	entry.hide()
	gate = Sprite2D.new()
	gate.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	gate.position = Vector2(CANDIDATE_X, 144)
	level.add_child(gate)
	level.move_child(gate, level.get_node("Operative").get_index())
	actor.position = Vector2(3462, 252)
	actor.velocity = Vector2.ZERO
	var warning_frame := -1
	var closed_frame := -1
	var passage := sequence.begins_with("passage-")
	var min_sprite_top := 360.0
	for tick in FRAMES:
		if tick == 30 and not passage:
			actor.position.x = 3464
		if tick == 30 and passage:
			Input.action_press("move_left")
		if tick == 35 and sequence == "passage-jump":
			Input.action_press("jump")
		if tick == 36:
			Input.action_release("jump")
		if passage and tick == 65:
			Input.action_release("move_left")
		if sequence == "cancel" and tick == 38:
			Input.action_press("move_left")
		if sequence == "cancel" and actor.position.x < 3463:
			Input.action_release("move_left")
		if sequence == "entry" and tick == 65:
			Input.action_press("shoot")
		if sequence == "boundary" and tick == 60:
			Input.action_press("move_left")
		if tick == 102:
			Input.action_release("shoot")
			Input.action_release("move_left")
		await physics_frame
		await process_frame
		# Let the original level's process callback update its follow camera
		# before freezing; pausing at process_frame would suppress that callback.
		await RenderingServer.frame_post_draw
		var actor_sprite := actor.get_node("Sprite") as Sprite2D
		min_sprite_top = minf(min_sprite_top, actor_sprite.global_position.y + actor_sprite.get_rect().position.y)
		var remaining: float = level.get("_entry_warning_remaining")
		var closed: bool = not entry.get_node("Barrier/CollisionShape2D").disabled
		var pose := 0
		if closed:
			pose = 7
			if closed_frame < 0:
				closed_frame = tick
		elif remaining >= 0.0:
			pose = 1 + clampi(int((1.0 - remaining / 0.22) * 6.0), 0, 5)
			if warning_frame < 0:
				warning_frame = tick
		# Freeze one simulation instant and render both variants. Camera, sprite
		# poses, projectiles and warning readout are pixel-identical outside art.
		paused = true
		for variant in ["A", "B"]:
			gate.texture = poses[variant][pose]
			await RenderingServer.frame_post_draw
			var img := root.get_texture().get_image()
			if img.get_size() != Vector2i(640, 360) or img.save_png(ART + "capture-frames/" + variant + "/" + sequence + "-%03d.png" % tick) != OK:
				push_error("A/B viewport save failed")
				paused = false
				return false
			var name := ""
			if tick == 20:
				name = "open"
			elif warning_frame >= 0 and tick == warning_frame + (5 if sequence == "cancel" else 8):
				name = "warning"
			elif closed_frame >= 0 and tick == closed_frame + 4:
				name = "closed"
			elif tick == 110:
				name = "late"
			elif passage and tick == 46:
				name = "crossing"
			if not name.is_empty():
				if img.save_png(ART + variant + "/" + sequence + "-" + name + ".png") != OK:
					paused = false
					return false
		paused = false
	if (not passage and warning_frame < 0) or ((sequence == "cancel" or passage) and closed_frame >= 0) or (not passage and sequence != "cancel" and closed_frame < 0):
		push_error("Unexpected candidate sequence: " + sequence)
		return false
	if sequence == "boundary" and absf(actor.position.x - 3431.075) > 0.2:
		push_error("Candidate collider does not match the translated art")
		return false
	if passage and (actor.position.x >= CANDIDATE_X - 64 or min_sprite_top < 104):
		push_error("Open candidate passage is not visually clear")
		return false
	print(sequence, ": warning=", warning_frame, " closed=", closed_frame,
		" actor_x=", actor.position.x, " gate_x=", entry.position.x,
		" camera_x=", level.get_node("Camera2D").position.x, " sprite_min_y=", min_sprite_top)
	Input.action_release("shoot")
	Input.action_release("move_left")
	level.queue_free()
	await process_frame
	await process_frame
	return true
