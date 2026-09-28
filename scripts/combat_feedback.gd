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
	_marks.append({"position": to_local(at), "remaining": 0.16,
		"color": Color(0.65, 1.0, 0.94) if hit_target else Color(1.0, 0.71, 0.35)})
	play_cue("hit_confirm")
	queue_redraw()


func _process(delta: float) -> void:
	var had_marks := not _marks.is_empty()
	for index in range(_marks.size() - 1, -1, -1):
		_marks[index]["remaining"] -= delta
		if _marks[index]["remaining"] <= 0.0:
			_marks.remove_at(index)
	if had_marks:
		queue_redraw()


func _draw() -> void:
	for mark in _marks:
		var at: Vector2 = mark["position"]
		var color: Color = mark["color"]
		color.a = minf(1.0, mark["remaining"] / 0.12)
		draw_arc(at, 5.0, 0.0, TAU, 12, color, 1.5)
		draw_line(at + Vector2(-8, 0), at + Vector2(-4, 0), color, 1.5)
		draw_line(at + Vector2(4, 0), at + Vector2(8, 0), color, 1.5)
