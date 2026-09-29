extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	var friendly := (load("res://scenes/friendly_projectile.tscn") as PackedScene).instantiate() as Area2D
	friendly.position = Vector2(60, 100)
	stage.add_child(friendly)
	var enemy := (load("res://scenes/enemy_projectile.tscn") as PackedScene).instantiate() as Area2D
	enemy.position = Vector2(180, 100)
	stage.add_child(enemy)
	await process_frame
	var flashes := _flashes(stage)
	if flashes.size() != 2 or flashes[0].frame != 12 or flashes[1].frame != 16 \
			or flashes[0].global_position != Vector2(60, 100) \
			or flashes[1].global_position != Vector2(180, 100):
		_fail("己方与敌方枪口火光须留在各自发弹位置")
		return
	await create_timer(0.25).timeout
	await process_frame
	if not _flashes(stage).is_empty():
		_fail("枪口火光须迅速消失，不跟随飞行弹丸")
		return
	print("PASS: 双方枪口短帧留在发弹原点并清理")
	quit(0)


func _flashes(stage: Node2D) -> Array[Sprite2D]:
	var result: Array[Sprite2D] = []
	for child in stage.get_children():
		if child is Sprite2D:
			result.append(child)
	return result


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
