extends SceneTree
# THROWAWAY capture harness. Run only inside the archived main snapshot.
func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	AudioServer.set_bus_mute(0, true)
	var destination := OS.get_cmdline_user_args()[0]
	var records: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(destination.path_join("states.json"))) if FileAccess.file_exists(destination.path_join("states.json")) else {}
	for state in ["normal", "low", "combat", "gap-left", "failure", "complete"]:
		# Preserve the established A/B samples; only capture missing states.
		if records.has(state) and FileAccess.file_exists(destination.path_join(state + ".png")):
			continue
		var level := (load("res://scenes/level.tscn") as PackedScene).instantiate()
		root.add_child(level)
		var actor := level.get_node("Operative/Operative")
		var mech := level.get_node("BossSlot/DefenseMech")
		actor.position = Vector2(900 if state == "normal" else (1460 if state == "gap-left" else 3510), 252)
		actor.invulnerability_duration = 0.0
		for tick in 24:
			await physics_frame
		if state not in ["normal", "gap-left"]:
			for hit in 14:
				mech.receive_hit()
		if state == "low":
			actor.receive_hit()
			actor.receive_hit()
		if state == "failure":
			for hit in 3:
				actor.receive_hit()
		elif state == "complete":
			for hit in mech.health:
				mech.receive_hit()
		else:
			Input.action_press("shoot")
			for tick in 10:
				await physics_frame
			Input.action_release("shoot")
		level.process_mode = Node.PROCESS_MODE_DISABLED
		level.get_node("HUD").hide()
		await process_frame
		await RenderingServer.frame_post_draw
		var frame := root.get_texture().get_image()
		assert(frame.get_size() == Vector2i(640, 360))
		assert(mech.max_health == 42)
		frame.save_png(destination.path_join(state + ".png"))
		records[state] = {"life": actor.health, "boss": mech.health, "max": mech.max_health, "boss_visible": level.get_node("HUD/MechProgress").visible}
		level.queue_free()
		await process_frame
	var file := FileAccess.open(destination.path_join("states.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(records, "\t") + "\n")
	file.close()
	print(records)
	quit()
