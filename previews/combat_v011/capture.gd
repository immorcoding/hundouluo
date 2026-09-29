extends SceneTree

const OUT := "res://previews/combat_v011/"

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	if DirAccess.make_dir_recursive_absolute(OUT + "frames") != OK:
		push_error("Could not create preview frame directory")
		quit(1)
		return
	root.content_scale_size = Vector2i(640, 360)
	root.size = Vector2i(640, 360)
	var level := (load("res://scenes/level.tscn") as PackedScene).instantiate()
	root.add_child(level)
	level.process_mode = Node.PROCESS_MODE_DISABLED
	var actor := level.get_node("Operative/Operative") as Node2D
	var camera := level.get_node("Camera2D") as Camera2D
	var effects := Node2D.new()
	effects.set_script(load(OUT + "effects.gd"))
	effects.atlas = ImageTexture.create_from_image(Image.load_from_file("res://assets/combat_v011/atlas.png"))
	effects.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	level.add_child(effects)
	for mode in ["combat", "mech"]:
		actor.position = Vector2(580 if mode == "combat" else 3550, 252)
		camera.position = Vector2(695 if mode == "combat" else 3665, 180)
		camera.force_update_scroll()
		if mode == "mech":
			level.get_node("HUD").show_mech(120)
		effects.mode = mode
		for frame in 48:
			effects.time = frame / 12.0
			effects.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			var shot := root.get_texture().get_image()
			if shot.get_size() != Vector2i(640, 360):
				push_error("Capture is not native 640x360")
				quit(1)
				return
			if shot.save_png(OUT + "frames/%s-%02d.png" % [mode, frame]) != OK:
				quit(1)
				return
			if mode == "mech" and frame == 9:
				shot.save_png(OUT + "charge.png")
			if frame == (9 if mode == "combat" else 19):
				shot.save_png(OUT + mode + ".png")
		print("Captured actual Godot level + isolated art staging: ", mode)
	quit()
