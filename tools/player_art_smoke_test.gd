extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var player_art_script := load("res://scripts/PlayerArt.gd")
	var player_art: Node2D = player_art_script.new()
	root.add_child(player_art)
	await process_frame

	if not player_art.using_sprite_art:
		push_error("player_art_smoke_test: PlayerArt fell back to procedural shapes")
		quit(1)
		return

	var texture_size: Vector2 = player_art.sprite.texture.get_size()
	print("player_art_smoke_test: using_sprite_art=true texture_size=", texture_size)
	quit()
