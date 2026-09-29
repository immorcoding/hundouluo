extends Sprite2D

@export var first_frame := 12
var _elapsed := 0.0


func _ready() -> void:
	frame = first_frame


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= 0.2:
		queue_free()
	else:
		frame = first_frame + mini(3, int(_elapsed / 0.05))
