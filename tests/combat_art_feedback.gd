extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var feedback := (load("res://scripts/combat_feedback.gd") as Script).new() as Node2D
	root.add_child(feedback)
	feedback.impact(Vector2(40, 60), true)
	feedback.impact(Vector2(80, 60), false)
	var marks := _visual_marks(feedback)
	if marks.size() != 2 or marks[0].frame != 20 or marks[1].frame != 24 \
			or marks[0].global_position != Vector2(40, 60) or marks[1].global_position != Vector2(80, 60):
		_fail("敌人与墙面命中须显示不同的原生短帧")
		return
	await create_timer(0.07).timeout
	if marks[0].frame == 20 or marks[1].frame == 24:
		_fail("命中标记须继续播放，而不是常驻单帧")
		return
	await create_timer(0.18).timeout
	await process_frame
	if not _visual_marks(feedback).is_empty():
		_fail("短命中反馈须自行消失")
		return
	print("PASS: 敌人/墙面独立命中短帧及清理")
	quit(0)


func _visual_marks(feedback: Node2D) -> Array[Sprite2D]:
	var marks: Array[Sprite2D] = []
	for child in feedback.get_children():
		if child is Sprite2D:
			marks.append(child)
	return marks


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
