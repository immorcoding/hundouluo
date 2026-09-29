extends Node2D

var atlas: Texture2D
var mode := "combat"
var time := 0.0

func effect(row: int, frame: int, at: Vector2) -> void:
	draw_texture_rect_region(atlas, Rect2(at - Vector2(24, 20), Vector2(48, 40)), Rect2(frame * 48, row * 40, 48, 40))

func flash(row: int, age: float, at: Vector2, duration: float = 0.2) -> void:
	if age >= 0.0 and age < duration:
		effect(row, mini(3, int(age / duration * 4)), at)

func _draw() -> void:
	if mode == "combat":
		for start in [0.0, 0.4, 0.8, 1.2]:
			var age: float = fposmod(time, 2.0) - start
			flash(3, age, Vector2(615, 214))
			if age >= 0.0 and age < 0.4:
				effect(0, int(age * 20) % 4, Vector2(624 + age * 425, 214))
			flash(5, age - 0.4, Vector2(804, 214))
		var enemy_age := fposmod(time, 2.0) - 0.55
		flash(4, enemy_age, Vector2(779, 234))
		if enemy_age >= 0.0 and enemy_age < 0.85:
			effect(1, int(enemy_age * 12) % 4, Vector2(776 - enemy_age * 250, 234))
		# A separate low shot hits an existing crate edge, illustrating scenery impact.
		flash(6, fposmod(time, 2.0) - 1.6, Vector2(688, 237))
	else:
		if time < 1.0:
			effect(7, mini(3, int(time * 4)), Vector2(3773, 234))
		for start in [1.0, 1.22, 1.44]:
			var age: float = time - start
			flash(4, age, Vector2(3765, 234))
			if age >= 0.0 and age < 1.35:
				effect(2, int(age * 12) % 4, Vector2(3760 - age * 250, 234))
		for start in [0.4, 0.8, 1.2, 1.6, 2.0]:
			var age: float = time - start
			flash(3, age, Vector2(3585, 214))
			if age >= 0.0 and age < 0.46:
				effect(0, int(age * 20) % 4, Vector2(3594 + age * 400, 214))
			flash(5, age - 0.46, Vector2(3790, 214))
