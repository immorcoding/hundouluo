extends SceneTree


func _initialize() -> void:
	var level := load("res://scenes/level.tscn") as PackedScene
	if level == null:
		push_error("Single-level scene cannot be loaded")
		quit(1)
		return
	var instance := level.instantiate()
	root.add_child(instance)
	for slot in ["Operative", "Enemies", "Projectiles"]:
		if instance.get_node_or_null(slot) is not Node2D:
			push_error("Missing 2D instance slot: " + slot)
			quit(1)
			return
	if instance.get_node_or_null("HUD") is not CanvasLayer:
		push_error("Missing screen-space HUD instance slot")
		quit(1)
		return

	print("PASS: single scene exposes the operative, enemies, projectiles and HUD slots")
	quit(0)
