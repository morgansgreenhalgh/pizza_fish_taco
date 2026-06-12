extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var level: Node = load("res://scenes/Level.tscn").instantiate()
	root.add_child(level)
	await process_frame
	await physics_frame

	level.player.global_position.x = 590
	await process_frame
	await physics_frame

	Input.action_press("light_attack")
	await physics_frame
	Input.action_release("light_attack")
	await create_timer(0.7).timeout

	var healths := []
	for enemy in get_nodes_in_group("enemies"):
		healths.append(enemy.health)
	print("combat_smoke_test: enemies=", get_nodes_in_group("enemies").size(), " healths=", healths, " score=", level.player.score)
	quit()
