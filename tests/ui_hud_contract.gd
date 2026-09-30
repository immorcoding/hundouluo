extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	change_scene_to_file("res://scenes/level.tscn")
	await process_frame
	await process_frame
	var hud := current_scene.get_node("HUD")
	var life := hud.get_node_or_null("LifeDisplay")
	if life == null or not life.visible:
		push_error("开场应展示获批 S6 的三格生命模块")
		quit(1)
		return
	var full := load("res://assets/ui_v011/life-full.png")
	var empty := load("res://assets/ui_v011/life-empty.png")
	var actor := current_scene.get_node("Operative/Operative")
	if life.get_node("Life1").texture != full or life.get_node("Life2").texture != full or life.get_node("Life3").texture != full:
		push_error("开场应有三格实心生命")
		quit(1)
		return
	actor.receive_hit()
	if life.get_node("Life1").texture != full or life.get_node("Life2").texture != full or life.get_node("Life3").texture != empty:
		push_error("受击后应立即展示两格实心、一格空槽")
		quit(1)
		return

	actor.position = Vector2(3700, 252)
	for tick in 4:
		await physics_frame
	if not hud.get_node("MechValueLabel").visible or hud.get_node("MechValueLabel").text != "42/42":
		push_error("机甲入镜应显示真实上限 42/42")
		quit(1)
		return
	var mech := current_scene.get_node("BossSlot/DefenseMech")
	for hit in 41:
		mech.receive_hit()
	if hud.get_node("MechValueLabel").text != "1/42" or hud.get_node("MechProgress").value != 1:
		push_error("机甲受击应显示 1/42 的最小非零进度")
		quit(1)
		return

	mech.receive_hit()
	if life.visible or hud.get_node("MechProgress").visible or hud.get_node("MechValueLabel").visible:
		push_error("结算应隐藏战斗 HUD")
		quit(1)
		return
	if hud.get_node("OutcomePanel/TitleLabel").text != "任务完成" or hud.get_node("OutcomePanel/TitleLabel").get_theme_color("font_color") != Color("8de9ed"):
		push_error("完成页应展示青色任务完成标题")
		quit(1)
		return
	if hud.get_node("OutcomePanel/ReasonLabel").text != "防御机甲已击败" or hud.get_node("OutcomePanel/RetryLabel").text != "R 从关卡起点重试":
		push_error("完成页应展示击败说明及整关重试提示")
		quit(1)
		return
	print("PASS: S6 生命变化、机甲进度与获批结算状态")
	current_scene.queue_free()
	await process_frame
	await process_frame
	await create_timer(0.1).timeout
	call_deferred("_finish")


func _finish() -> void:
	quit(0)
