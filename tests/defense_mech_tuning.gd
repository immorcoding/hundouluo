extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var level := (load("res://scenes/level.tscn") as PackedScene).instantiate()
	root.add_child(level)
	var actor := level.get_node("Operative/Operative") as CharacterBody2D
	var mech := level.get_node("BossSlot/DefenseMech") as DefenseMech
	var soldier := level.get_node("Enemies/SoloSoldier") as MechanicalSoldier
	actor.position = Vector2(3510, 252)
	for tick in 5:
		await physics_frame
	if not mech.attack_enabled or mech.max_health <= soldier.max_health * 10:
		_fail("机甲须明显比机械兵耐打且完整入镜后可交战")
		return
	# #12 reported roughly 120 s at 120 HP: approximately one effective hit
	# per second after dodging and missed shots. This is a calibration model,
	# not a human-play acceptance test; the desired 30–45 s maps to 30–45 HP.
	var projected_seconds := float(mech.max_health) / 1.0
	if projected_seconds < 30.0 or projected_seconds > 45.0:
		_fail("按反馈的约 1 有效命中/秒推算，首次成功战斗目标为 30–45 秒，当前 %.0f" % projected_seconds)
		return
	var max_health := mech.max_health
	for hit in max_health:
		mech.receive_hit()
	if mech.health != 0 or not level.get_node("HUD/OutcomePanel").visible:
		_fail("调参后必须仍可全程受击并在归零时通关")
		return
	print("PASS: 机甲 %d HP，按 #12 有效命中率推算 %.0f 秒；全程可受击" % [max_health, projected_seconds])
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
