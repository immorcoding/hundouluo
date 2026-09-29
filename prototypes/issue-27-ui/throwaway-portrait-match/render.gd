extends SceneTree
# THROWAWAY: restore the exact old portrait, keep S6/S4 proportions, reduce casings.
const FITS := preload("res://prototypes/issue-27-ui/throwaway-pixel-fit/render.gd")
const OUT := "res://prototypes/issue-27-ui/throwaway-portrait-match/"

class Matched extends FITS.PixelFit:
	var weapon: Texture2D
	var weapon_region: Rect2
	func _ready() -> void:
		super()
		var source := Image.load_from_file("res://prototypes/issue-27-ui/throwaway-portrait-match/source/rifle.png")
		weapon_region = Rect2(136,118,1928,540) # Trim transparent source padding; PNG unchanged.
		weapon = ImageTexture.create_from_image(source)
	func helmet(at: Vector2) -> void:
		# EXACT source, crop and 48x48 size from 1137dda. Position only changes.
		draw_texture_rect_region(portrait,Rect2(at,Vector2(48,48)),Rect2(310,184,656,632))
	func rifle(at: Vector2) -> void:
		draw_texture_rect_region(weapon,Rect2(at,Vector2(76,24)),weapon_region)
	func shell(at: Vector2, filled: bool) -> void:
		# 18x7 instead of 22x9; retain horizontal casing / vertical stack.
		draw_set_transform(at)
		var brass := Color("c9975f")
		draw_rect(Rect2(0,2,3,3),brass)
		draw_rect(Rect2(3,1,13,5),brass)
		draw_rect(Rect2(16,0,2,7),Color("e5b77b"))
		if filled:
			draw_rect(Rect2(4,1,10,1),Color("ffe0a2"))
			draw_rect(Rect2(4,5,11,1),Color("8e633d"))
		else:
			draw_rect(Rect2(4,2,11,3),DARK)
		draw_rect(Rect2(0,3,2,1),DARK)
		draw_set_transform(Vector2.ZERO)
	func _draw() -> void:
		draw_texture(background,Vector2.ZERO)
		var small := fit=="four"
		var box := Rect2(4,292,184,64) if small else Rect2(6,286,192,68)
		round_frame(box)
		var p := box.position
		# Both fits have room for the old 48x48 face without touching the life/weapon.
		draw_rect(Rect2(p+Vector2(8,8),Vector2(52,52)),SHADE)
		draw_rect(Rect2(p+Vector2(10,10),Vector2(48,48)),DARK)
		helmet(p+Vector2(10,10))
		var mid := p+Vector2(62 if small else 64,12)
		rifle(mid)
		for i in 3:
			shell(p+Vector2(156 if small else 164,10+i*10),fire_mode=="auto" or i==0)
		var w := 34 if small else 36
		var h := 10 if small else 12
		for i in 3:
			var r := Rect2(p+Vector2((62 if small else 64)+i*(w+4),44 if small else 48),Vector2(w,h))
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
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(FITS.PREVIOUS.BASE.OLD.DIR+"captures/states.json"))
	for state in ["normal","combat","low","gap-left"]:
		for mode in ["semi","auto"]:
			for fit in ["six","four"]:
				root.content_scale_size=Vector2i(640,360)
				var ui := Matched.new()
				ui.fit=fit
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
			for pair in [["six","six"],["four","four"],["six","four"]]:
				root.content_scale_size=Vector2i(1280,360)
				var both:=Control.new()
				root.add_child(both)
				for i in 2:
					var directory: String = FITS.OUT if i==0 and pair[0]==pair[1] else OUT
					var pic:=TextureRect.new()
					pic.texture=ImageTexture.create_from_image(Image.load_from_file(directory+"images/"+pair[i]+"-"+mode+"-"+state+".png"))
					pic.position=Vector2(i*640,0)
					both.add_child(pic)
				await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(OUT+"images/compare-"+pair[0]+"-"+pair[1]+"-"+mode+"-"+state+".png")
				both.queue_free()
				await process_frame
	quit()
