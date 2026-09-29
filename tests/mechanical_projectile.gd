extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1152, 648)
	var encounter := (load("res://tests/mechanical_encounter.tscn") as PackedScene).instantiate()
	var operative := encounter.get_node("Operative/Operative") as CharacterBody2D
	operative.position.x = 0
	root.add_child(encounter)
	var changes: Array[int] = []
	operative.health_changed.connect(func(value: int) -> void: changes.append(value))
	for frame in 110:
		await physics_frame
		if operative.health == 2:
			break
	if operative.health != 2 or changes != [2]:
		_fail("水平敌弹应让行动员只受一次伤害，生命：%s" % [changes])
		return
	for frame in 30:
		await physics_frame
	if operative.health != 2 or changes != [2]:
		_fail("敌弹命中后不得重复提交伤害")
		return
	var hostile := (load("res://scenes/enemy_projectile.tscn") as PackedScene).instantiate() as Area2D
	var friendly := (load("res://scenes/friendly_projectile.tscn") as PackedScene).instantiate() as Area2D
	var hostile_signature := _signature(hostile.get_node("Sprite") as Sprite2D)
	var friendly_signature := _signature(friendly.get_node("Sprite") as Sprite2D)
	if hostile_signature.x <= hostile_signature.y or friendly_signature.y <= friendly_signature.x \
			or hostile_signature.z == friendly_signature.z:
		_fail("敌我弹丸需同时以色彩和形状区分")
		return
	hostile.free()
	friendly.free()
	encounter.queue_free()
	await physics_frame

	encounter = (load("res://tests/mechanical_encounter.tscn") as PackedScene).instantiate()
	operative = encounter.get_node("Operative/Operative") as CharacterBody2D
	operative.position.x = 0
	root.add_child(encounter)
	var soldier := encounter.get_node("Enemies/MechanicalSoldier") as CharacterBody2D
	var warned := false
	for frame in 50:
		await physics_frame
		if soldier.get_node("Muzzle").visible:
			warned = true
			break
	if not warned:
		_fail("无法观察到跳跃前的枪口预告")
		return
	for frame in 8:
		await physics_frame
	Input.action_press("jump")
	await physics_frame
	Input.action_release("jump")
	var projectile_passed := false
	for frame in 85:
		await physics_frame
		for projectile in encounter.get_node("Projectiles").get_children():
			if projectile.global_position.x < operative.global_position.x - 15.0:
				projectile_passed = true
		if projectile_passed:
			break
	if not projectile_passed or operative.health != 3:
		_fail("跳跃应允许敌弹从行动员脚下通过且不受击")
		return
	print("PASS: 敌弹单次命中、敌我弹丸可区分、预告后可跳跃规避")
	quit(0)


func _fail(message: String) -> void:
	Input.action_release("jump")
	push_error(message)
	quit(1)


func _signature(sprite: Sprite2D) -> Vector3:
	var image := sprite.texture.get_image()
	var red := 0.0
	var blue := 0.0
	var pixels := 0
	var left := 48
	var right := 0
	var origin_y := sprite.frame / 4 * 40
	for y in 40:
		for x in 48:
			var color := image.get_pixel(x, origin_y + y)
			if color.a > 0.3:
				red += color.r
				blue += color.b
				pixels += 1
				left = mini(left, x)
				right = maxi(right, x)
	return Vector3(red / maxf(1, pixels), blue / maxf(1, pixels), right - left + 1)
