extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	var floor := StaticBody2D.new()
	floor.collision_layer = 4
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(600, 16)
	shape.shape = rectangle
	floor.add_child(shape)
	floor.position.y = 8
	stage.add_child(floor)
	var operative := (load("res://scenes/operative.tscn") as PackedScene).instantiate()
	stage.add_child(operative)
	operative.position.y = -30
	var shots: Array[Area2D] = []
	if not operative.has_signal("projectile_fired"):
		_fail("行动员未公开发弹信号")
		return
	operative.projectile_fired.connect(func(projectile: Area2D) -> void:
		shots.append(projectile)
		stage.add_child(projectile)
	)
	operative.fire_interval = 0.1
	for frame in 20:
		await physics_frame
	Input.action_press("move_right")
	Input.action_press("jump")
	Input.action_press("shoot")
	for frame in 17:
		await physics_frame
	Input.action_release("move_right")
	Input.action_release("jump")
	Input.action_release("shoot")
	if shots.size() < 2 or shots.size() > 3:
		_fail("跑跳中按住射击没有依可调间隔连续发弹")
		return
	var right_shot := shots[shots.size() - 1]
	var right_x := right_shot.global_position.x
	for frame in 3:
		await physics_frame
	if right_shot.global_position.x <= right_x:
		_fail("面向右方的弹丸没有向右移动")
		return

	var before_left: float = operative.position.x
	Input.action_press("move_left")
	await physics_frame
	Input.action_release("move_left")
	if operative.position.x >= before_left:
		_fail("向左输入没有移动行动员")
		return
	Input.action_press("shoot")
	for frame in 8:
		await physics_frame
	Input.action_release("shoot")
	var left_shot := shots[shots.size() - 1]
	var left_x := left_shot.global_position.x
	for frame in 3:
		await physics_frame
	if left_shot == right_shot or left_shot.global_position.x >= left_x:
		_fail("面向左方的弹丸没有向左移动")
		return
	operative.fire_interval = 0.4
	var previous_shots := shots.size()
	Input.action_press("shoot")
	for frame in 17:
		await physics_frame
	Input.action_release("shoot")
	if shots.size() != previous_shots + 1:
		_fail("延长射击间隔后仍过快重复开火")
		return
	print("PASS: 跑跳连续射击及面向方向")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
