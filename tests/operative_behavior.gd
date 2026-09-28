extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	var floor := StaticBody2D.new()
	floor.collision_layer = 4
	var floor_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(600, 16)
	floor_shape.shape = rectangle
	floor.add_child(floor_shape)
	floor.position.y = 8
	stage.add_child(floor)

	var scene := load("res://scenes/operative.tscn") as PackedScene
	if scene == null:
		_fail("行动员场景无法加载")
		return
	var operative := scene.instantiate() as CharacterBody2D
	if operative == null:
		_fail("行动员不是可移动角色")
		return
	var sprite := operative.get_node_or_null("Sprite") as Sprite2D
	if sprite == null or sprite.texture == null:
		_fail("行动员贴图没有正确导入")
		return
	stage.add_child(operative)
	operative.position = Vector2(0, -30)
	for frame in 20:
		await physics_frame
	if not operative.is_on_floor():
		_fail("行动员未落到地面")
		return

	Input.action_press("move_right")
	for frame in 8:
		await physics_frame
	Input.action_release("move_right")
	if operative.position.x <= 0:
		_fail("按住向右没有移动")
		return
	var grounded_y := operative.position.y
	Input.action_press("jump")
	await physics_frame
	Input.action_release("jump")
	for frame in 4:
		await physics_frame
	if operative.position.y >= grounded_y:
		_fail("地面跳跃没有向上移动")
		return

	print("PASS: 行动员左右移动和地面跳跃")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
