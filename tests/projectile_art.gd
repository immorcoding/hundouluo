extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var friendly := (load("res://scenes/friendly_projectile.tscn") as PackedScene).instantiate() as Area2D
	var soldier := (load("res://scenes/enemy_projectile.tscn") as PackedScene).instantiate() as Area2D
	var mech := (load("res://scenes/enemy_projectile.tscn") as PackedScene).instantiate() as Area2D
	mech.visual_variant = 1
	root.add_child(friendly)
	root.add_child(soldier)
	root.add_child(mech)
	var friendly_sprite := friendly.get_node_or_null("Sprite") as Sprite2D
	var soldier_sprite := soldier.get_node_or_null("Sprite") as Sprite2D
	var mech_sprite := mech.get_node_or_null("Sprite") as Sprite2D
	if friendly_sprite == null or soldier_sprite == null or mech_sprite == null:
		_fail("三类弹丸须显示获批图集")
		return
	if friendly_sprite.texture == null or soldier_sprite.texture == null or mech_sprite.texture == null \
			or friendly_sprite.frame != 0 or soldier_sprite.frame != 4 or mech_sprite.frame != 8:
		_fail("己方、机械兵、防御机甲须分别使用独立轮廓")
		return
	if friendly.collision_layer != 8 or friendly.collision_mask != 6 \
			or soldier.collision_layer != 16 or soldier.collision_mask != 5 \
			or mech.collision_layer != soldier.collision_layer or mech.collision_mask != soldier.collision_mask:
		_fail("视觉变体不得改变碰撞契约")
		return
	for frame in 6:
		await physics_frame
	if friendly_sprite.frame == 0 or soldier_sprite.frame == 4 or mech_sprite.frame == 8:
		_fail("弹丸应有可见的短帧循环")
		return
	print("PASS: 三类获批弹丸轮廓、循环及原碰撞层")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
