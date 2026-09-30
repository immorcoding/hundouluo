extends SceneTree
## Evidence harness only. Production rules and resources are never modified.
## Fixtures disclose their initial teleport/direct-hit setup; the full run uses
## only Input actions from the normal level spawn, including the final R retry.

const OUT := "res://docs/art/issue-31/"
var records: Array[Dictionary] = []
var failures: Array[String] = []
var enemy_shots := 0
var player_shots := 0
var charges := 0
var simulation_only := false


func _initialize() -> void:
	simulation_only = "--simulation-only" in OS.get_cmdline_user_args()
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(640, 360)
	root.content_scale_size = Vector2i(640, 360)
	DirAccess.make_dir_recursive_absolute(OUT + "frames")
	await _simulate()
	if not simulation_only:
		for sequence in ["run-jump", "soldier", "gap", "entry", "cancel", "boundary", "advance"]:
			await _fixture(sequence)
		await _outcomes()
	var filename := "simulation-results.json" if simulation_only else "capture-results.json"
	var file := FileAccess.open(OUT + filename, FileAccess.WRITE)
	file.store_string(JSON.stringify({"engine": Engine.get_version_info().string,
		"native_size": [640, 360], "physics_ticks_per_second": Engine.physics_ticks_per_second,
		"disclosure": "Automated evidence, not a human first success. Fixture setups are listed per sequence. Full-run simulation uses legal Input only; no teleport, direct damage, invulnerability or tuning changes.",
		"sequences": records, "failures": failures}, "\t") + "\n")
	file.close()
	_release()
	current_scene.queue_free()
	await process_frame
	await process_frame
	await create_timer(0.1).timeout
	# --fixed-fps advances the timer faster than the audio thread's wall clock.
	# Let that thread release already-freed fixture playbacks before shutdown.
	OS.delay_msec(150)
	await process_frame
	for failure in failures:
		push_error(failure)
	call_deferred("_finish")


func _finish() -> void:
	quit(0 if failures.is_empty() else 1)


func _new_level() -> void:
	_release()
	change_scene_to_file("res://scenes/level.tscn")
	await process_frame
	await process_frame
	enemy_shots = 0
	player_shots = 0
	charges = 0
	current_scene.get_node("BossSlot/DefenseMech").projectile_fired.connect(
		func(_projectile: Area2D) -> void: enemy_shots += 1)
	current_scene.get_node("BossSlot/DefenseMech").charge_started.connect(
		func() -> void: charges += 1)
	current_scene.get_node("Operative/Operative").projectile_fired.connect(
		func(_projectile: Area2D) -> void: player_shots += 1)
	for soldier in current_scene.get_node("Enemies").get_children():
		soldier.projectile_fired.connect(func(_projectile: Area2D) -> void: enemy_shots += 1)


func _step() -> void:
	await physics_frame
	await process_frame


func _release() -> void:
	for action in ["move_left", "move_right", "jump", "shoot", "retry"]:
		Input.action_release(action)


func _state() -> Dictionary:
	var actor := current_scene.get_node("Operative/Operative") as CharacterBody2D
	var mech := current_scene.get_node("BossSlot/DefenseMech") as DefenseMech
	return {"physics_frame": Engine.get_physics_frames(), "actor_x": actor.position.x,
		"actor_y": actor.position.y, "actor_health": actor.health, "on_floor": actor.is_on_floor(),
		"mech_health": mech.health, "mech_phase": mech._phase,
		"mech_visible": mech.attack_enabled, "enemy_shots": enemy_shots,
		"player_shots": player_shots, "charges": charges,
		"gate_frame": current_scene.get_node("CombatEntry/Artwork").frame,
		"gate_closed": not current_scene.get_node("CombatEntry/Barrier/CollisionShape2D").disabled,
		"camera_x": current_scene.get_node("Camera2D").position.x,
		"outcome": current_scene.get_node("HUD/OutcomePanel").visible,
		"reason": current_scene.get_node("HUD/OutcomePanel/ReasonLabel").text}


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _frame(sequence: String, tick: int) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_check(image.get_size() == Vector2i(640, 360), "Non-native viewport: " + sequence)
	_check(image.save_png(OUT + "frames/" + sequence + "-%04d.png" % tick) == OK,
		"Frame save failed: " + sequence)


func _save(name: String, frame_ready: bool = false) -> void:
	if not frame_ready:
		await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(OUT + name + ".png") == OK,
		"State save failed: " + name)


