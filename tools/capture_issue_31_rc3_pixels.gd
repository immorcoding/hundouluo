extends "res://tools/capture_issue_36.gd"
## Reuse #36 independent gun-mask and visible seam checks in the merged level.


func _initialize() -> void:
	Engine.physics_ticks_per_second = 60
	process_frame.connect(func() -> void: OS.delay_msec(17))
	super._initialize()


func _capture_pair(actor: CharacterBody2D, tick: int) -> Dictionary:
	var record: Dictionary = await super._capture_pair(actor, tick)
	record["camera_x"] = current_scene.get_node("Camera2D").position.x
	record["gate_closed"] = not current_scene.get_node("CombatEntry/Barrier/CollisionShape2D").disabled
	record["actor_health"] = actor.health
	record["on_floor"] = actor.is_on_floor()
	return record
