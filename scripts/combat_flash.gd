extends Sprite2D

@export var first_frame := 12
@export var attach_muzzle_rear := false
# Approved friendly flash atlas: visible rear in each 48x40 cell.
# Frame0/2 contain near-transparent export residue before the visible shape.
const MUZZLE_REAR_COLUMNS := [18, 14, 17, 18]
const MUZZLE_SHADER := preload("res://scripts/muzzle_flash.gdshader")
var _elapsed := 0.0


static func spawn_from(projectile: Area2D, initial_frame: int, mirrored: bool) -> void:
	if not projectile.is_inside_tree():
		return
	var flash := (load("res://scenes/combat_flash.tscn") as PackedScene).instantiate() as Sprite2D
	flash.first_frame = initial_frame
	flash.flip_h = mirrored
	projectile.get_parent().add_child(flash)
	flash.global_position = projectile.global_position


func _ready() -> void:
	frame = first_frame
	if attach_muzzle_rear:
		var seam_material := ShaderMaterial.new()
		seam_material.shader = MUZZLE_SHADER
		material = seam_material
	_align_muzzle_rear()


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= 0.2:
		queue_free()
	else:
		frame = first_frame + mini(3, int(_elapsed / 0.05))
		_align_muzzle_rear()


func _align_muzzle_rear() -> void:
	if attach_muzzle_rear:
		# Keep the node on the gun anchor; shift only the drawn atlas cell.
		offset.x = 24 - MUZZLE_REAR_COLUMNS[frame - first_frame]
		(material as ShaderMaterial).set_shader_parameter("rear_column", MUZZLE_REAR_COLUMNS[frame - first_frame])
