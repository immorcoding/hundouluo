extends SceneTree
## Package notices from the actual engine, rather than a versionless copy.


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1 or not DirAccess.dir_exists_absolute(args[0]):
		push_error("Pass the existing package directory after --")
		quit(1)
		return
	var notices := {
		"GODOT_LICENSE.txt": "This game uses Godot Engine " + str(Engine.get_version_info().string)
			+ "\nhttps://godotengine.org/license\n\n" + Engine.get_license_text(),
		"GODOT_COPYRIGHT.json": JSON.stringify(Engine.get_copyright_info(), "\t"),
		"GODOT_THIRD_PARTY_LICENSES.json": JSON.stringify(Engine.get_license_info(), "\t"),
	}
	for filename: String in notices:
		var file := FileAccess.open(args[0].path_join(filename), FileAccess.WRITE)
		if file == null:
			push_error("Could not write engine notice: " + filename)
			quit(1)
			return
		file.store_string(notices[filename] + "\n")
	print("PASS: engine and third-party notices exported from ", Engine.get_version_info().string)
	quit(0)
