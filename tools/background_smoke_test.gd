extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var level: Node = load("res://scenes/Level.tscn").instantiate()
	root.add_child(level)
	await process_frame

	if not level.using_illustrated_background:
		push_error("background_smoke_test: illustrated background plates did not load")
		quit(1)
		return
	var background_sprites := _count_background_sprites(level)
	if background_sprites < 4:
		push_error("background_smoke_test: expected four illustrated background plates")
		quit(1)
		return
	if level.get_child_count() < 12:
		push_error("background_smoke_test: level child count unexpectedly low")
		quit(1)
		return

	print("background_smoke_test: illustrated=true plates=", background_sprites, " child_count=", level.get_child_count())
	quit()

func _count_background_sprites(root_node: Node) -> int:
	var total := 0
	for child in root_node.get_children():
		if child is Sprite2D:
			total += 1
		total += _count_background_sprites(child)
	return total
