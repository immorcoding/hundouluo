extends SceneTree
## Real health/projectile/input probe. No range, damage or trigger edits.

var shot_count := 0
var first_muzzle := Vector2.ZERO


func _initialize() -> void:
	call_deferred("_run")


func _record_shot(projectile: Area2D) -> void:
	if shot_count == 0:
		first_muzzle = projectile.global_position
	shot_count += 1


func _steps(count: int) -> void:
	for tick in count:
		await physics_frame
		await process_frame


func _run() -> void:
	root.size = Vector2i(640, 360)
	for gate_x in [3396.0, 3388.0]:
		shot_count = 0
		first_muzzle = Vector2.ZERO
		var level := (load("res://scenes/level.tscn") as PackedScene).instantiate() as Node2D
		root.add_child(level)
		level.get_node("CombatEntry").position.x = gate_x
		var actor := level.get_node("Operative/Operative") as CharacterBody2D
		var mech := level.get_node("BossSlot/DefenseMech") as DefenseMech
		mech.projectile_fired.connect(_record_shot)
		actor.position = Vector2(3462, 252)
		await _steps(30)
		actor.position.x = 3464
		await _steps(30)
		Input.action_press("move_left")
		await _steps(42)
		Input.action_release("move_left")
		await _steps(180)
		var rest_x := actor.position.x
		var rest_health: int = actor.health
		var rest_shots := shot_count
		var body := actor.get_node("Body") as CollisionShape2D
		var shape := body.shape as RectangleShape2D
		var hurt_rect := Rect2(body.global_position - shape.size / 2, shape.size)
		# Ordinary one-physics-frame right tap + shot, followed by a left tap.
		# Unlike setting private facing, this is reachable with actual inputs.
		Input.action_press("move_right")
		Input.action_press("shoot")
		await _steps(1)
		Input.action_release("move_right")
		Input.action_release("shoot")
		Input.action_press("move_left")
		await _steps(1)
		Input.action_release("move_left")
		await _steps(120)
		print("gate=", gate_x, " rest_x=", rest_x,
			" distance=", mech.global_position.x-rest_x,
			" rest_health=", rest_health, " rest_shots=", rest_shots,
			" first_enemy_muzzle=", first_muzzle, " actual_actor_hitbox=", hurt_rect,
			" after_peek_actor_health=", actor.health, " after_peek_mech_health=", mech.health,
			" total_enemy_shots=", shot_count, " final_x=", actor.position.x)
		if absf(rest_x-gate_x-19.075) > 0.2 or mech.health >= mech.max_health:
			push_error("Boundary or ordinary player peek shot was not exercised")
			quit(1)
			return
		if gate_x == 3396.0 and (rest_health >= 3 or rest_shots == 0):
			push_error("16px candidate was not actually hit by an enemy projectile")
			quit(1)
			return
		if gate_x == 3388.0 and (rest_health != 3 or actor.health != 3 or shot_count != 0):
			push_error("24px safe-pocket hypothesis changed; inspect before reporting")
			quit(1)
			return
		level.queue_free()
		await process_frame
		await process_frame
	print("PASS: x3396 remains contestable; x3388 admits a real peek-shot safe pocket")
	quit(0)
