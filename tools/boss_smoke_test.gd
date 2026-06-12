extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var level: Node = load("res://scenes/Level.tscn").instantiate()
	root.add_child(level)
	await process_frame
	await physics_frame

	level.player.global_position.x = 2520
	await create_timer(1.2).timeout

	var boss_count := 0
	for enemy in get_nodes_in_group("enemies"):
		if enemy.is_boss:
			boss_count += 1
	print("boss_smoke_test: boss_count=", boss_count, " gate_locked=", level.gate_locked)
	quit()
