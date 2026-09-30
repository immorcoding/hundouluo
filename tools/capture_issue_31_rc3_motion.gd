extends "res://tools/capture_issue_35.gd"
## Original unpaused Input/flight capture; no hidden-feedback measurement frames.


func _initialize() -> void:
	Engine.physics_ticks_per_second = 60
	process_frame.connect(func() -> void: OS.delay_msec(17))
	super._initialize()
