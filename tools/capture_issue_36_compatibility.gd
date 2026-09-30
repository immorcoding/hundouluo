extends "res://tools/capture_issue_36.gd"
## Graphical golden comparison of unchanged standalone friendly/enemy feedback.


func _run() -> void:
	root.size = Vector2i(640, 360)
	root.content_scale_size = Vector2i(640, 360)
	DirAccess.make_dir_recursive_absolute(out + "/frames")
	var stage := Node2D.new()
	root.add_child(stage)
	for direction in [-1, 1]:
		for friendly in [false, true]:
			var path := "res://scenes/friendly_projectile.tscn" if friendly else "res://scenes/enemy_projectile.tscn"
			var projectile := (load(path) as PackedScene).instantiate() as Area2D
			projectile.direction = direction
			projectile.position = Vector2(160 if direction < 0 else 480, 100 if friendly else 220)
			stage.add_child(projectile)
	for tick in 16:
		await _step()
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		if image.get_size() != Vector2i(640, 360) or image.save_png(out + "/frames/%03d.png" % tick) != OK:
			failures.append("standalone graphical capture failed")
	stage.queue_free()
	await process_frame
	await process_frame
	OS.delay_msec(150)
	if failures.is_empty():
		print("PASS: standalone friendly/enemy native feedback capture")
	quit(0 if failures.is_empty() else 1)
