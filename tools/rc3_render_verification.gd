extends Node
## Explicit local verification entry for release templates without --script.
## Ordinary startup discards this node; mode names never accept resource paths.

const MODES := {
	"pixels": "res://tools/capture_issue_31_rc3_pixels.gd",
	"motion": "res://tools/capture_issue_31_rc3_motion.gd",
	"outcomes": "res://tools/capture_issue_31_rc3_outcomes.gd",
	"integrated": "res://tools/capture_issue_31_rc3.gd",
}
const OUTPUT_ROOTS := [
	"E:/Projects/game_hundouluo_codex_worktree/issue-31-v011-acceptance/.godot/issue31-rc3",
	"E:/Projects/game_hundouluo_codex_artifacts/v0.1.1-rc.3",
]


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
	if not _reserve_output():
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


func _reserve_output() -> bool:
	var outputs: Array[String] = []
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			outputs.append(argument.trim_prefix("--out="))
		elif argument == "--out":
			outputs.append("")
	if outputs.size() != 1 or outputs[0].is_empty():
		return _reject_output("requires exactly one nonempty --out")
	var output := outputs[0].replace("\\", "/")
	if output != output.strip_edges() or not output.to_upper().begins_with("E:/"):
		return _reject_output("requires an absolute E: path")
	if output != output.simplify_path() or not _valid_components(output):
		return _reject_output("requires a normalized Windows path")
	var scoped := false
	for allowed_root in OUTPUT_ROOTS:
		if output.to_lower().begins_with(allowed_root.to_lower() + "/"):
			scoped = true
	if not scoped:
		return _reject_output("outside the fixed rc.3 evidence roots")
	var drive := DirAccess.open("E:/")
	if drive == null:
		return _reject_output("E: is unavailable")
	var ancestor := output
	while ancestor.length() > 3:
		if drive.is_link(ancestor):
			return _reject_output("linked output or parent")
		ancestor = ancestor.get_base_dir()
	if DirAccess.dir_exists_absolute(output) or FileAccess.file_exists(output):
		return _reject_output("output already exists")
	var parent_path := output.get_base_dir()
	var parent := DirAccess.open(parent_path)
	if parent == null:
		return _reject_output("parent must already exist")
	var actual_parent := parent.get_current_dir().replace("\\", "/").simplify_path()
	if actual_parent.to_lower() != parent_path.to_lower():
		return _reject_output("parent resolves outside the supplied path")
	# Reserve a fresh leaf before any fixture can write: a concurrent creator fails.
	if DirAccess.make_dir_absolute(output) != OK:
		return _reject_output("could not reserve a new output directory")
	return true


func _valid_components(output: String) -> bool:
	for component in output.substr(3).split("/"):
		if component.is_empty() or component.ends_with(".") or component.ends_with(" "):
			return false
		for character in component:
			if character.unicode_at(0) < 32 or character in '<>:"|?*':
				return false
		var stem := component.get_slice(".", 0).to_upper()
		if stem in ["CON", "PRN", "AUX", "NUL", "CONIN$", "CONOUT$"]:
			return false
		if stem.length() == 4 and stem.left(3) in ["COM", "LPT"]:
			if stem.right(1) in "123456789¹²³":
				return false
	return true


func _reject_output(reason: String) -> bool:
	print("FAIL: rc3 render verification output ", reason)
	return false
