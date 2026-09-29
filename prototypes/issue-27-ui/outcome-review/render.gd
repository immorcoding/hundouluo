extends SceneTree
# Design review only. Approved S6 HUD is neither loaded for editing nor changed.
const OUT := "res://prototypes/issue-27-ui/outcome-review/"
class Outcome extends Control:
	var state := "failure"
	var previous := false
	var font: FontFile
	var background: Texture2D
	var metal: Texture2D
	func _ready() -> void:
		texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		font=FontFile.new()
		font.data=FileAccess.get_file_as_bytes("res://prototypes/issue-27-ui/source/fonts/fusion-pixel-12px-proportional-zh_hans.otf")
		font.antialiasing=TextServer.FONT_ANTIALIASING_NONE
		font.hinting=TextServer.HINTING_NONE
		font.subpixel_positioning=TextServer.SUBPIXEL_POSITIONING_DISABLED
		font.oversampling=1
		font.allow_system_fallback=false
		background=ImageTexture.create_from_image(Image.load_from_file(OUT+"captures/"+state+".png"))
		metal=ImageTexture.create_from_image(Image.load_from_file("res://prototypes/issue-27-ui/source/console-panel.png"))
	func center(value: String, y: int, size_px: int, color: Color) -> void:
		var x: float = floor(320-font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_px).x/2)
		draw_string_outline(font,Vector2(x,y),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_px,2,Color("09141f"))
		draw_string(font,Vector2(x,y),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_px,color)
	func _draw() -> void:
		draw_texture(background,Vector2.ZERO)
		var complete := state=="complete"
		var accent := Color("8de9ed") if complete else Color("ffcb7b")
		var reason := "防御机甲已击败" if complete else ("跌落深渊" if state=="fall" else "生命耗尽")
		draw_rect(Rect2(0,0,640,360),Color(0.015,0.035,0.065,0.30 if previous else 0.36))
		if previous:
			center("任务完成" if complete else "任务失败",142,24,accent)
			center(reason,170,12,Color("e5f2f2"))
			draw_rect(Rect2(304,190,32,1),accent)
			center("R 从关卡起点重试",222,12,Color("e5f2f2"))
		else:
			# Retain only upper/lower rails of the accepted metal frame.
			# Open sides, no enclosed panel, badge box or button box.
			draw_texture_rect_region(metal,Rect2(176,88,288,16),Rect2(20,92,1734,100),Color(0.8,0.85,0.9,1))
			draw_texture_rect_region(metal,Rect2(176,220,288,16),Rect2(20,674,1734,100),Color(0.8,0.85,0.9,1))
			center("任务完成" if complete else "任务失败",138,24,accent)
			center(reason,170,12,Color("e5f2f2"))
			center("R 从关卡起点重试",208,12,Color("e5f2f2"))
func _initialize() -> void:
	call_deferred("render")
func render() -> void:
	for state in ["failure","fall","complete"]:
		for version in ["before","after"]:
			root.content_scale_size=Vector2i(640,360)
			var ui:=Outcome.new()
			ui.state=state
			ui.previous=version=="before"
			root.add_child(ui)
			await process_frame
			await RenderingServer.frame_post_draw
			var frame:=root.get_texture().get_image()
			frame.save_png(OUT+"images/"+version+"-"+state+".png")
			frame.resize(1280,720,Image.INTERPOLATE_NEAREST)
			frame.save_png(OUT+"images/"+version+"-"+state+"-2x.png")
			ui.queue_free()
			await process_frame
		root.content_scale_size=Vector2i(1280,360)
		var pair:=Control.new()
		root.add_child(pair)
		for i in 2:
			var image:=TextureRect.new()
			image.position=Vector2(i*640,0)
			image.texture=ImageTexture.create_from_image(Image.load_from_file(OUT+"images/"+("before" if i==0 else "after")+"-"+state+".png"))
			pair.add_child(image)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT+"images/compare-"+state+".png")
		pair.queue_free()
		await process_frame
	quit()
