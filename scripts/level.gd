extends Node2D

const TILES := preload("res://assets/pixel/base_tiles.png")
const DECK := preload("res://assets/pixel/hangar_deck.png")


func _ready() -> void:
	# Exposed scene collision shapes are the sole terrain layout source.
	var left := _solid_span($Ground/Left as StaticBody2D)
	var right := _solid_span($Ground/Right as StaticBody2D)
	var ground_y := _ground_top($Ground/Left as StaticBody2D)
	for span in [left, right]:
		var deck := Sprite2D.new()
		deck.texture = DECK
		deck.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		deck.region_enabled = true
		deck.region_rect = Rect2(span.x, 0, span.y - span.x, 108)
		deck.position = Vector2((span.x + span.y) / 2.0, ground_y + 54)
		$Ground/Deck.add_child(deck)
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
	$Camera2D.position.x = clampf(lead_x, 320.0, 1120.0)


func _on_operative_projectile_fired(projectile: Area2D) -> void:
	var spawn_position := projectile.global_position
	$Projectiles.add_child(projectile)
	projectile.global_position = spawn_position
