extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	change_scene_to_file("res://scenes/level.tscn")
	await process_frame
	await process_frame
	var level := current_scene
	var actor := level.get_node("Operative/Operative") as CharacterBody2D
	var feedback := level.get_node("CombatFeedback")
	var hud := level.get_node("HUD")
	for cue in ["player_shot", "enemy_shot", "hit_confirm", "operative_hurt",
			"enemy_warning", "mech_charge_warning", "death_health", "death_fall"]:
		var player := feedback.get_node_or_null(cue) as AudioStreamPlayer
		if player == null or player.stream == null:
			_fail("音效没有导入并接入：" + cue)
			return
	if feedback.get_node("player_shot").volume_db >= feedback.get_node("operative_hurt").volume_db:
		_fail("己方射击应比受击提示轻")
		return
	actor.position = Vector2(630, 252)
	var soldier := level.get_node("Enemies/SoloSoldier") as MechanicalSoldier
	var warned := false
	for tick in 35:
		await physics_frame
		warned = warned or soldier.get_node("Muzzle").visible
		if warned:
			break
	if not warned or not feedback.get_node("enemy_warning").playing:
		_fail("完整关卡单兵预告缺少视觉或声音")
		return
	var friendly := (load("res://scenes/friendly_projectile.tscn") as PackedScene).instantiate() as Area2D
	actor.projectile_fired.emit(friendly)
	if not feedback.get_node("player_shot").playing:
		_fail("己方发弹未播放轻射击声")
		return
	friendly._on_body_entered(level.get_node("Ground/Left"))
	if feedback._marks.size() != 1 or not feedback.get_node("hit_confirm").playing:
		_fail("弹丸击墙缺少短暂标记或击中声")
		return
	var target_hit := (load("res://scenes/friendly_projectile.tscn") as PackedScene).instantiate() as Area2D
	actor.projectile_fired.emit(target_hit)
	var old_health := soldier.health
	target_hit._on_body_entered(soldier)
	if soldier.health != old_health - 1 or feedback._marks.size() != 2:
		_fail("弹丸击敌没有伤害与标记")
		return
	for tick in 14:
		await physics_frame
	if not feedback._marks.is_empty():
		_fail("命中标记应在短暂显示后消失")
		return
	var hostile := (load("res://scenes/enemy_projectile.tscn") as PackedScene).instantiate() as Area2D
	soldier.projectile_fired.emit(hostile)
	if not feedback.get_node("enemy_shot").playing:
		_fail("敌弹未播放区别于己方的发射声")
		return
	hostile._on_body_entered(actor)
	if actor.health != 2 or not feedback.get_node("operative_hurt").playing \
			or actor.get_node("Sprite").frame != 5:
		_fail("行动员受击反馈不完整")
		return
	await physics_frame
	if actor.get_node("Sprite").modulate == Color.WHITE:
		_fail("无敌期缺少稳定可见的暖色标识")
		return
	actor.position = Vector2(140, 252)
	actor.invulnerability_duration = 0.0
	for tick in 50:
		await physics_frame
	actor.receive_hit()
	if not hud.get_node("LifeLabel").text.contains("1") \
			or not hud.get_node("LifeLabel").get_theme_color("font_color").r > 0.9:
		_fail("低血量 HUD 缺少强调")
		return
	actor.position = Vector2(3700, 252)
	for tick in 5:
		await physics_frame
	var mech := level.get_node("BossSlot/DefenseMech") as DefenseMech
	if not mech.get_node("Muzzle").visible or not feedback.get_node("mech_charge_warning").playing \
			or not hud.get_node("MechProgress").visible:
		_fail("机甲蓄力或血量反馈没有在完整关卡出现")
		return
	mech.receive_hit()
	if hud.get_node("MechProgress").value != mech.health:
		_fail("机甲进度未随命中更新")
		return
	actor.receive_hit()
	if not feedback.get_node("death_health").playing or not hud.get_node("OutcomePanel").visible:
		_fail("生命死亡缺少独立音效与重试提示")
		return
	change_scene_to_file("res://scenes/level.tscn")
	await process_frame
	await process_frame
	level = current_scene
	actor = level.get_node("Operative/Operative") as CharacterBody2D
	feedback = level.get_node("CombatFeedback")
	actor.position = Vector2(1392, 425)
	for tick in 3:
		await physics_frame
	if not feedback.get_node("death_fall").playing \
			or not level.get_node("HUD/OutcomePanel/ReasonLabel").text.contains("跌落"):
		_fail("跌落死亡缺少不同声音及视觉死因")
		return
	print("PASS: 完整关卡音效接线、危险/击中/受击/机甲进度/两种死因反馈")
	current_scene.queue_free()
	await process_frame
	call_deferred("_finish")


func _finish() -> void:
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
