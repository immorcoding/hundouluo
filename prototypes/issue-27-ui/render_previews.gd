extends SceneTree

# Offline review renderer only. Existing scene rules drive all state captures.
const OUT := "res://prototypes/issue-27-ui/"
const UI := preload("res://prototypes/issue-27-ui/design_ui.gd")
const CASES := ["start", "hud", "low-health", "death", "fall", "complete", "life-two", "boss-full", "boss-one"]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	for state in CASES:
		var level := (load("res://scenes/level.tscn") as PackedScene).instantiate()
		root.add_child(level)
		var actor := level.get_node("Operative/Operative") as CharacterBody2D
		var mech := level.get_node("BossSlot/DefenseMech") as DefenseMech
		actor.position = Vector2(1250 if state in ["start", "fall"] else 3500, 252)
		actor.invulnerability_duration = 0.0
		for tick in 4:
			await physics_frame
		if state not in ["start", "fall", "boss-full"]:
			for hit in (119 if state == "boss-one" else 42):
				mech.receive_hit()
		if state in ["low-health", "life-two"]:
			for hit in (2 if state == "low-health" else 1):
				actor.receive_hit()
		if state == "death":
			for hit in 3:
				actor.receive_hit()
		elif state == "complete":
			for hit in mech.health:
				mech.receive_hit()
		elif state == "fall":
			actor.position = Vector2(1392, 425)
			for tick in 3:
				await physics_frame
		elif state not in ["boss-one", "boss-full", "life-two"]:
			Input.action_press("shoot")
			for tick in 12:
				await physics_frame
			Input.action_release("shoot")
		level.process_mode = Node.PROCESS_MODE_DISABLED
		var show_boss: bool = level.get_node("HUD/MechProgress").visible
		level.get_node("HUD").hide()
		await process_frame
		await RenderingServer.frame_post_draw
		var boundary: bool = state in ["life-two", "boss-full", "boss-one"]
		if not _save(("boundaries/" if boundary else "captures/") + state + ("-raw.png" if boundary else ".png")):
			return
		var layer := CanvasLayer.new()
		layer.layer = 100
		root.add_child(layer)
		var ui := UI.new()
		ui.state = state
		ui.health = actor.health
		ui.boss_health = mech.health
		ui.boss_max = mech.max_health
		ui.show_boss = show_boss
		layer.add_child(ui)
		await process_frame
		await RenderingServer.frame_post_draw
		var directory := "boundaries/" if boundary else "previews/"
		if not _save(directory + state + ".png"):
			return
		# Integer nearest-neighbor export of our native Godot-rendered frame.
		var doubled := root.get_texture().get_image()
		doubled.resize(1280, 720, Image.INTERPOLATE_NEAREST)
		var doubled_path: String = "boundaries/" + state + "-2x.png" if boundary else "previews-2x/" + state + ".png"
		if doubled.save_png(OUT + doubled_path) != OK:
			quit(1)
			return
		print("CAPTURE ", state, " life=", actor.health, " mech=", mech.health, "/", mech.max_health, " boss-visible=", show_boss)
		layer.queue_free()
		level.queue_free()
		await process_frame
	quit(0)

func _save(relative_path: String) -> bool:
	var screenshot := root.get_texture().get_image()
	if screenshot.get_size() != Vector2i(640, 360):
		push_error("Review image must be exactly 640x360")
		quit(1)
		return false
	if screenshot.save_png(OUT + relative_path) != OK:
		push_error("Could not save " + relative_path)
		quit(1)
		return false
	return true
