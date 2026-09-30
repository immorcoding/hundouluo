extends "res://tools/capture_issue_36_outcomes.gd"
## True winning projectile at 120 Hz / 30 fps, death and physical R rebuild.


func _initialize() -> void:
	process_frame.connect(func() -> void: OS.delay_msec(17))
	super._initialize()
