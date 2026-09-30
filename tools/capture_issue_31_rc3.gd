extends "res://tools/capture_issue_31.gd"
## Legal Input run is separate from disclosed visibility-only corpse fixtures.

var rc_out := ""
var layers: Array[Dictionary] = []
var frame_samples: Array[Dictionary] = []


func _initialize() -> void:
	Engine.physics_ticks_per_second = 60
	process_frame.connect(func() -> void: OS.delay_msec(17))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			rc_out = arg.trim_prefix("--out=")
	call_deferred("_run")


func _run() -> void:
	if rc_out.is_empty() or DisplayServer.get_name() == "headless":
		print("FAIL: graphical rendering and explicit --out are required")
		quit(1)
		return
	root.size = Vector2i(640, 360)
	root.content_scale_size = Vector2i(640, 360)
	DirAccess.make_dir_recursive_absolute(rc_out + "/frames/legal-run")
	await _simulate()
	await _new_level()
	var actor := current_scene.get_node("Operative/Operative") as CharacterBody2D
	var soldier := current_scene.get_node("Enemies/SoloSoldier") as MechanicalSoldier
	actor.global_position = soldier.global_position
	for hit in soldier.health:
		soldier.receive_hit()
	await _step()
	await _layer_set("soldier-standing", actor, soldier)
	actor.global_position.x += 24
	await _layer_set("soldier-moving-right", actor, soldier)
	actor.get_node("Sprite").flip_h = true
	await _layer_set("soldier-moving-left", actor, soldier)
	await _new_level()
	actor = current_scene.get_node("Operative/Operative") as CharacterBody2D
	var mech := current_scene.get_node("BossSlot/DefenseMech") as DefenseMech
	actor.position = Vector2(3700, 252)
	for tick in 4:
		await _step()
	for hit in mech.health:
		mech.receive_hit()
	await _step()
	actor.global_position = mech.global_position
	await _layer_set("mech-victory", actor, mech)
	var report := {"engine": Engine.get_version_info().string,
		"native_size": [640, 360], "physics_hz": 60, "fixed_fps": 60,
		"wall_clock_pacing": "process_frame OS.delay_msec(17)",
		"disclosure": "Legal-run: normal spawn, only Input, physical R. Layers: initial actor teleport/public enemy.receive_hit; pause/freeze camera and Sprite frame 0 or 1 only for component visibility renders. Mech-victory layers use direct public hits and actor teleport after victory; true winning projectile separately captured by rc3_outcomes at 120Hz/30fps. Neither fixtures nor simulated mech timing are new human acceptance.",
		"sequences": records, "layers": layers, "frame_samples": frame_samples,
		"failures": failures}
	var file := FileAccess.open(rc_out + "/capture-results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	_release()
	current_scene.queue_free()
	await process_frame
	await process_frame
	OS.delay_msec(150)
	for failure in failures:
		print("FAIL: ", failure)
	print("PASS: RC3 legal Input completion/R and corpse pixel layers" if failures.is_empty()
		else "FAIL: RC3 integrated capture")
	quit(0 if failures.is_empty() else 1)


func _step() -> void:
	await physics_frame
	await process_frame
	await create_timer(0.0).timeout


func _frame(sequence: String, tick: int) -> void:
	await RenderingServer.frame_post_draw
	frame_samples.append({"sequence": sequence, "tick": tick,
		"physics_frame": Engine.get_physics_frames()})
	var image := root.get_texture().get_image()
	_check(image.get_size() == Vector2i(640, 360), "non-native viewport")
	_check(image.save_png(rc_out + "/frames/" + sequence + "/%04d.png" % tick) == OK,
		"frame save failed")


func _state() -> Dictionary:
	var actor := current_scene.get_node("Operative/Operative") as CharacterBody2D
	var mech := current_scene.get_node("BossSlot/DefenseMech") as DefenseMech
	return {"physics_frame": Engine.get_physics_frames(), "actor_x": actor.position.x,
		"actor_y": actor.position.y, "actor_health": actor.health, "on_floor": actor.is_on_floor(),
		"mech_health": mech.health, "mech_visible": mech.attack_enabled,
		"enemy_shots": enemy_shots, "player_shots": player_shots, "charges": charges,
		"gate_frame": current_scene.get_node("CombatEntry/Artwork").frame,
		"gate_closed": not current_scene.get_node("CombatEntry/Barrier/CollisionShape2D").disabled,
		"camera_x": current_scene.get_node("Camera2D").position.x,
		"outcome": current_scene.get_node("HUD/OutcomePanel").visible,
		"reason": current_scene.get_node("HUD/OutcomePanel/ReasonLabel").text}


func _save(name: String, frame_ready: bool = false) -> void:
	if not frame_ready:
		await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(rc_out + "/" + name + ".png") == OK,
		"snapshot save failed")


func _layer_set(name: String, actor: CharacterBody2D, enemy: Node2D) -> void:
	var actor_sprite := actor.get_node("Sprite") as Sprite2D
	var corpse_sprite := enemy.get_node("Sprite") as Sprite2D
	var actor_physics := actor.is_physics_processing()
	current_scene.set_process(false)
	actor.set_physics_process(false)
	actor_sprite.frame = 1 if name.begins_with("soldier-moving") else 0
	var camera := current_scene.get_node("Camera2D") as Camera2D
	camera.position.x = 3580 if name == "mech-victory" else actor.global_position.x + 115
	camera.force_update_scroll()
	paused = true
	for components in ["background", "corpse-only", "actor-only", "combined"]:
		actor_sprite.visible = components in ["actor-only", "combined"]
		corpse_sprite.visible = components in ["corpse-only", "combined"]
		await _save(name + "-" + components)
	layers.append({"name": name, "actor_z": actor_sprite.z_index,
		"corpse_z": corpse_sprite.z_index, "corpse_health": enemy.health,
		"corpse_position": [enemy.global_position.x, enemy.global_position.y],
		"pose": actor_sprite.frame, "left": actor_sprite.flip_h})
	_check(corpse_sprite.z_index == -1 and actor_sprite.z_index == 0,
		"merged corpse bands changed")
	actor.set_physics_process(actor_physics)
	current_scene.set_process(true)
	paused = false
