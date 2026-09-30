extends "observe.gd"

var step_calls := 0
var extra_steps := 8

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--extra="):
			extra_steps = arg.trim_prefix("--extra=").to_int()
	super._initialize()

func _step() -> void:
	step_calls += 1
	await super._step()
	if step_calls == 41:
		for extra_step in extra_steps:
			await super._step()
