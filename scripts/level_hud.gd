extends CanvasLayer


func show_life(health: int) -> void:
	$LifeLabel.text = "行动员生命  %d / 3" % health


func show_mech(max_health: int) -> void:
	$MechLabel.visible = true
	$MechProgress.visible = true
	$MechProgress.max_value = max_health
	show_mech_health(max_health)


func show_mech_health(health: int) -> void:
	$MechProgress.value = health
	$MechLabel.text = "防御机甲  %d / %d" % [health, int($MechProgress.max_value)]


func show_death(reason: String) -> void:
	$OutcomePanel.visible = true
	$OutcomePanel/TitleLabel.text = "任务失败"
	$OutcomePanel/ReasonLabel.text = reason


func show_complete() -> void:
	$OutcomePanel.visible = true
	$OutcomePanel/TitleLabel.text = "任务完成"
	$OutcomePanel/ReasonLabel.text = "防御机甲已击败"
