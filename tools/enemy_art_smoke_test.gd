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

	if boss.using_sprite_art:
		push_error("enemy_art_smoke_test: Big Bad Burger should remain procedural until its sheet exists")
		quit(1)
		return

	print("enemy_art_smoke_test: burger_sprite=true texture_size=", burger.sprite.texture.get_size(), " fry_sprite=true texture_size=", fry.sprite.texture.get_size(), " boss_sprite=false")
	quit()
