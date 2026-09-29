extends Node2D

var atlas: Texture2D
var mode := "combat"
var time := 0.0
var friendly_muzzle := Vector2.ZERO
var soldier_muzzle := Vector2.ZERO
var mech_muzzle := Vector2.ZERO
var mech_low_y := 234.0

func effect(row: int, frame: int, at: Vector2) -> void:
	draw_texture_rect_region(atlas, Rect2(at - Vector2(24, 20), Vector2(48, 40)), Rect2(frame * 48, row * 40, 48, 40))

func flash(row: int, age: float, at: Vector2, duration: float = 0.2) -> void:
	if age >= 0.0 and age < duration:
		effect(row, mini(3, int(age / duration * 4)), at)

func _draw() -> void:
	if mode == "combat":
		for start in [0.0, 0.4, 0.8, 1.2]:
			var age: float = fposmod(time, 2.0) - start
			flash(3, age, friendly_muzzle + Vector2(5, 0))
			if age >= 0.0 and age < 0.4:
				effect(0, int(age * 20) % 4, friendly_muzzle + Vector2(age * 425, 0))
			flash(5, age - 0.4, Vector2(804, 214))
		var enemy_age := fposmod(time, 2.0) - 0.55
		flash(4, enemy_age, soldier_muzzle + Vector2(-5, 0))
		if enemy_age >= 0.0 and enemy_age < 0.85:
			effect(1, int(enemy_age * 12) % 4, soldier_muzzle + Vector2(-enemy_age * 250, 0))
		# A separate low shot hits an existing crate edge, illustrating scenery impact.
		flash(6, fposmod(time, 2.0) - 1.6, Vector2(688, 237))
	else:
		if time < 1.0:
			effect(7, mini(3, int(time * 4)), mech_muzzle)
		for start in [1.0, 1.22, 1.44]:
			var age: float = time - start
			flash(4, age, mech_muzzle + Vector2(-5, 0))
			if age >= 0.0 and age < 1.35:
				# Art staging only: connect the visible high barrel to the existing low lane.
				var y := lerpf(mech_muzzle.y, mech_low_y, clampf(age / 0.18, 0.0, 1.0))
				effect(2, int(age * 12) % 4, Vector2(mech_muzzle.x - age * 250, y))
		for start in [0.4, 0.8, 1.2, 1.6, 2.0]:
			var age: float = time - start
			flash(3, age, friendly_muzzle + Vector2(5, 0))
			if age >= 0.0 and age < 0.46:
				effect(0, int(age * 20) % 4, friendly_muzzle + Vector2(age * 400, 0))
			flash(5, age - 0.46, Vector2(3790, 214))
