extends "res://tools/capture_issue_31.gd"
## Incremental merged-level evidence. Reuse the original legal Input run,
## redirect every output, and disclose fixture-only teleports/direct hits.

const RC_OUT := "res://docs/art/issue-31-rc2/"
const RAW := "res://.godot/issue31-rc2/frames/"
const BARRELS := [Vector2(28, -26), Vector2(31, -24), Vector2(31, -24),
	Vector2(23, -25), Vector2(21, -25), Vector2(26, -28)]
var traces: Array[Dictionary] = []
var layers: Array[Dictionary] = []
var flight: Array[Dictionary] = []


func _initialize() -> void:
	Engine.physics_ticks_per_second = 60
	process_frame.connect(func() -> void: OS.delay_msec(17))
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(640, 360)
	root.content_scale_size = Vector2i(640, 360)
	DirAccess.make_dir_recursive_absolute(RC_OUT)
	await _simulate()
	await _integrated("corpse-follow")
	await _integrated("gate-fixed")
	var file := FileAccess.open(RC_OUT + "capture-results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"engine": Engine.get_version_info().string,
		"native_size": [640, 360], "physics_hz": 60, "fixed_fps": 60,
		"wall_clock_pacing": "OS.delay_msec(17) each process_frame; APNG simulation rate 60 fps",
		"disclosure": "Legal run reuses capture_issue_31 Input-only normal spawn and R. Corpse fixture teleports to SoloSoldier and calls public receive_hit; fixed fixture teleports to (3462,252), then closes production gate with Input. Tick125 public operative.receive_hit forces hurt pose. Final mech fixture uses public receive_hit and teleports actor onto retained wreck after victory. Visibility-only component captures pause tree, freeze actor physics/level camera processing; two static running component fixtures additionally set public Sprite.frame=1/facing at corpse center after real Input motion. Gameplay rules/resources never changed. Simulated timing is not new human acceptance.",
		"sequences": records, "traces": traces, "layers": layers,
		"failures": failures}, "\t") + "\n")
	file.close()
	_release()
	current_scene.queue_free()
	await process_frame
	await process_frame
	OS.delay_msec(150)
	for failure in failures:
		push_error(failure)
	print("PASS: RC2 integrated capture" if failures.is_empty() else "FAIL: RC2 integrated capture")
	call_deferred("_finish")


func _step() -> void:
	await physics_frame
	await process_frame
	await create_timer(0.0).timeout


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


func _frame(sequence: String, tick: int) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_check(image.get_size() == Vector2i(640, 360), "non-native viewport")
	DirAccess.make_dir_recursive_absolute(RAW + sequence)
	_check(image.save_png(RAW + sequence + "/%04d.png" % tick) == OK, "frame save failed")


func _save(name: String, frame_ready: bool = false) -> void:
	if not frame_ready:
		await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(RC_OUT + name + ".png") == OK,
		"snapshot save failed")


