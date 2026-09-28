extends Node2D

signal operative_fell

const TILES := preload("res://assets/pixel/base_tiles.png")
const DECK := preload("res://assets/pixel/hangar_deck.png")
const ART_SECTION_WIDTH := 1440
const FALL_DEATH_Y := 410.0
const FINAL_SECTION_X := 3500.0
const FRIENDLY_PROJECTILE_LAYER := 1 << 3

enum RunState { PLAYING, DEAD, COMPLETE }

var _fall_reported := false
var _fell := false
var _mech_hud_shown := false
var _state := RunState.PLAYING


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
	$HUD.show_life(operative.health)
	operative.health_changed.connect($HUD.show_life)
	operative.health_changed.connect(_on_operative_health_changed)
	operative.died.connect(_on_operative_died)
	operative_fell.connect(_on_operative_fell)
	$Camera2D.position = Vector2(320, 180)
	for child in $Enemies.get_children():
		var soldier := child as MechanicalSoldier
		if soldier == null:
			continue
		soldier.target = operative
		soldier.projectile_fired.connect(_on_operative_projectile_fired)
		soldier.warning_started.connect($CombatFeedback.play_cue.bind("enemy_warning"))
	$BossSlot/DefenseMech.target = operative
	$BossSlot/DefenseMech.projectile_fired.connect(_on_operative_projectile_fired)
	$BossSlot/DefenseMech.charge_started.connect($CombatFeedback.play_cue.bind("mech_charge_warning"))
	$BossSlot/DefenseMech.health_changed.connect($HUD.show_mech_health)
	$BossSlot/DefenseMech.died.connect(_on_mech_died)


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
	if _state != RunState.PLAYING:
		return
	var operative := $Operative/Operative as CharacterBody2D
	if not _fall_reported and operative.position.y >= FALL_DEATH_Y:
		_fall_reported = true
		operative.health = 0
		operative.velocity = Vector2.ZERO
		operative.get_node("Sprite").frame = 6
		# Consumers can distinguish the fatal fall before generic death handling.
		operative_fell.emit()
		operative.health_changed.emit(0)
		operative.died.emit()
		return
	var camera := $Camera2D as Camera2D
	var half_view := camera.get_viewport_rect().size / camera.zoom / 2.0
	var center := camera.get_screen_center_position()
	var view_rect := Rect2(center - half_view, half_view * 2.0)
	for child in $Enemies.get_children():
		var soldier := child as MechanicalSoldier
		if soldier == null:
			continue
		soldier.attack_enabled = soldier.is_fully_visible_in(view_rect)
	$BossSlot/DefenseMech.update_visibility(view_rect)
	if not _mech_hud_shown and (operative.position.x >= FINAL_SECTION_X or $BossSlot/DefenseMech.attack_enabled):
		_mech_hud_shown = true
		$HUD.show_mech($BossSlot/DefenseMech.max_health)


func _on_operative_projectile_fired(projectile: Area2D) -> void:
	var is_friendly := (projectile.collision_layer & FRIENDLY_PROJECTILE_LAYER) != 0
	$CombatFeedback.play_cue("player_shot" if is_friendly else "enemy_shot")
	projectile.impacted.connect($CombatFeedback.impact)
	var spawn_position := projectile.global_position
	$Projectiles.add_child(projectile)
	projectile.global_position = spawn_position


func _on_operative_health_changed(health: int) -> void:
	if health > 0:
		$CombatFeedback.play_cue("operative_hurt")


func _on_mech_died() -> void:
	if _state != RunState.PLAYING:
		return
	_state = RunState.COMPLETE
	_stop_gameplay()
	$ExitDoor/DoorBlocker/CollisionShape2D.set_deferred("disabled", true)
	$HUD.show_complete()


func _on_operative_fell() -> void:
	_fell = true


func _on_operative_died() -> void:
	if _state != RunState.PLAYING:
		return
	_state = RunState.DEAD
	$CombatFeedback.play_cue("death_fall" if _fell else "death_health")
	_stop_gameplay()
	$HUD.show_death("跌落深渊" if _fell else "生命耗尽")


func _stop_gameplay() -> void:
	# Keep this level alive for R, but freeze every active gameplay subtree.
	$Operative.process_mode = Node.PROCESS_MODE_DISABLED
	$Enemies.process_mode = Node.PROCESS_MODE_DISABLED
	$BossSlot.process_mode = Node.PROCESS_MODE_DISABLED
	$Projectiles.process_mode = Node.PROCESS_MODE_DISABLED
	# The winner cannot take a final hit from an already-overlapping projectile.
	$Operative/Operative.set_deferred("collision_layer", 0)
	$Operative/Operative.set_deferred("collision_mask", 0)


func _unhandled_input(event: InputEvent) -> void:
	if _state != RunState.PLAYING and event.is_action_pressed("retry") and not event.is_echo():
		get_viewport().set_input_as_handled()
		get_tree().call_deferred("change_scene_to_file", "res://scenes/level.tscn")
