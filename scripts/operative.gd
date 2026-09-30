extends CharacterBody2D

signal projectile_fired(projectile: Area2D)
signal health_changed(health: int)
signal died

@export var run_speed := 210.0
@export var jump_speed := 360.0
@export var gravity := 900.0
@export_range(0.01, 2.0, 0.01) var fire_interval := 0.16
@export_range(0.0, 3.0, 0.05) var invulnerability_duration := 0.7
# Artwork-local muzzle points, one per atlas frame; configured by the scene.
@export var muzzle_offsets := PackedVector2Array([Vector2(30, -31)])

const PROJECTILE := preload("res://scenes/friendly_projectile.tscn")
const MUZZLE_FLASH := preload("res://scenes/combat_flash.tscn")

var _facing := 1
var _fire_cooldown := 0.0
var _invulnerable_remaining := 0.0
var _receives_hits := true
var health := 3


func _ready() -> void:
	died.connect($Muzzle.hide)


func _process(_delta: float) -> void:
	# Hits can change the visible pose after this actor's physics callback.
	# Anchor feedback to the pose actually drawn, including turns and jumps.
	_update_muzzle()


func _muzzle_position() -> Vector2:
	var muzzle := muzzle_offsets[mini($Sprite.frame, muzzle_offsets.size() - 1)]
	return Vector2(_facing * muzzle.x, muzzle.y)


func _update_muzzle() -> void:
	$Muzzle.position = _muzzle_position()
	$Muzzle.scale.x = _facing


func _physics_process(delta: float) -> void:
	if health == 0:
		return
	if _invulnerable_remaining > 0.0:
		_invulnerable_remaining = maxf(0.0, _invulnerable_remaining - delta)
		# Sustained warm tint reads as invulnerability without a strobe.
		$Sprite.modulate = Color(1.0, 0.65, 0.58, 0.82)
		if _invulnerable_remaining == 0.0:
			$Sprite.modulate = Color.WHITE
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
	# Victory can freeze this subtree before its next idle callback.
	_update_muzzle()
	if Input.is_action_pressed("shoot"):
		_fire_cooldown -= delta
		if _fire_cooldown <= 0.0:
			var projectile := PROJECTILE.instantiate() as Area2D
			projectile.global_position = to_global(_muzzle_position())
			projectile.direction = _facing
			projectile.muzzle_flash_enabled = false
			# A muzzle flash belongs to the moving gun; the projectile does not.
			$Muzzle.add_child(MUZZLE_FLASH.instantiate())
			projectile_fired.emit(projectile)
			_fire_cooldown = fire_interval
	else:
		_fire_cooldown = 0.0


func receive_hit() -> void:
	if not _receives_hits or health == 0 or _invulnerable_remaining > 0.0:
		return
	health -= 1
	health_changed.emit(health)
	if health == 0:
		velocity = Vector2.ZERO
		$Sprite.modulate = Color.WHITE
		$Sprite.frame = 6
		died.emit()
	else:
		_invulnerable_remaining = invulnerability_duration
		$Sprite.frame = 5
		_update_muzzle()


func stop_receiving_hits() -> void:
	# Script state can close immediately, even during a physics callback.
	_receives_hits = false
