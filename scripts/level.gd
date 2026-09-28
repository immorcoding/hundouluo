extends Node2D


func _ready() -> void:
	for child in $Enemies.get_children():
		var soldier := child as MechanicalSoldier
		if soldier == null:
			continue
		soldier.target = $Operative/Operative
		soldier.projectile_fired.connect(_on_operative_projectile_fired)


func _physics_process(_delta: float) -> void:
	var camera := $Camera2D as Camera2D
	var half_view := camera.get_viewport_rect().size / camera.zoom / 2.0
	var center := camera.get_screen_center_position()
	for child in $Enemies.get_children():
		var soldier := child as MechanicalSoldier
		if soldier == null:
			continue
		soldier.attack_enabled = absf(soldier.global_position.x - center.x) + 18.0 < half_view.x \
			and absf(soldier.global_position.y - 24.0 - center.y) + 24.0 < half_view.y


func _on_operative_projectile_fired(projectile: Area2D) -> void:
	var spawn_position := projectile.global_position
	$Projectiles.add_child(projectile)
	projectile.global_position = spawn_position
