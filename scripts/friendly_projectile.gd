extends Area2D

signal impacted(at: Vector2, hit_target: bool)

@export var speed := 520.0
@export var max_distance := 960.0
var direction := 1
var _spent := false
var _distance := 0.0


func _physics_process(delta: float) -> void:
	var step := speed * delta
	position.x += direction * step
	_distance += absf(step)
	if _distance >= max_distance:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if _spent:
		return
	_spent = true
	impacted.emit(global_position, body.has_method("receive_hit"))
	if body.has_method("receive_hit"):
		body.receive_hit()
	queue_free()