func _integrated(sequence: String) -> void:
	await _new_level()
	flight.clear()
	var actor := current_scene.get_node("Operative/Operative") as CharacterBody2D
	var sprite := actor.get_node("Sprite") as Sprite2D
	var enemy := current_scene.get_node("Enemies/SoloSoldier") as MechanicalSoldier
	if sequence == "corpse-follow":
		actor.position = enemy.position
		for hit in enemy.health:
			enemy.receive_hit()
		await _step()
		await _layer_set("soldier-standing", actor, enemy)
		actor.position.x -= 64
	else:
		actor.position = Vector2(3462, 252)
		Input.action_press("move_right")
		await _step()
		Input.action_release("move_right")
		for tick in 40:
			await _step()
		_check(_state().gate_closed, "fixed camera fixture must close actual gate")
	actor.projectile_fired.connect(func(projectile: Area2D) -> void:
		var offset: Vector2 = BARRELS[sprite.frame]
		var barrel := actor.to_global(Vector2(-offset.x if sprite.flip_h else offset.x, offset.y))
		_check(projectile.global_position.distance_to(barrel) <= 1.0, "bullet birth missed visible barrel")
		flight.append({"node": projectile, "origin": projectile.global_position,
			"frame": Engine.get_physics_frames(), "direction": projectile.direction}))
	Input.action_press("shoot")
	var camera_samples: Array[float] = []
	var poses := {}
	var samples := 0
	for tick in 180:
		if tick == 5 or tick == 130:
			Input.action_press("move_right")
		elif tick == 45 or tick == 145:
			Input.action_release("move_right")
			Input.action_press("move_left")
		elif tick == 65:
			Input.action_press("jump")
		elif tick == 66:
			Input.action_release("jump")
		elif tick == 95 or tick == 155:
			Input.action_release("move_left")
		elif tick == 125:
			actor.receive_hit()
		await _step()
		await _frame(sequence, tick)
		var barrel := actor.to_global(Vector2(-BARRELS[sprite.frame].x if sprite.flip_h
			else BARRELS[sprite.frame].x, BARRELS[sprite.frame].y))
		var record := _state()
		record.merge({"sequence": sequence, "tick": tick, "pose": sprite.frame,
			"left": sprite.flip_h, "barrel": [barrel.x, barrel.y], "flashes": [], "flights": []})
		poses[str(sprite.frame) + ":" + str(sprite.flip_h)] = true
		camera_samples.append(record.camera_x)
		for child in current_scene.find_children("*", "Sprite2D", true, false):
			if child.get_script() == load("res://scripts/combat_flash.gd") and child.frame in range(12, 16) and child.is_visible_in_tree():
				var error: float = child.global_position.distance_to(barrel)
				_check(error <= 1.0, "visible muzzle detached at " + str(tick))
				record.flashes.append({"frame": child.frame, "barrel_error": error})
				samples += 1
		for item in flight:
			if not is_instance_valid(item.node) or item.node.is_queued_for_deletion():
				continue
			var elapsed := Engine.get_physics_frames() - int(item.frame)
			var expected: Vector2 = item.origin + Vector2(item.direction * elapsed * 520.0 / 60, 0)
			var error: float = item.node.global_position.distance_to(expected)
			_check(error < 0.05, "independent bullet flight changed")
			record.flights.append({"elapsed_ticks": elapsed, "error": error})
		traces.append(record)
		if tick in [13, 22, 64, 70, 125, 150]:
			await _save(sequence + "-%03d" % tick, true)
	_release()
	var result := _state()
	result.merge({"sequence": sequence, "frames": 180, "fps": 60,
		"camera_min": camera_samples.min(), "camera_max": camera_samples.max(),
		"visible_flash_samples": samples, "poses": poses.keys()})
	_check(samples > 0, "visible muzzle evidence missing")
	_check(poses.has("3:true") and poses.has("5:true"), "jump/hurt left pose missing")
	if sequence == "gate-fixed":
		_check(camera_samples.min() == 3580 and camera_samples.max() == 3580,
			"closed camera moved")
		var mech := current_scene.get_node("BossSlot/DefenseMech") as DefenseMech
		for hit in mech.health:
			mech.receive_hit()
		await _step()
		actor.global_position = mech.global_position
		await _layer_set("mech-victory", actor, mech)
		var frozen := actor.position
		Input.action_press("move_right")
		Input.action_press("shoot")
		for tick in 30:
			await _step()
		_check(actor.position == frozen and _state().outcome, "victory freeze changed")
		result["victory_freeze"] = _state()
		result["frozen_actor_position"] = [frozen.x, frozen.y]
		await _save("victory-freeze")
		await _retry()
		_check(_state().actor_health == 3 and _state().actor_x == 140 and not _state().outcome,
			"fixture R did not restore normal level")
		await _save("fixture-retry")
		result["retry"] = _state()
	else:
		_check(camera_samples.max() > camera_samples.min(), "follow camera never moved")
		actor.global_position = enemy.global_position + Vector2(24, 0)
		sprite.flip_h = false
		await _layer_set("soldier-moving-right", actor, enemy)
		sprite.flip_h = true
		await _layer_set("soldier-moving-left", actor, enemy)
	records.append(result)


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
		"corpse_position": [enemy.global_position.x, enemy.global_position.y], "pose": actor_sprite.frame})
	_check(corpse_sprite.z_index == -1 and actor_sprite.z_index == 0, "merged corpse bands changed")
	actor.set_physics_process(actor_physics)
	current_scene.set_process(true)
	paused = false
