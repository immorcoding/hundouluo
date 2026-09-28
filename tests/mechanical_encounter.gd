extends Node2D


func _ready() -> void:
	var soldier := $Enemies/MechanicalSoldier as MechanicalSoldier
	soldier.target = $Operative/Operative
	soldier.projectile_fired.connect(_on_projectile_fired)


func _physics_process(_delta: float) -> void:
	var camera := $Camera2D as Camera2D
	var half_view := camera.get_viewport_rect().size / camera.zoom / 2.0
	var center := camera.get_screen_center_position()
	var view_rect := Rect2(center - half_view, half_view * 2.0)
	for child in $Enemies.get_children():
		var soldier := child as MechanicalSoldier
		if soldier != null:
			soldier.attack_enabled = soldier.is_fully_visible_in(view_rect)


func _on_projectile_fired(projectile: Area2D) -> void:
	var spawn_position := projectile.global_position
	$Projectiles.add_child(projectile)
	projectile.global_position = spawn_position
