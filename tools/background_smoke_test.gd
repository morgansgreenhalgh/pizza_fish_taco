extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var level: Node = load("res://scenes/Level.tscn").instantiate()
	root.add_child(level)
	await process_frame

	var labels := _collect_labels(level)
	if not labels.has("SNACK CITY"):
		push_error("background_smoke_test: missing Snack City neon sign")
		quit(1)
		return
	if not labels.has("BOSS BITES"):
		push_error("background_smoke_test: missing boss district sign")
		quit(1)
		return
	if level.get_child_count() < 260:
		push_error("background_smoke_test: background detail count unexpectedly low")
		quit(1)
		return

	print("background_smoke_test: labels=", labels, " child_count=", level.get_child_count())
	quit()

func _collect_labels(root_node: Node) -> Array[String]:
	var texts: Array[String] = []
	for child in root_node.get_children():
		if child is Label:
			texts.append(child.text)
		texts.append_array(_collect_labels(child))
	return texts
