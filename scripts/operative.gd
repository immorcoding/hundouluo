extends CharacterBody2D

signal projectile_fired(projectile: Area2D)
signal health_changed(health: int)
signal died

@export var run_speed := 210.0
@export var jump_speed := 360.0
@export var gravity := 900.0
@export_range(0.01, 2.0, 0.01) var fire_interval := 0.16
@export_range(0.0, 3.0, 0.05) var invulnerability_duration := 0.7

const PROJECTILE := preload("res://scenes/friendly_projectile.tscn")

var _facing := 1
var _fire_cooldown := 0.0
var _invulnerable_remaining := 0.0
var health := 3


func _physics_process(delta: float) -> void:
	if health == 0:
		return
	if _invulnerable_remaining > 0.0:
		_invulnerable_remaining = maxf(0.0, _invulnerable_remaining - delta)
		$Sprite.modulate.a = 0.4 if int(_invulnerable_remaining * 12.0) % 2 == 0 else 1.0
		if _invulnerable_remaining == 0.0:
			$Sprite.modulate.a = 1.0
	var direction := Input.get_axis("move_left", "move_right")
	velocity.x = direction * run_speed
	if direction != 0.0:
		_facing = int(sign(direction))
		$Sprite.flip_h = _facing < 0
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = -jump_speed
	else:
		velocity.y += gravity * delta
	move_and_slide()
	if _invulnerable_remaining == 0.0:
		if not is_on_floor():
			$Sprite.frame = 3
		elif direction != 0.0:
			$Sprite.frame = 1 + int(Time.get_ticks_msec() / 125) % 2
		else:
			$Sprite.frame = 0
	if Input.is_action_pressed("shoot"):
		_fire_cooldown -= delta
		if _fire_cooldown <= 0.0:
			var projectile := PROJECTILE.instantiate() as Area2D
			projectile.global_position = to_global(Vector2(_facing * 30, -31))
			projectile.direction = _facing
			projectile_fired.emit(projectile)
			_fire_cooldown = fire_interval
	else:
		_fire_cooldown = 0.0


func receive_hit() -> void:
	if health == 0 or _invulnerable_remaining > 0.0:
		return
	health -= 1
	health_changed.emit(health)
	if health == 0:
		velocity = Vector2.ZERO
		$Sprite.modulate.a = 1.0
		$Sprite.frame = 6
		died.emit()
	else:
		_invulnerable_remaining = invulnerability_duration
		$Sprite.frame = 5
