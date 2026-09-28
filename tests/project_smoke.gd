extends SceneTree


func _initialize() -> void:
	var entry_path := str(ProjectSettings.get_setting("application/run/main_scene", ""))
	if entry_path.is_empty():
		push_error("No playable single-level entry scene is configured")
		quit(1)
		return

	var level := load(entry_path) as PackedScene
	if level == null:
		push_error("The configured entry scene cannot be loaded")
		quit(1)
		return

	var instance := level.instantiate()
	root.add_child(instance)
	if instance is not Node2D:
		push_error("The single-level entry must be a 2D scene")
		quit(1)
		return

	print("PASS: single-level entry loads")
	quit(0)
