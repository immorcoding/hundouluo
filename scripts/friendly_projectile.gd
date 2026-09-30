extends Area2D

signal impacted(at: Vector2, hit_target: bool)

const FLASH_VISUAL := preload("res://scripts/combat_flash.gd")
const MUZZLE_CLIP := preload("res://scripts/projectile_muzzle_clip.gdshader")

@export var speed := 520.0
@export var max_distance := 960.0
var direction := 1
var muzzle_flash_enabled := true
var muzzle_visual_anchor: Node2D
var _spent := false
var _distance := 0.0
var _visual_elapsed := 0.0


func _ready() -> void:
	if is_instance_valid(muzzle_visual_anchor):
		var seam_material := ShaderMaterial.new()
		seam_material.shader = MUZZLE_CLIP
		$Sprite.material = seam_material
		_update_muzzle_clip()
	if muzzle_flash_enabled:
		call_deferred("_spawn_muzzle_flash")


func _process(_delta: float) -> void:
	_update_muzzle_clip()


func _update_muzzle_clip() -> void:
	if not is_instance_valid(muzzle_visual_anchor) or $Sprite.material == null:
		return
	var seam_material := $Sprite.material as ShaderMaterial
	seam_material.set_shader_parameter("muzzle_x", muzzle_visual_anchor.global_position.x)
	seam_material.set_shader_parameter("direction", direction)
	# The atlas tail is shorter than20px. Once clear, retain normal independent
	# rendering even if the owner later turns, dies, or leaves the scene.
	if direction * (global_position.x - muzzle_visual_anchor.global_position.x) > 20:
		$Sprite.material = null
		muzzle_visual_anchor = null


func _spawn_muzzle_flash() -> void:
	FLASH_VISUAL.spawn_from(self, 12, direction < 0)


func _physics_process(delta: float) -> void:
	_visual_elapsed += delta
	$Sprite.frame = int(_visual_elapsed / 0.05) % 4
	$Sprite.flip_h = direction < 0
	var step := speed * delta
	position.x += direction * step
	_distance += absf(step)
	if _distance >= max_distance:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if _spent:
		return
	_spent = true
	impacted.emit(global_position, body.has_method("receive_hit"))
	if body.has_method("receive_hit"):
		body.receive_hit()
	queue_free()
