extends SceneTree

const PickupScene := preload("res://scripts/Pickup.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var level: Node = load("res://scenes/Level.tscn").instantiate()
	root.add_child(level)
	await process_frame
	await physics_frame

	level.player.health = 40
	level.player.special = 10
	_collect(level, _fake_pickup("health", 25, level.player.global_position))
	_collect(level, _fake_pickup("special", 30, level.player.global_position))
	_collect(level, _fake_pickup("score", 250, level.player.global_position))
	print("pickup_smoke_test: health=", level.player.health, " special=", level.player.special, " score=", level.player.score)
	quit()

func _collect(level: Node, pickup: Node) -> void:
	level._on_pickup_collected(pickup, level.player)
	pickup.free()

func _fake_pickup(kind: String, value: int, pos: Vector2) -> Node:
	var pickup: Node = PickupScene.new()
	pickup.configure(kind, value)
	pickup.global_position = pos
	return pickup
