extends Node2D

signal operative_fell

const TILES := preload("res://assets/pixel/base_tiles.png")
const DECK := preload("res://assets/pixel/hangar_deck.png")
const ART_SECTION_WIDTH := 1440
const FALL_DEATH_Y := 410.0

var _fall_reported := false


func _ready() -> void:
	# Exposed scene collision shapes are the sole terrain layout source.
	var left := _solid_span($Ground/Left as StaticBody2D)
	var right := _solid_span($Ground/Right as StaticBody2D)
	var ground_y := _ground_top($Ground/Left as StaticBody2D)
	for span in [left, right]:
		# The 1440px painted deck repeats without stretching, but the collider
		# remains the only source of truth for where solid floor exists.
		var start: int = span.x
		while start < span.y:
			var source_x: int = posmod(start, ART_SECTION_WIDTH)
			var width: int = mini(span.y - start, ART_SECTION_WIDTH - source_x)
			var deck := Sprite2D.new()
			deck.texture = DECK
			deck.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			deck.region_enabled = true
			deck.region_rect = Rect2(source_x, 0, width, 108)
			deck.position = Vector2(start + width / 2.0, ground_y + 54)
			$Ground/Deck.add_child(deck)
			start += width
		var edge_x := left.y - 24 if span == left else right.x
		for y in range(ground_y, 360, 24):
			var tile := Sprite2D.new()
			tile.texture = TILES
			tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			tile.hframes = 13
			if span == left:
				tile.frame = 2 if y == ground_y else 11
			else:
				tile.frame = 3 if y == ground_y else 12
			tile.position = Vector2(edge_x + 12, y + 12)
			$Ground/Tiles.add_child(tile)
	var operative := $Operative/Operative as CharacterBody2D
	operative.position = Vector2(140, ground_y)
	$Camera2D.position = Vector2(320, 180)
	for child in $Enemies.get_children():
		var soldier := child as MechanicalSoldier
		if soldier == null:
			continue
		soldier.target = operative
		soldier.projectile_fired.connect(_on_operative_projectile_fired)


func _solid_span(body: StaticBody2D) -> Vector2i:
	var collision := body.get_node("CollisionShape2D") as CollisionShape2D
	var rect := collision.shape as RectangleShape2D
	var center := body.position + collision.position
	return Vector2i(roundi(center.x - rect.size.x / 2.0),
			roundi(center.x + rect.size.x / 2.0))


func _ground_top(body: StaticBody2D) -> int:
	var collision := body.get_node("CollisionShape2D") as CollisionShape2D
	var rect := collision.shape as RectangleShape2D
	return roundi(body.position.y + collision.position.y - rect.size.y / 2.0)


func _process(_delta: float) -> void:
	var lead_x: float = $Operative/Operative.position.x + 115.0
	$Camera2D.position.x = clampf(lead_x, 320.0, 4000.0)


func _physics_process(_delta: float) -> void:
	var operative := $Operative/Operative as CharacterBody2D
	if not _fall_reported and operative.position.y >= FALL_DEATH_Y:
		_fall_reported = true
		operative.health = 0
		operative.velocity = Vector2.ZERO
		operative.get_node("Sprite").frame = 6
		operative.health_changed.emit(0)
		operative.died.emit()
		operative_fell.emit()
	var camera := $Camera2D as Camera2D
	var half_view := camera.get_viewport_rect().size / camera.zoom / 2.0
	var center := camera.get_screen_center_position()
	var view_rect := Rect2(center - half_view, half_view * 2.0)
	for child in $Enemies.get_children():
		var soldier := child as MechanicalSoldier
		if soldier == null:
			continue
		soldier.attack_enabled = soldier.is_fully_visible_in(view_rect)


func _on_operative_projectile_fired(projectile: Area2D) -> void:
	var spawn_position := projectile.global_position
	$Projectiles.add_child(projectile)
	projectile.global_position = spawn_position
