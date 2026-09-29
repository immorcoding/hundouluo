extends Node2D

# Short-lived, world-space hit marks and non-spatial cues. Gameplay state lives in
# the operative, enemies, and level; this node only observes their events.
const CUES := {
	"player_shot": "res://assets/audio/player_shot.wav",
	"enemy_shot": "res://assets/audio/enemy_shot.wav",
	"hit_confirm": "res://assets/audio/hit_confirm.wav",
	"operative_hurt": "res://assets/audio/operative_hurt.wav",
	"enemy_warning": "res://assets/audio/enemy_warning.wav",
	"mech_charge_warning": "res://assets/audio/mech_charge_warning.wav",
	"death_health": "res://assets/audio/death_health.wav",
	"death_fall": "res://assets/audio/death_fall.wav",
}
const VOLUME_DB := {
	"player_shot": -22.0,
	"enemy_shot": -15.0,
	"hit_confirm": -15.0,
	"operative_hurt": -4.0,
	"enemy_warning": -6.0,
	"mech_charge_warning": -3.0,
	"death_health": -5.0,
	"death_fall": -5.0,
}
const IMPACT_ATLAS := preload("res://assets/combat_v011/atlas.png")

var _players: Dictionary = {}
var _marks: Array[Dictionary] = []


func _ready() -> void:
	for cue: String in CUES:
		var player := AudioStreamPlayer.new()
		player.name = cue
		player.stream = load(CUES[cue]) as AudioStream
		player.volume_db = VOLUME_DB[cue]
		player.max_polyphony = 4 if cue in ["player_shot", "enemy_shot", "hit_confirm"] else 1
		add_child(player)
		_players[cue] = player


func play_cue(cue: String) -> void:
	if _players.has(cue):
		(_players[cue] as AudioStreamPlayer).play()


func impact(at: Vector2, hit_target: bool) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = IMPACT_ATLAS
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.hframes = 4
	sprite.vframes = 8
	sprite.frame = 20 if hit_target else 24
	sprite.position = to_local(at)
	add_child(sprite)
	_marks.append({"sprite": sprite, "row": 5 if hit_target else 6, "remaining": 0.16})
	play_cue("hit_confirm")


func _process(delta: float) -> void:
	for index in range(_marks.size() - 1, -1, -1):
		_marks[index]["remaining"] -= delta
		if _marks[index]["remaining"] <= 0.0:
			(_marks[index]["sprite"] as Sprite2D).queue_free()
			_marks.remove_at(index)
		else:
			(_marks[index]["sprite"] as Sprite2D).frame = 4 * _marks[index]["row"] \
				+ mini(3, int((0.16 - _marks[index]["remaining"]) / 0.04))
