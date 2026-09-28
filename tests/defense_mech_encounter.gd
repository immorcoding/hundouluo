extends Node2D


func _ready() -> void:
	$DefenseMech.target = $Operative
	$DefenseMech.projectile_fired.connect(_on_projectile_fired)
	$Operative.projectile_fired.connect(_on_projectile_fired)


func _physics_process(_delta: float) -> void:
	var camera := $Camera2D as Camera2D
	var half_view := camera.get_viewport_rect().size / camera.zoom / 2.0
	var center := camera.get_screen_center_position()
	$DefenseMech.update_visibility(Rect2(center - half_view, half_view * 2.0))


func _on_projectile_fired(projectile: Area2D) -> void:
	var spawn_position := projectile.global_position
	$Projectiles.add_child(projectile)
	projectile.global_position = spawn_position
