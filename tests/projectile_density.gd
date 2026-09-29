extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	for index in 80:
		var path := "res://scenes/friendly_projectile.tscn" if index % 2 == 0 \
			else "res://scenes/enemy_projectile.tscn"
		var projectile := (load(path) as PackedScene).instantiate() as Area2D
		projectile.position = Vector2(100 + index, 100 + index % 16 * 8)
		projectile.max_distance = 28.0
		stage.add_child(projectile)
	for tick in 30:
		await physics_frame
	if not stage.get_children().is_empty():
		push_error("密集交火后弹丸与枪口短帧须全部清理，残留：%d" % stage.get_child_count())
		quit(1)
		return
	print("PASS: 80 发密集交火均按原距离销毁且短帧清理")
	quit(0)
