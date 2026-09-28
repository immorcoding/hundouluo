extends SceneTree

const PRESET_SECTION := "preset.0"


func _initialize() -> void:
	var version := Engine.get_version_info()
	if not _check(version.get("major", -1) == 4 and version.get("minor", -1) == 7 and version.get("patch", -1) == 2, "This export preset is verified with Godot 4.7.2."):
		return

	var config := ConfigFile.new()
	var error := config.load("res://export_presets.cfg")
	if not _check(error == OK, "export_presets.cfg must be readable by Godot."):
		return

	if not _check(config.get_value(PRESET_SECTION, "name", "") == "Windows Desktop", "The preset must be named Windows Desktop."):
		return
	if not _check(config.get_value(PRESET_SECTION, "platform", "") == "Windows Desktop", "The preset must target Windows Desktop."):
		return
	if not _check(config.get_value(PRESET_SECTION, "export_filter", "") == "all_resources", "The preset must include all runtime resources."):
		return
	if not _check(config.get_value(PRESET_SECTION, "export_path", "") == "", "The committed preset must not contain a machine-specific export path."):
		return
	if not _check(config.get_value(PRESET_SECTION + ".options", "binary_format/architecture", "") == "x86_64", "The Windows build must target x86_64."):
		return
	if not _check(config.get_value(PRESET_SECTION + ".options", "binary_format/embed_pck", false), "The PCK must be embedded in the executable."):
		return
	if not _check(config.get_value(PRESET_SECTION + ".options", "custom_template/release", "") == "", "The preset must use the installed official release template."):
		return

	print("PASS: Windows export preset is portable, x86_64, and self-contained.")
	quit(0)


func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("FAIL: " + message)
	quit(1)
	return false
