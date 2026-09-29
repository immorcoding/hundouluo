extends Area2D

signal impacted(at: Vector2, hit_target: bool)

const FLASH := preload("res://scenes/combat_flash.tscn")

@export var speed := 270.0
@export var max_distance := 560.0
var direction := -1
var _distance := 0.0
var _spent := false
@export_enum("Mechanical Soldier", "Defense Mech") var visual_variant := 0
var _visual_elapsed := 0.0


func _ready() -> void:
	$Sprite.frame = 4 * (1 + visual_variant)
	call_deferred("_spawn_muzzle_flash")


func _spawn_muzzle_flash() -> void:
	if not is_inside_tree():
		return
	var flash := FLASH.instantiate() as Sprite2D
	flash.first_frame = 16
	flash.flip_h = direction > 0
	get_parent().add_child(flash)
	flash.global_position = global_position


func _physics_process(delta: float) -> void:
	_visual_elapsed += delta
	$Sprite.frame = 4 * (1 + visual_variant) + int(_visual_elapsed / (1.0 / 12.0)) % 4
	$Sprite.flip_h = direction > 0
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
