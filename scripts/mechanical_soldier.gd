extends CharacterBody2D
class_name MechanicalSoldier

signal died
signal projectile_fired(projectile: Area2D)

@export var patrol_speed := 28.0
@export var patrol_half_width := 42.0
@export var gravity := 900.0
@export_range(1, 20, 1) var max_health := 3
@export var attack_range := 280.0
@export var warning_duration := 0.4
@export var fire_interval := 1.6

const ENEMY_PROJECTILE := preload("res://scenes/enemy_projectile.tscn")

var health := 3
var target: Node2D
var attack_enabled := false
var _patrol_origin := 0.0
var _patrol_direction := -1
var _facing := -1
var _warning_remaining := 0.0
var _fire_cooldown := 0.0


func _ready() -> void:
	health = max_health
	_patrol_origin = global_position.x


func _physics_process(delta: float) -> void:
	if health == 0:
		return
	_fire_cooldown = maxf(0.0, _fire_cooldown - delta)
	var in_range := attack_enabled and is_instance_valid(target) \
		and absf(target.global_position.x - global_position.x) <= attack_range \
		and absf(target.global_position.y - global_position.y) <= 90.0
	if not in_range:
		_warning_remaining = 0.0
		$Muzzle.visible = false
	elif _warning_remaining > 0.0:
		_warning_remaining -= delta
		if _warning_remaining <= 0.0:
			$Muzzle.visible = false
			_fire_cooldown = fire_interval
			var projectile := ENEMY_PROJECTILE.instantiate() as Area2D
			projectile.global_position = to_global(Vector2(_facing * 26, -18))
			projectile.direction = _facing
			projectile_fired.emit(projectile)
	elif _fire_cooldown == 0.0:
		_facing = -1 if target.global_position.x < global_position.x else 1
		$Muzzle.position = Vector2(_facing * 24, -18)
		$Muzzle.visible = true
		_warning_remaining = warning_duration
	if global_position.x <= _patrol_origin - patrol_half_width:
		_patrol_direction = 1
	elif global_position.x >= _patrol_origin + patrol_half_width:
		_patrol_direction = -1
	if _warning_remaining == 0.0:
		_facing = _patrol_direction
	velocity.x = 0.0 if _warning_remaining > 0.0 else patrol_speed * _patrol_direction
	velocity.y += gravity * delta
	move_and_slide()
	$Sprite.flip_h = _facing > 0
	$Sprite.frame = 3 if _warning_remaining > 0.0 else 1 + int(Time.get_ticks_msec() / 170) % 2


func receive_hit() -> void:
	if health == 0:
		return
	health -= 1
	if health == 0:
		$Muzzle.visible = false
		died.emit()
		queue_free()
	else:
		$Sprite.frame = 5


func _on_contact_body_entered(body: Node2D) -> void:
	if health > 0 and body.has_method("receive_hit"):
		body.receive_hit()
