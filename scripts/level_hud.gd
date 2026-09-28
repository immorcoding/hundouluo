extends CanvasLayer


func show_life(health: int) -> void:
	$LifeLabel.text = "行动员生命  %d / 3" % health
	$LifeLabel.add_theme_color_override("font_color",
		Color(1.0, 0.62, 0.44) if health <= 1 else Color(0.83, 0.98, 0.98))


func show_mech(max_health: int) -> void:
	$MechLabel.visible = true
	$MechProgress.visible = true
	$MechProgress.max_value = max_health
	show_mech_health(max_health)


func show_mech_health(health: int) -> void:
	$MechProgress.value = health
	$MechLabel.text = "防御机甲  %d / %d" % [health, int($MechProgress.max_value)]
	$MechProgress.modulate = Color(1.0, 0.58, 0.43) \
		if health <= $MechProgress.max_value / 3.0 else Color(1.0, 0.86, 0.6)


func show_death(reason: String) -> void:
	$OutcomePanel.visible = true
	$OutcomePanel/TitleLabel.text = "任务失败"
	$OutcomePanel/ReasonLabel.text = reason
	$OutcomePanel/ReasonLabel.add_theme_color_override("font_color",
		Color(1.0, 0.72, 0.43) if reason == "跌落深渊" else Color(1.0, 0.55, 0.46))


func show_complete() -> void:
	$OutcomePanel.visible = true
	$OutcomePanel/TitleLabel.text = "任务完成"
	$OutcomePanel/ReasonLabel.text = "防御机甲已击败"
