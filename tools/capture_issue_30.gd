extends SceneTree
# Acceptance fixture: real level events, plus the frozen review renderer as oracle.
# Prototype scripts are used only here, never by scenes/level.tscn.
const HUD_ORACLE := preload("res://prototypes/issue-27-ui/throwaway-portrait-match/render.gd")
const OUTCOME_ORACLE := preload("res://prototypes/issue-27-ui/outcome-review/render.gd")
const OUT := "res://docs/art/issue-30/"
var comparisons: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	root.size = Vector2i(640, 360)
	root.content_scale_size = Vector2i(640, 360)
	DirAccess.make_dir_recursive_absolute(OUT)
	await _new_level()
	await _save("start")
	var actor := current_scene.get_node("Operative/Operative")
	actor.position = Vector2(1640, 252)
	for tick in 4:
		await physics_frame
	await _save("gap-left")
	actor.position = Vector2(3700, 252)
	for tick in 4:
		await physics_frame
	await _save("mech-full")
	var mech := current_scene.get_node("BossSlot/DefenseMech")
	for hit in 14:
		mech.receive_hit()
	await _save("combat")
	actor.invulnerability_duration = 0.0
	actor.receive_hit()
	await _save("hurt")
	actor.receive_hit()
	await _save("low")
	for hit in 27:
		mech.receive_hit()
	await _save("mech-one")
	actor.receive_hit()
	if current_scene.get_node("HUD/OutcomePanel/ReasonLabel").text != "生命耗尽":
		push_error("Real health death did not reach HUD")
		quit(1)
		return
	await _save("failure")
	await _retry()
	await _save("retry-failure")
	actor = current_scene.get_node("Operative/Operative")
	actor.position = Vector2(1392, 425)
	for tick in 3:
		await physics_frame
	if current_scene.get_node("HUD/OutcomePanel/ReasonLabel").text != "跌落深渊":
		push_error("Real fall did not reach HUD")
		quit(1)
		return
	await _save("fall")
	await _retry()
	await _save("retry-fall")
	actor = current_scene.get_node("Operative/Operative")
	actor.position = Vector2(3700, 252)
	for tick in 4:
		await physics_frame
	mech = current_scene.get_node("BossSlot/DefenseMech")
	for hit in mech.health:
		mech.receive_hit()
	await _save("complete")
	await _retry()
	await _save("retry-complete")
	var file := FileAccess.open(OUT+"comparisons.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(comparisons, "\t")+"\n")
	current_scene.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	call_deferred("_finish")


func _new_level() -> void:
	change_scene_to_file("res://scenes/level.tscn")
	await process_frame
	await process_frame


func _retry() -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_R
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	await process_frame
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame
	if current_scene.get_node("Operative/Operative").health != 3 or current_scene.get_node("HUD/OutcomePanel").visible:
		push_error("R did not restore a fresh level")
		quit(1)


func _save(state: String) -> void:
	var level := current_scene
	var hud := level.get_node("HUD")
	level.process_mode = Node.PROCESS_MODE_DISABLED
	hud.hide()
	await process_frame
	await RenderingServer.frame_post_draw
	var background := root.get_texture().get_image()
	hud.show()
	await process_frame
	await RenderingServer.frame_post_draw
	var actual := root.get_texture().get_image()
	actual.save_png(OUT+state+".png")
	var doubled := actual.duplicate() as Image
	doubled.resize(1280,720,Image.INTERPOLATE_NEAREST)
	doubled.save_png(OUT+state+"-2x.png")
	var viewport := SubViewport.new()
	viewport.size = Vector2i(640,360)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var outcome: bool = hud.get_node("OutcomePanel").visible
	var oracle: Control
	if outcome:
		oracle = OUTCOME_ORACLE.Outcome.new()
		oracle.state = state
	else:
		oracle = HUD_ORACLE.Matched.new()
		oracle.fit = "six"
		oracle.variant = "C"
		oracle.fire_mode = "auto"
		oracle.state = "combat"
		oracle.record = {
			"life": level.get_node("Operative/Operative").health,
			"boss": level.get_node("BossSlot/DefenseMech").health,
			"max": level.get_node("BossSlot/DefenseMech").max_health,
			"boss_visible": hud.get_node("MechProgress").visible,
		}
	viewport.add_child(oracle)
	oracle.background = ImageTexture.create_from_image(background)
	await process_frame
	await RenderingServer.frame_post_draw
	var expected := viewport.get_texture().get_image()
	expected.save_png(OUT+state+"-approved-overlay.png")
	actual.convert(Image.FORMAT_RGBA8)
	expected.convert(Image.FORMAT_RGBA8)
	var actual_bytes := actual.get_data()
	var expected_bytes := expected.get_data()
	var changed := 0
	var bounds := Rect2i()
	var material_changes := 0
	var max_delta := 0
	for y in 360:
		for x in 640:
			var i := (y*640+x)*4
			var delta := maxi(absi(actual_bytes[i]-expected_bytes[i]), maxi(
				absi(actual_bytes[i+1]-expected_bytes[i+1]), absi(actual_bytes[i+2]-expected_bytes[i+2])))
			max_delta = maxi(max_delta, delta)
			# Only source-texture samples and the re-quantized outcome background
			# permit tiny color differences. Flat HUD geometry remains exact.
			var tolerance := 1 if outcome else 0
			if outcome and (Rect2i(176,88,288,16).has_point(Vector2i(x,y)) or Rect2i(176,220,288,16).has_point(Vector2i(x,y))):
				tolerance = 5
			elif not outcome and (Rect2i(16,296,48,48).has_point(Vector2i(x,y)) or Rect2i(70,298,76,24).has_point(Vector2i(x,y))):
				tolerance = 3
			if delta > tolerance:
				material_changes += 1
			if actual_bytes[i] != expected_bytes[i] or actual_bytes[i+1] != expected_bytes[i+1] or actual_bytes[i+2] != expected_bytes[i+2]:
				changed += 1
				bounds = Rect2i(x,y,1,1) if changed == 1 else bounds.merge(Rect2i(x,y,1,1))
	comparisons.append({"state":state,"changed_pixels":changed,"material_changes":material_changes,"max_channel_delta":max_delta,"bounds":str(bounds)})
	print("CAPTURE ",state,": ",changed," quantization/sample differences, ",material_changes," material differences, max delta ",max_delta)
	viewport.queue_free()
	await process_frame
	level.process_mode = Node.PROCESS_MODE_INHERIT


func _finish() -> void:
	for comparison in comparisons:
		if comparison.material_changes > 0:
			push_error("Approved UI visual mismatch: "+comparison.state)
			quit(1)
			return
	quit(0)