func _simulate() -> void:
	await _new_level()
	var actor := current_scene.get_node("Operative/Operative") as CharacterBody2D
	var mech := current_scene.get_node("BossSlot/DefenseMech") as DefenseMech
	var start_frame := Engine.get_physics_frames()
	var combat_frame := -1
	var first_hit_frame := -1
	var end_frame := -1
	var gap_jumped := false
	var timeline: Array[Dictionary] = []
	var jump_frames: Array[int] = []
	var effective_hits: Array[Dictionary] = []
	var previous_mech_health := mech.health
	Input.action_press("shoot")
	for tick in 5400:
		Input.action_release("jump")
		if actor.position.x < 3540:
			Input.action_press("move_right")
		else:
			Input.action_release("move_right")
		if actor.position.x >= 1260 and not gap_jumped and actor.is_on_floor():
			Input.action_press("jump")
			gap_jumped = true
			jump_frames.append(Engine.get_physics_frames() + 1)
		# Jump as the leading low projectile approaches. The normal jump spans
		# the three-shot volley; no state/property of a gameplay node is changed.
		if actor.position.x >= 3450 and actor.is_on_floor():
			for projectile in current_scene.get_node("Projectiles").get_children():
				if projectile is Area2D and projectile.collision_layer == 16 and projectile.direction < 0 and \
						projectile.position.x > actor.position.x and projectile.position.x < actor.position.x + 112:
					Input.action_press("jump")
					jump_frames.append(Engine.get_physics_frames() + 1)
					break
		await _step()
		if mech.health != previous_mech_health:
			effective_hits.append({"physics_frame": Engine.get_physics_frames(),
				"health_before": previous_mech_health, "health_after": mech.health,
				"actor_x": actor.position.x, "actor_y": actor.position.y})
			previous_mech_health = mech.health
		if combat_frame < 0 and charges > 0:
			combat_frame = Engine.get_physics_frames()
		if first_hit_frame < 0 and mech.health < mech.max_health:
			first_hit_frame = Engine.get_physics_frames()
		if tick % 60 == 0 or actor.health == 0 or mech.health == 0:
			var snapshot := _state()
			snapshot["tick"] = tick
			timeline.append(snapshot)
		if not simulation_only and tick % 12 == 0:
			await _frame("legal-run", tick)
		if actor.health == 0 or mech.health == 0:
			end_frame = Engine.get_physics_frames()
			break
	_release()
	var result := _state()
	result.merge({"sequence": "legal-run", "setup": "Normal level spawn. Only move_right, shoot, one gap jump and projectile-triggered boss jumps, then physical R key event.",
		"start_physics_frame": start_frame, "combat_start_physics_frame": combat_frame,
		"first_effective_mech_hit_physics_frame": first_hit_frame, "end_physics_frame": end_frame,
		"combat_seconds": float(end_frame - combat_frame) / 60.0 if combat_frame >= 0 else -1.0,
		"run_seconds": float(end_frame - start_frame) / 60.0,
		"effective_mech_hits": mech.max_health - mech.health,
		"soldiers_defeated": _dead_soldiers(), "gap_jump": gap_jumped,
		"jump_physics_frames": jump_frames, "effective_hit_events": effective_hits, "timeline": timeline})
	_check(mech.health == 0 and actor.health > 0, "Legal simulation did not complete alive")
	_check(_dead_soldiers() == 5, "Legal simulation did not defeat all five soldiers")
	if not simulation_only:
		await _save("legal-victory")
	await _retry()
	result["retry"] = _state()
	_check(current_scene.get_node("Operative/Operative").health == 3 and \
		current_scene.get_node("Operative/Operative").position.x == 140 and \
		not current_scene.get_node("HUD/OutcomePanel").visible, "Legal simulation R did not restore spawn")
	if not simulation_only:
		await _save("legal-retry")
	records.append(result)
	print("LEGAL_SIMULATION ", JSON.stringify(result))


func _dead_soldiers() -> int:
	var count := 0
	for soldier in current_scene.get_node("Enemies").get_children():
		if soldier.health == 0:
			count += 1
	return count


