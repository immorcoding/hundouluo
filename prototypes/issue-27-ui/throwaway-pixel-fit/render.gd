extends SceneTree
# THROWAWAY: close size/margin choices, explicitly clustered native pixels.
const PREVIOUS := preload("res://prototypes/issue-27-ui/throwaway-compact-refine/render.gd")
const OUT := "res://prototypes/issue-27-ui/throwaway-pixel-fit/"

class PixelFit extends PREVIOUS.Refined:
	var fit := "six"
	const STEEL := Color("688290")
	const SHADE := Color("2d4959")
	const LIGHT := Color("dce9df")
	const TEAL := Color("3896a9")
	func helmet(at: Vector2) -> void:
		# Native 40x44 design: 2px stepped masses plus selective 1px edge detail.
		draw_set_transform(at)
		draw_colored_polygon(PackedVector2Array([Vector2(14,2),Vector2(28,2),Vector2(28,4),Vector2(34,4),Vector2(34,8),Vector2(36,8),Vector2(36,12),Vector2(38,12),Vector2(38,30),Vector2(34,30),Vector2(34,36),Vector2(28,36),Vector2(28,40),Vector2(12,40),Vector2(12,38),Vector2(6,38),Vector2(6,30),Vector2(3,30),Vector2(3,14),Vector2(6,14),Vector2(6,8),Vector2(10,8),Vector2(10,4),Vector2(14,4)]),DARK)
		draw_rect(Rect2(14,4,14,4),LIGHT)
		draw_rect(Rect2(10,8,23,5),LIGHT)
		draw_rect(Rect2(7,13,12,8),LIGHT)
		draw_rect(Rect2(16,6,8,2),Color("f2f0dd"))
		draw_rect(Rect2(28,8,5,3),STEEL)
		draw_rect(Rect2(17,13,4,12),STEEL)
		draw_rect(Rect2(20,12,14,3),SHADE)
		draw_rect(Rect2(20,15,16,14),TEAL)
		draw_rect(Rect2(23,29,11,3),TEAL)
		draw_rect(Rect2(23,14,10,3),CYAN)
		draw_rect(Rect2(28,17,7,9),CYAN)
		draw_rect(Rect2(30,17,3,5),LIGHT)
		draw_rect(Rect2(28,22,2,3),CYAN)
		draw_rect(Rect2(20,21,3,7),SHADE)
		draw_rect(Rect2(23,28,4,3),SHADE)
		draw_rect(Rect2(6,21,10,10),STEEL)
		draw_rect(Rect2(5,23,12,6),LIGHT)
		draw_rect(Rect2(8,21,6,10),LIGHT)
		draw_rect(Rect2(8,23,6,6),DARK)
		draw_rect(Rect2(10,24,2,4),TEAL)
		draw_rect(Rect2(10,24,1,2),CYAN)
		draw_rect(Rect2(15,26,4,7),LIGHT)
		draw_rect(Rect2(18,31,13,3),LIGHT)
		draw_rect(Rect2(22,34,10,2),STEEL)
		draw_rect(Rect2(12,34,4,4),STEEL)
		draw_rect(Rect2(16,36,12,2),LIGHT)
		draw_rect(Rect2(28,38,7,3),LIGHT)
		draw_rect(Rect2(7,38,9,4),SHADE)
		draw_rect(Rect2(9,38,5,1),STEEL)
		draw_rect(Rect2(4,6,2,12),STEEL)
		draw_rect(Rect2(4,5,2,3),Color("c99c65"))
		draw_set_transform(Vector2.ZERO)
	func rifle(at: Vector2) -> void:
		# Fixed 60x18 pixel icon; no fractional scaling or filtered texture.
		for part in [Rect2(0,6,12,6),Rect2(10,4,36,10),Rect2(44,6,16,6),Rect2(18,14,6,4)]:
			draw_rect(Rect2(at+part.position,part.size),SHADE)
		draw_rect(Rect2(at+Vector2(2,6),Vector2(10,4)),LIGHT)
		draw_rect(Rect2(at+Vector2(12,6),Vector2(30,6)),LIGHT)
		draw_rect(Rect2(at+Vector2(24,2),Vector2(20,4)),SHADE)
		draw_rect(Rect2(at+Vector2(26,2),Vector2(14,2)),CYAN)
		draw_rect(Rect2(at+Vector2(14,10),Vector2(26,2)),STEEL)
		draw_rect(Rect2(at+Vector2(46,6),Vector2(10,2)),STEEL)
		for x in [30,36]:
			draw_rect(Rect2(at+Vector2(x,12),Vector2(2,2)),DARK)
	func round_frame(r: Rect2) -> void:
		# Two-step clipped corners and broken highlight runs, all integer rectangles.
		draw_rect(Rect2(r.position+Vector2(4,0),r.size-Vector2(8,0)),DARK)
		draw_rect(Rect2(r.position+Vector2(0,4),r.size-Vector2(0,8)),DARK)
		draw_rect(r.grow(-2),SHADE)
		draw_rect(r.grow(-4),Color("142632"))
		for xw in [Vector2(6,18),Vector2(32,40),Vector2(r.size.x-26,20)]:
			draw_rect(Rect2(r.position+Vector2(xw.x,2),Vector2(xw.y,1)),STEEL)
		draw_rect(Rect2(r.position+Vector2(2,6),Vector2(1,r.size.y-12)),STEEL)
	func _draw() -> void:
		draw_texture(background,Vector2.ZERO)
		var small := fit=="four"
		var box := Rect2(4,292,184,64) if small else Rect2(6,286,192,68)
		round_frame(box)
		var p := box.position
		draw_rect(Rect2(p+Vector2(8,8),Vector2(44,box.size.y-16)),SHADE)
		draw_rect(Rect2(p+Vector2(10,10),Vector2(40,box.size.y-20)),DARK)
		helmet(p+Vector2(10,10))
		var mid := p+Vector2(60 if small else 62,12)
		rifle(mid)
		for i in 3:
			# Existing horizontal casing profile is drawn at native 22x9, no resizing.
			shell(p+Vector2(156 if small else 164,9+i*10),fire_mode=="auto" or i==0)
		var w := 34 if small else 36
		var h := 10 if small else 12
		for i in 3:
			var r := Rect2(p+Vector2((60 if small else 62)+i*(w+4),44 if small else 48),Vector2(w,h))
			draw_rect(r.grow(1),SHADE)
			draw_rect(r,DARK)
			if i < record.life:
				draw_rect(r.grow(-1),TEAL)
				draw_rect(Rect2(r.position+Vector2(2,2),Vector2(w-4,h-5)),CYAN)
				draw_rect(Rect2(r.position+Vector2(2,1),Vector2(8,1)),LIGHT)
		if record.get("boss_visible",true):
			text("防御机甲",224,24,12,WHITE)
			text("%d/%d"%[record.boss,record.max],376,24,12,AMBER)
			progress(224,31,192)

