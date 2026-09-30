extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var level := (load("res://scenes/level.tscn") as PackedScene).instantiate()
	root.add_child(level)
	level.position = Vector2(100, 50)
	var operative := level.get_node_or_null("Operative/Operative")
	var projectiles := level.get_node_or_null("Projectiles")
	if operative == null or projectiles == null:
		_fail("关卡槽位未装入行动员或弹丸容器")
		return
	var projectile := (load("res://scenes/friendly_projectile.tscn") as PackedScene).instantiate()
	projectile.global_position = Vector2(220, 40)
	operative.projectile_fired.emit(projectile)
	if projectile.get_parent() != projectiles or projectile.global_position != Vector2(220, 40):
		_fail("关卡未在保留世界坐标的情况下将弹丸放入弹丸槽")
		return
	print("PASS: 关卡通过信号安置行动员弹丸")
	# This fixture emits the shot in its first frame; let audio start first.
	await process_frame
	# Release the scene before quitting so active WAV playbacks can retire.
	level.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	call_deferred("quit", 0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