func _fixture(sequence: String) -> void:
	await _new_level()
	var actor := current_scene.get_node("Operative/Operative") as CharacterBody2D
	var setup := "Normal spawn; only movement/jump Input."
	if sequence == "soldier":
		actor.position = Vector2(580, 252)
		setup = "Initial actor teleport to (580,252); thereafter Input only; unchanged soldier AI, actual shots, impacts and corpse."
	elif sequence == "gap":
		actor.position = Vector2(1230, 252)
		setup = "Initial actor teleport to (1230,252); thereafter legal gap jump with Input only."
	elif sequence in ["entry", "cancel", "boundary", "advance"]:
		actor.position = Vector2(3462, 252)
		setup = "Initial actor teleport to (3462,252); thereafter Input only; unchanged gate, mech and projectiles."
	var total := 450 if sequence == "boundary" else 210 if sequence == "soldier" else 160
	var warning := -1
	var closure := -1
	var snapshots: Array[Dictionary] = []
	var camera_closed: Array[float] = []
	var start_physics_frame := Engine.get_physics_frames()
	for tick in total:
		Input.action_release("jump")
		if sequence == "run-jump":
			if tick == 10:
				Input.action_press("move_right")
			if tick == 45:
				Input.action_press("jump")
			if tick == 120:
				Input.action_release("move_right")
		elif sequence == "soldier":
			if tick == 65:
				Input.action_press("shoot")
			if tick == 140:
				Input.action_release("shoot")
				Input.action_press("move_right")
		elif sequence == "gap":
			if tick == 10:
				Input.action_press("move_right")
			if actor.position.x >= 1260 and actor.is_on_floor() and actor.position.x < 1344:
				Input.action_press("jump")
			if tick == 110:
				Input.action_release("move_right")
		else:
			if tick == 30:
				Input.action_press("move_right")
			if tick == 31 and sequence != "advance":
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
		await _frame(sequence, tick)
		var state := _state()
		if warning < 0 and state.gate_frame in range(1, 7):
			warning = tick
		if closure < 0 and state.gate_closed:
			closure = tick
		if state.gate_closed:
			camera_closed.append(state.camera_x)
		var name := ""
		if tick == 20:
			name = "early"
		elif warning >= 0 and tick == warning + 8:
			name = "warning"
		elif closure >= 0 and tick == closure + 4:
			name = "closed"
		elif tick == 75:
			name = "motion"
		elif tick == 125:
			name = "late"
		elif sequence == "boundary" and tick in [275, 430]:
			name = "wait-hit" if tick == 275 else "peek-hit"
		if not name.is_empty():
			state["tick"] = tick
			state["image"] = sequence + "-" + name + ".png"
			snapshots.append(state)
			await _save(sequence + "-" + name, true)
		if sequence == "run-jump" and tick in [30, 60]:
			await _save("start-run" if tick == 30 else "start-jump", true)
		if sequence == "gap" and tick == 40:
			await _save("gap-airborne", true)
		if sequence == "soldier" and tick in [30, 60, 68, 90, 140, 200]:
			await _save("soldier-tick-%03d" % tick, true)
	var result := _state()
	_check(Engine.get_physics_frames() - start_physics_frame == total,
		"Capture requires --fixed-fps 60 for one physics frame per saved frame: " + sequence)
	result.merge({"sequence": sequence, "setup": setup, "frames": total, "fps": 60,
		"start_physics_frame": start_physics_frame,
		"elapsed_physics_frames": Engine.get_physics_frames() - start_physics_frame,
		"warning_tick": warning, "closure_tick": closure, "snapshots": snapshots,
		"closed_camera_min": camera_closed.min() if not camera_closed.is_empty() else null,
		"closed_camera_max": camera_closed.max() if not camera_closed.is_empty() else null,
		"dead_soldiers": _dead_soldiers()})
	if sequence == "cancel":
		_check(warning >= 0 and closure < 0 and result.gate_frame == 0, "Warning retreat did not cancel closure")
	if sequence == "gap":
		_check(actor.position.x > 1440 and actor.is_on_floor() and actor.health == 3, "Fixture legal gap jump failed")
	if sequence == "soldier":
		_check(result.dead_soldiers == 1 and enemy_shots > 0 and player_shots >= 3, "Soldier fixture lacked live fire/corpse")
	if sequence == "boundary":
		_check(result.actor_health == 1 and result.mech_health == 41, "Gate wait/one-frame peek did not give reciprocal real hits")
	if not camera_closed.is_empty():
		_check(camera_closed.min() == 3580.0 and camera_closed.max() == 3580.0, "Closed camera moved")
	records.append(result)
	print("FIXTURE ", JSON.stringify(result))
	_release()


func _outcomes() -> void:
	for outcome in ["health-death", "fall-death", "fixture-victory"]:
		await _new_level()
		var actor := current_scene.get_node("Operative/Operative") as CharacterBody2D
		var setup := ""
		if outcome == "health-death":
			setup = "Direct receive_hit fixture; 43 physics frames between hits preserve normal 0.7s invulnerability."
			for hit in 3:
				actor.receive_hit()
				for tick in 43:
					await _step()
		elif outcome == "fall-death":
			setup = "Actor teleport to (1392,425); production fall detection and HUD then run normally."
			actor.position = Vector2(1392, 425)
			for tick in 3:
				await _step()
		else:
			setup = "Actor teleport to (3700,252); enabled mech receives 42 direct fixture hits; production victory and R paths. Legal input victory is separately captured."
			actor.position = Vector2(3700, 252)
			for tick in 4:
				await _step()
			var mech := current_scene.get_node("BossSlot/DefenseMech") as DefenseMech
			for hit in mech.health:
				mech.receive_hit()
			await _step()
		await _save(outcome)
		var record := _state()
		record["sequence"] = outcome
		record["setup"] = setup
		_check(record.outcome, "Outcome panel missing: " + outcome)
		if outcome != "fixture-victory":
			_check(record.reason == ("生命耗尽" if outcome == "health-death" else "跌落深渊"), "Wrong death reason")
		await _retry()
		await _save("retry-" + outcome)
		record["retry"] = _state()
		_check(record.retry.actor_health == 3 and not record.retry.outcome, "Fixture retry failed")
		records.append(record)


func _retry() -> void:
	_release()
	var event := InputEventKey.new()
	event.physical_keycode = KEY_R
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	await process_frame
	event.pressed = false
	Input.parse_input_event(event)
	await _step()
	enemy_shots = 0
	player_shots = 0
	charges = 0
