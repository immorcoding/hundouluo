extends SceneTree
# THROWAWAY compact refinement; the accepted four-zone structure/footprint stays fixed.
const BASE := preload("res://prototypes/issue-27-ui/throwaway-block-layout/render.gd")
const OUT := "res://prototypes/issue-27-ui/throwaway-compact-refine/"

class Refined extends BASE.BlockLayout:
	func bevel(rect: Rect2, color: Color, cut: int) -> void:
		var a := rect.position
		var b := rect.end
		draw_colored_polygon(PackedVector2Array([a+Vector2(cut,0),Vector2(b.x-cut,a.y),Vector2(b.x,a.y+cut),b-Vector2(0,cut),b-Vector2(cut,0),Vector2(a.x+cut,b.y),Vector2(a.x,b.y-cut),a+Vector2(0,cut)]),color)
	func metal(rect: Rect2) -> void:
		bevel(rect, DARK, 4)
		bevel(rect.grow(-1), Color("667f8f"), 3)
		bevel(rect.grow(-2), Color("233b4a"), 3)
		bevel(rect.grow(-4), Color("10202c"), 2)
		draw_rect(Rect2(19,278,190,1),Color("a3b7c3"))
		draw_rect(Rect2(19,345,190,1),Color("07121a"))
		for x in [17,208]:
			for y in [281,341]:
				draw_rect(Rect2(x,y,3,3),DARK)
				draw_rect(Rect2(x,y,2,1),Color("a5b6bf"))
	func gun(at: Vector2, scale_factor: float) -> void:
		super(at,scale_factor)
		# Keep the approved weapon silhouette; add limited material separation.
		gun_part(at,scale_factor,Rect2(13,4,9,1),Color("faf5df"))
		gun_part(at,scale_factor,Rect2(27,2,12,1),Color("cbffff"))
		for x in [33,37,41]:
			gun_part(at,scale_factor,Rect2(x,8,1,3),Color("344754"))
		gun_part(at,scale_factor,Rect2(55,5,1,4),Color("b3c8cf"))
	func shell(at: Vector2, filled: bool) -> void:
		draw_set_transform(at)
		var brass := Color("c9975f")
		draw_rect(Rect2(0,3,4,3),brass)
		draw_rect(Rect2(4,1,15,7),brass)
		draw_rect(Rect2(19,0,3,9),Color("e5b77b"))
		if filled:
			draw_rect(Rect2(5,2,13,1),Color("ffe0a2"))
			draw_rect(Rect2(5,6,13,1),Color("8e633d"))
		else:
			draw_rect(Rect2(5,2,13,5),DARK)
		draw_rect(Rect2(0,4,2,1),DARK)
		draw_rect(Rect2(20,1,1,7),Color("87623f"))
		draw_set_transform(Vector2.ZERO)
	func _draw() -> void:
		draw_texture(background,Vector2.ZERO)
		metal(Rect2(12,276,204,72))
		# Portrait grows 44->48 while its vertical compartment stays inside the old shell.
		draw_rect(Rect2(20,284,52,56),Color("466171"))
		for row in 54:
			var tone := Color("304d5c").lerp(Color("142a37"),row/53.0)
			draw_rect(Rect2(21,285+row,50,1),tone)
		draw_rect(Rect2(23,287,44,1),Color("7998a7"))
		draw_texture_rect_region(portrait,Rect2(22,288,48,48),Rect2(310,184,656,632))
		gun(Vector2(80,292),1.32)
		for i in 3:
			shell(Vector2(180,287+i*10),fire_mode=="auto" or i==0)
		for i in 3:
			var cell := Rect2(80+i*40,326,36,12)
			draw_rect(cell.grow(1),Color("536f7c"))
			draw_rect(cell,DARK)
			if i < record.life:
				draw_rect(cell.grow(-1),Color("78d4d9"))
				draw_rect(Rect2(cell.position+Vector2(1,1),Vector2(34,1)),Color("d1fcf5"))
				draw_rect(Rect2(cell.position+Vector2(1,9),Vector2(34,2)),Color("367c87"))
			else:
				draw_rect(Rect2(cell.position+Vector2(2,9),Vector2(32,1)),Color("233b49"))
		if record.get("boss_visible",true):
			text("防御机甲",224,24,12,WHITE)
			text("%d/%d"%[record.boss,record.max],376,24,12,AMBER)
			progress(224,31,192)

func _initialize() -> void:
	call_deferred("render")
func render() -> void:
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(BASE.OLD.DIR+"captures/states.json"))
	for state in ["normal","combat","low","gap-left"]:
		for mode in ["semi","auto"]:
			for version in ["before","after"]:
				root.content_scale_size=Vector2i(640,360)
				var ui = BASE.BlockLayout.new() if version=="before" else Refined.new()
				ui.variant="C"
				ui.state=state
				ui.record=data[state]
				ui.fire_mode=mode
				root.add_child(ui)
				await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(OUT+"images/"+version+"-"+mode+"-"+state+".png")
				ui.queue_free()
				await process_frame
			root.content_scale_size=Vector2i(1280,360)
			var pair:=Control.new()
			root.add_child(pair)
			for i in 2:
				var picture:=TextureRect.new()
				picture.texture=ImageTexture.create_from_image(Image.load_from_file(OUT+"images/"+("before" if i==0 else "after")+"-"+mode+"-"+state+".png"))
				picture.position=Vector2(i*640,0)
				pair.add_child(picture)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OUT+"images/compare-"+mode+"-"+state+".png")
			pair.queue_free()
			await process_frame
	quit()
