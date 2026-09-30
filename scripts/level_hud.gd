extends CanvasLayer


const LIFE_FULL := preload("res://assets/ui_v011/life-full.png")
const LIFE_EMPTY := preload("res://assets/ui_v011/life-empty.png")


@onready var _life_cells: Array[TextureRect] = [
	$LifeDisplay/Life1, $LifeDisplay/Life2, $LifeDisplay/Life3,
]


func show_life(health: int) -> void:
	for i in _life_cells.size():
		_life_cells[i].texture = LIFE_FULL if i < health else LIFE_EMPTY


func show_mech(max_health: int) -> void:
	$MechLabel.visible = true
	$MechValueLabel.visible = true
	$MechProgress.visible = true
	$MechProgress.max_value = max_health
	show_mech_health(max_health)


func show_mech_health(health: int) -> void:
	$MechProgress.value = health
	# Match the approved native-pixel floor, including a visible final hit point.
	$MechProgress/Fill.visible = health > 0
	$MechProgress/Fill.size.x = maxi(1, int(
		$MechProgress.size.x * $MechProgress.value / $MechProgress.max_value))
	$MechValueLabel.text = "%d/%d" % [health, int($MechProgress.max_value)]


func show_death(reason: String) -> void:
	_show_outcome("任务失败", reason, Color("ffcb7b"))


func show_complete() -> void:
	_show_outcome("任务完成", "防御机甲已击败", Color("8de9ed"))


func _show_outcome(title: String, reason: String, accent: Color) -> void:
	$LifeDisplay.hide()
	$MechLabel.hide()
	$MechValueLabel.hide()
	$MechProgress.hide()
	$OutcomePanel.show()
	$OutcomePanel/TitleLabel.text = title
	$OutcomePanel/TitleLabel.add_theme_color_override("font_color", accent)
	$OutcomePanel/ReasonLabel.text = reason
