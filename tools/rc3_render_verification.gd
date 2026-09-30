extends Node
## Explicit local verification entry for release templates without --script.
## Ordinary startup discards this node; mode names never accept resource paths.

const MODES := {
	"pixels": "res://tools/capture_issue_31_rc3_pixels.gd",
	"motion": "res://tools/capture_issue_31_rc3_motion.gd",
	"outcomes": "res://tools/capture_issue_31_rc3_outcomes.gd",
	"integrated": "res://tools/capture_issue_31_rc3.gd",
}


func _ready() -> void:
	var requested: Array[String] = []
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--rc3-render-verification="):
			requested.append(argument.trim_prefix("--rc3-render-verification="))
		elif argument == "--rc3-render-verification":
			requested.append("")
	if requested.is_empty():
		queue_free()
		return
	if requested.size() != 1 or not MODES.has(requested[0]):
		print("FAIL: unsupported or repeated rc3 render verification mode")
		get_tree().quit(1)
		return
	var fixture := load(MODES[requested[0]]) as Script
	if fixture == null or fixture.get_instance_base_type() != "SceneTree":
		print("FAIL: rc3 verification fixture is not a SceneTree script")
		get_tree().quit(1)
		return
	var loop := get_tree()
	loop.set_script(fixture)
	print("RC3_RENDER_VERIFICATION ", requested[0])
	loop.call_deferred("_initialize")
	queue_free()
