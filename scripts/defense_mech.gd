extends StaticBody2D
class_name DefenseMech

signal health_changed(health: int)
signal died
signal projectile_fired(projectile: Area2D)
signal charge_started

@export_range(1, 200, 1) var max_health := 42
@export var attack_range := 420.0
@export var charge_duration := 1.0
@export var shot_spacing := 0.22
@export var recovery_duration := 2.4

const ENEMY_PROJECTILE := preload("res://scenes/enemy_projectile.tscn")

enum Phase { IDLE, CHARGE, VOLLEY, RECOVERY }

var health := 42
var attack_enabled := false
var target: Node2D

var _phase := Phase.IDLE
var _remaining := 0.0
var _shots_left := 0
var _hurt_remaining := 0.0


func _ready() -> void:
	health = max_health


func is_fully_visible_in(view_rect: Rect2) -> bool:
	var sprite := $Sprite as Sprite2D
	var local_bounds := sprite.get_rect()
	var top_left := sprite.to_global(local_bounds.position)
	var bottom_right := sprite.to_global(local_bounds.end)
	return view_rect.encloses(Rect2(top_left, bottom_right - top_left))


func update_visibility(view_rect: Rect2) -> void:
	attack_enabled = health > 0 and is_fully_visible_in(view_rect)
	if not attack_enabled:
		_reset_attack()


func _physics_process(delta: float) -> void:
	if health == 0:
		return
	if _hurt_remaining > 0.0:
		_hurt_remaining = maxf(0.0, _hurt_remaining - delta)
	if not attack_enabled or not is_instance_valid(target) \
			or absf(target.global_position.x - global_position.x) > attack_range \
			or absf(target.global_position.y - global_position.y) > 100.0:
		_reset_attack()
		return
	if _phase == Phase.IDLE:
		_begin_charge()
	else:
		_remaining -= delta
		if _remaining <= 0.0:
			match _phase:
				Phase.CHARGE:
					_phase = Phase.VOLLEY
					_shots_left = 2
					_fire_low_projectile()
					_remaining = shot_spacing
				Phase.VOLLEY:
					_fire_low_projectile()
					_shots_left -= 1
					if _shots_left == 0:
						_phase = Phase.RECOVERY
						_remaining = recovery_duration
						$Muzzle.visible = false
					else:
						_remaining = shot_spacing
				Phase.RECOVERY:
					_begin_charge()
	if _hurt_remaining > 0.0:
		$Sprite.frame = 4
	elif _phase == Phase.CHARGE:
		$Sprite.frame = 1 + int(Time.get_ticks_msec() / 120) % 2
	elif _phase == Phase.VOLLEY:
		$Sprite.frame = 3
	else:
		$Sprite.frame = 0
	if _phase == Phase.CHARGE:
		var progress := 1.0 - _remaining / maxf(charge_duration, 0.01)
		$Muzzle.scale = Vector2.ONE * (1.0 + 0.45 * progress)
	else:
		$Muzzle.scale = Vector2.ONE


func _begin_charge() -> void:
	_phase = Phase.CHARGE
	_remaining = charge_duration
	$Muzzle.visible = true
	charge_started.emit()


func _fire_low_projectile() -> void:
	var projectile := ENEMY_PROJECTILE.instantiate() as Area2D
	projectile.global_position = to_global(Vector2(-62, -18))
	projectile.direction = -1
	projectile_fired.emit(projectile)


func _reset_attack() -> void:
	_phase = Phase.IDLE
	_remaining = 0.0
	_shots_left = 0
	$Muzzle.visible = false
	if health > 0:
		$Sprite.frame = 0


func receive_hit() -> void:
	if health == 0 or not attack_enabled:
		return
	health -= 1
	health_changed.emit(health)
	if health == 0:
		attack_enabled = false
		_reset_attack()
		$Sprite.frame = 5
		died.emit()
	else:
		_hurt_remaining = 0.12
		$Sprite.frame = 4


func _on_contact_body_entered(body: Node2D) -> void:
	if attack_enabled and health > 0 and body.has_method("receive_hit"):
		body.receive_hit()
