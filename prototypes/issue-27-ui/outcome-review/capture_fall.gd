extends SceneTree
# Review capture in archived #28 main only, does not change gameplay resources.
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	AudioServer.set_bus_mute(0,true)
	var level := (load("res://scenes/level.tscn") as PackedScene).instantiate()
	root.add_child(level)
	var actor := level.get_node("Operative/Operative")
	actor.position = Vector2(1392,425)
	for tick in 4:
		await physics_frame
	assert(level.get_node("HUD/OutcomePanel/ReasonLabel").text == "跌落深渊")
	level.process_mode = Node.PROCESS_MODE_DISABLED
	level.get_node("HUD").hide()
	await process_frame
	await RenderingServer.frame_post_draw
	var screenshot := root.get_texture().get_image()
	assert(screenshot.get_size()==Vector2i(640,360))
	screenshot.save_png(OS.get_cmdline_user_args()[0])
	print("Actual fall-death scene captured, actor health=",actor.health)
	level.queue_free()
	await process_frame
	quit()
