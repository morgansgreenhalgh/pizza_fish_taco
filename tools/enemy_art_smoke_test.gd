extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var enemy_script := load("res://scripts/Enemy.gd")
	var burger = enemy_script.new()
	burger.configure("burger_grunt", null)
	root.add_child(burger)
	await process_frame

	if not burger.using_sprite_art:
		push_error("enemy_art_smoke_test: Burger Grunt fell back to procedural shapes")
		quit(1)
		return

	var fry = enemy_script.new()
	fry.configure("fry_goblin", null)
	root.add_child(fry)
	await process_frame

	if not fry.using_sprite_art:
		push_error("enemy_art_smoke_test: Fry Goblin fell back to procedural shapes")
		quit(1)
		return

	var boss = enemy_script.new()
	boss.configure("big_bad_burger", null)
	root.add_child(boss)
	await process_frame

	if not boss.using_sprite_art:
		push_error("enemy_art_smoke_test: Big Bad Burger fell back to procedural shapes")
		quit(1)
		return
	if burger.sprite.scale.x >= 1.0:
		push_error("enemy_art_smoke_test: Burger Grunt sprite should be slightly scaled down")
		quit(1)
		return
	if fry.sprite.scale.x >= burger.sprite.scale.x:
		push_error("enemy_art_smoke_test: Fry Goblin should be smaller than Burger Grunt")
		quit(1)
		return
	if boss.sprite.scale.x <= 1.0:
		push_error("enemy_art_smoke_test: Big Bad Burger should be scaled up for boss presence")
		quit(1)
		return
	if boss.health_back.position.y > -110:
		push_error("enemy_art_smoke_test: Boss health bar overlaps imported boss sprite")
		quit(1)
		return

	print("enemy_art_smoke_test: burger_scale=", burger.sprite.scale, " fry_scale=", fry.sprite.scale, " boss_scale=", boss.sprite.scale, " boss_health_y=", boss.health_back.position.y)
	quit()
