extends Sprite2D

@export var first_frame := 12
var _elapsed := 0.0


static func spawn_from(projectile: Area2D, initial_frame: int, mirrored: bool) -> void:
	if not projectile.is_inside_tree():
		return
	var flash := (load("res://scenes/combat_flash.tscn") as PackedScene).instantiate() as Sprite2D
	flash.first_frame = initial_frame
	flash.flip_h = mirrored
	projectile.get_parent().add_child(flash)
	flash.global_position = projectile.global_position


func _ready() -> void:
	frame = first_frame


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= 0.2:
		queue_free()
	else:
		frame = first_frame + mini(3, int(_elapsed / 0.05))
