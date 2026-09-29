extends SceneTree
## Two isolated 2D worlds share input and physics clock, not colliders.
## Only temporary CombatEntry instances translate; production files stay intact.

const ART := "res://art/entry_gate/b-left/"
const NAMES := ["left16", "left24"]
const POSITIONS := [3396.0, 3388.0]
const FRAME_COUNT := 150
var textures := {}
var shots := [0, 0]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(640, 360)
	for name in NAMES:
		var poses: Array[Texture2D] = []
		for state in ["open", "warning-0", "warning-1", "warning-2", "warning-3", "warning-4", "warning-5", "closed"]:
			var img := Image.load_from_file(ART + name + "/" + state + ".png")
			if img == null or img.get_size() != Vector2i(128, 288):
				push_error("Invalid B candidate asset")
				quit(1)
				return
			poses.append(ImageTexture.create_from_image(img))
		textures[name] = poses
		DirAccess.make_dir_recursive_absolute(ART + "frames/" + name)
	for sequence in ["entry", "cancel", "boundary", "walk", "jump"]:
		if not await _sequence(sequence):
			quit(1)
			return
	quit(0)


func _shot(_projectile: Area2D, index: int) -> void:
	shots[index] += 1


func _sequence(sequence: String) -> bool:
	var views: Array[SubViewport] = []
	var levels: Array[Node2D] = []
	var gates: Array[Sprite2D] = []
	var actors: Array[CharacterBody2D] = []
	var warnings := [-1, -1]
	var closures := [-1, -1]
	var min_top := [360.0, 360.0]
	shots = [0, 0]
	for i in 2:
		var view := SubViewport.new()
		view.size = Vector2i(640, 360)
		view.world_2d = World2D.new()
		view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(view)
		var level := (load("res://scenes/level.tscn") as PackedScene).instantiate() as Node2D
		view.add_child(level)
		level.get_node("Camera2D").make_current()
		var entry := level.get_node("CombatEntry") as Node2D
		entry.position.x = POSITIONS[i]
		entry.hide()
		var gate := Sprite2D.new()
		gate.position = Vector2(POSITIONS[i], 144)
		gate.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		level.add_child(gate)
		level.move_child(gate, level.get_node("Operative").get_index())
		var actor := level.get_node("Operative/Operative") as CharacterBody2D
		actor.position = Vector2(3462, 252)
		level.get_node("BossSlot/DefenseMech").projectile_fired.connect(_shot.bind(i))
		views.append(view)
		levels.append(level)
		gates.append(gate)
		actors.append(actor)
	var passage := sequence == "walk" or sequence == "jump"
	for tick in FRAME_COUNT:
		if tick == 30:
			if passage:
				Input.action_press("move_left")
			else:
				for actor in actors:
					actor.position.x = 3464
		if tick == 35 and sequence == "jump":
			Input.action_press("jump")
		if tick == 36:
			Input.action_release("jump")
		if tick == 38 and sequence == "cancel":
			Input.action_press("move_left")
		if sequence == "cancel" and actors[0].position.x < 3463:
			Input.action_release("move_left")
		if tick == 60 and sequence == "boundary":
			Input.action_press("move_left")
		if tick == 65 and sequence == "entry":
			Input.action_press("shoot")
		if tick == 75 and passage:
			Input.action_release("move_left")
		if tick == 102:
			Input.action_release("move_left")
			Input.action_release("shoot")
		await physics_frame
		await process_frame
		for i in 2:
			var remaining: float = levels[i].get("_entry_warning_remaining")
			var closed: bool = not levels[i].get_node("CombatEntry/Barrier/CollisionShape2D").disabled
			var pose := 0
			if closed:
				pose = 7
				if closures[i] < 0:
					closures[i] = tick
			elif remaining >= 0.0:
				pose = 1 + clampi(int((1.0 - remaining / 0.22) * 6.0), 0, 5)
				if warnings[i] < 0:
					warnings[i] = tick
			gates[i].texture = textures[NAMES[i]][pose]
			var sprite := actors[i].get_node("Sprite") as Sprite2D
			min_top[i] = minf(min_top[i], sprite.global_position.y + sprite.get_rect().position.y)
		await RenderingServer.frame_post_draw
		for i in 2:
			var img := views[i].get_texture().get_image()
			if img.save_png(ART + "frames/" + NAMES[i] + "/" + sequence + "-%03d.png" % tick) != OK:
				return false
			var state := ""
			if tick == 20:
				state = "open"
			elif warnings[i] >= 0 and tick == warnings[i] + (5 if sequence == "cancel" else 8):
				state = "warning"
			elif closures[i] >= 0 and tick == closures[i] + 4:
				state = "closed"
			elif tick == 125:
				state = "late"
			elif passage and tick == 51:
				state = "crossing"
			if not state.is_empty():
				if img.save_png(ART + NAMES[i] + "/" + sequence + "-" + state + ".png") != OK:
					return false
	for i in 2:
		var mech := levels[i].get_node("BossSlot/DefenseMech") as DefenseMech
		var distance := mech.global_position.x - actors[i].global_position.x
		if not passage and warnings[i] < 0:
			return false
		if (passage or sequence == "cancel") and closures[i] >= 0:
			return false
		if not passage and sequence != "cancel" and closures[i] < 0:
			return false
		if sequence == "boundary" and absf(actors[i].position.x - POSITIONS[i] - 19.075) > 0.2:
			return false
		if passage and (actors[i].position.x >= POSITIONS[i] - 64 or min_top[i] < 104):
			return false
		print(sequence, " ", NAMES[i], " warning=", warnings[i], " closed=", closures[i],
			" actor_x=", actors[i].position.x, " distance=", distance,
			" mech_shots=", shots[i], " fully_visible=", mech.attack_enabled,
			" min_sprite_y=", min_top[i])
	if sequence == "boundary" and (shots[0] == 0 or shots[1] != 0):
		push_error("Unexpected candidate range result; inspect before reporting")
		return false
	Input.action_release("move_left")
	Input.action_release("shoot")
	Input.action_release("jump")
	for view in views:
		view.queue_free()
	await process_frame
	await process_frame
	return true
