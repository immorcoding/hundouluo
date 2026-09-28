extends SceneTree


func _initialize() -> void:
	var bindings := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_SPACE],
		"shoot": [KEY_J],
		"retry": [KEY_R],
	}
	for action in bindings:
		if not InputMap.has_action(action):
			push_error("Missing InputMap action: " + action)
			quit(1)
			return
		for keycode in bindings[action]:
			var key := InputEventKey.new()
			key.physical_keycode = keycode
			if not InputMap.action_has_event(action, key):
				push_error("Missing physical keyboard binding for " + action)
				quit(1)
				return
	for keycode in [KEY_D, KEY_SPACE, KEY_J]:
		var key := InputEventKey.new()
		key.physical_keycode = keycode
		key.pressed = true
		Input.parse_input_event(key)
	call_deferred("_check_pressed")


func _check_pressed() -> void:
	for action in ["move_right", "jump", "shoot"]:
		if not Input.is_action_pressed(action):
			push_error("Concurrent physical keys did not keep " + action + " pressed")
			quit(1)
			return

	print("PASS: simultaneous movement, jump and shoot bindings are distinct")
	quit(0)
