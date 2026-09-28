extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var projectile := (load("res://scenes/friendly_projectile.tscn") as PackedScene).instantiate()
	root.add_child(projectile)
	for frame in 150:
		await physics_frame
	if is_instance_valid(projectile):
		push_error("未命中的己方弹丸应在飞出测试区域后结束，避免按住射击无限累积")
		quit(1)
		return
	print("PASS: 未命中弹丸有限飞行距离")
	quit(0)
