extends SceneTree


class Target extends StaticBody2D:
	var hits := 0

	func receive_hit() -> void:
		hits += 1


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	var targets: Array[Target] = []
	for index in 2:
		var target := Target.new()
		target.collision_layer = 2
		target.position.x = 60
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(16, 16)
		shape.shape = rectangle
		target.add_child(shape)
		stage.add_child(target)
		targets.append(target)

	var projectile := (load("res://scenes/friendly_projectile.tscn") as PackedScene).instantiate() as Area2D
	projectile.position.x = 0
	stage.add_child(projectile)
	for frame in 20:
		await physics_frame
	var hits := targets[0].hits + targets[1].hits
	if hits != 1 or is_instance_valid(projectile):
		push_error("己方弹丸须对重叠对象只提交一次命中后消失；实际命中数：%d" % hits)
		quit(1)
		return
	print("PASS: 己方弹丸一次命中提交")
	quit(0)