func _initialize() -> void:
	call_deferred("render")
func render() -> void:
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(PREVIOUS.BASE.OLD.DIR+"captures/states.json"))
	for state in ["normal","combat","low","gap-left"]:
		for mode in ["semi","auto"]:
			for fit in ["old","six","four"]:
				root.content_scale_size=Vector2i(640,360)
				var ui = PREVIOUS.Refined.new() if fit=="old" else PixelFit.new()
				if fit!="old":ui.fit=fit
				ui.variant="C"
				ui.state=state
				ui.record=data[state]
				ui.fire_mode=mode
				root.add_child(ui)
				await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(OUT+"images/"+fit+"-"+mode+"-"+state+".png")
				ui.queue_free()
				await process_frame
			for pair in [["old","six"],["six","four"]]:
				root.content_scale_size=Vector2i(1280,360)
				var both:=Control.new()
				root.add_child(both)
				for i in 2:
					var pic:=TextureRect.new()
					pic.texture=ImageTexture.create_from_image(Image.load_from_file(OUT+"images/"+pair[i]+"-"+mode+"-"+state+".png"))
					pic.position=Vector2(i*640,0)
					both.add_child(pic)
				await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(OUT+"images/compare-"+pair[0]+"-"+pair[1]+"-"+mode+"-"+state+".png")
				both.queue_free()
				await process_frame
	quit()
