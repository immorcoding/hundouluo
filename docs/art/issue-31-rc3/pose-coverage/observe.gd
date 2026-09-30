extends "res://tools/capture_issue_36.gd"

func _inputs(tick: int, actor: CharacterBody2D) -> void:
	var before_health: int = actor.health
	super._inputs(tick, actor)
	if tick == 125:
		print("[DEBUG-rc3-pose] forced_hit frame=", Engine.get_physics_frames(),
			" before_health=", before_health, " after_health=", actor.health,
			" pose=", actor.get_node("Sprite").frame)

func _capture_pair(actor: CharacterBody2D, tick: int) -> Dictionary:
	var record: Dictionary = await super._capture_pair(actor, tick)
	record["physics_frame"] = Engine.get_physics_frames()
	record["health"] = actor.health
	return record
