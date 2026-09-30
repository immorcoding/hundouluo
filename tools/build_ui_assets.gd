extends SceneTree
# Offline slicing only. No prototype script is loaded by the production HUD.
const OUTPUT := "res://assets/ui_v011/"

class Slice extends Control:
	var part := "hud"
	const DARK := Color("09141f")
	const SHADE := Color("2d4959")
	func _ready() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	func _draw() -> void:
		if part == "hud":
			draw_rect(Rect2(4,0,184,68),DARK)
			draw_rect(Rect2(0,4,192,60),DARK)
			draw_rect(Rect2(2,2,188,64),SHADE)
			draw_rect(Rect2(4,4,184,60),Color("142632"))
			for run in [Vector2(6,18),Vector2(32,40),Vector2(166,20)]:
				draw_rect(Rect2(run.x,2,run.y,1),Color("688290"))
			draw_rect(Rect2(2,6,1,56),Color("688290"))
			draw_rect(Rect2(8,8,52,52),SHADE)
			draw_rect(Rect2(10,10,48,48),DARK)
			for i in 3:
				var at := Vector2(164,10+i*10)
				draw_rect(Rect2(at+Vector2(0,2),Vector2(3,3)),Color("c9975f"))
				draw_rect(Rect2(at+Vector2(3,1),Vector2(13,5)),Color("c9975f"))
				draw_rect(Rect2(at+Vector2(16,0),Vector2(2,7)),Color("e5b77b"))
				draw_rect(Rect2(at+Vector2(4,1),Vector2(10,1)),Color("ffe0a2"))
				draw_rect(Rect2(at+Vector2(4,5),Vector2(11,1)),Color("8e633d"))
				draw_rect(Rect2(at+Vector2(0,3),Vector2(2,1)),DARK)
		elif part.begins_with("life"):
			draw_rect(Rect2(0,0,38,14),SHADE)
			draw_rect(Rect2(1,1,36,12),DARK)
			if part == "life-full":
				draw_rect(Rect2(2,2,34,10),Color("3896a9"))
				draw_rect(Rect2(3,3,32,7),Color("8de9ed"))
				draw_rect(Rect2(3,2,8,1),Color("dce9df"))

func _initialize() -> void:
	call_deferred("_build")

func _build() -> void:
	for part in ["hud","life-full","life-empty"]:
		var viewport := SubViewport.new()
		viewport.size = Vector2i(192,68) if part == "hud" else Vector2i(38,14)
		viewport.transparent_bg = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var slice := Slice.new()
		slice.part = part
		viewport.add_child(slice)
		await process_frame
		await RenderingServer.frame_post_draw
		if viewport.get_texture().get_image().save_png(OUTPUT+part+".png") != OK:
			push_error("Cannot save UI slice: "+part)
			quit(1)
			return
		viewport.queue_free()
		await process_frame

	# Preserve source RGBA; production does one nearest sample and alpha blend.
	for cut in [
		["portrait", "res://prototypes/issue-27-ui/throwaway-ab/source/operative-portrait.png", Rect2i(310,184,656,632)],
		["rifle", "res://prototypes/issue-27-ui/throwaway-portrait-match/source/rifle.png", Rect2i(136,118,1928,540)],
		["outcome-top", "res://prototypes/issue-27-ui/source/console-panel.png", Rect2i(20,92,1734,100)],
		["outcome-bottom", "res://prototypes/issue-27-ui/source/console-panel.png", Rect2i(20,674,1734,100)],
	]:
		var image := Image.load_from_file(cut[1])
		if image.get_region(cut[2]).save_png(OUTPUT+cut[0]+".png") != OK:
			push_error("Cannot save source crop")
			quit(1)
			return
	print("PASS: approved S6 and outcome slices rebuilt")
	quit(0)
