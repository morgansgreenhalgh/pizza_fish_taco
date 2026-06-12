extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var hud_script := load("res://scripts/HUD.gd")
	var hud: CanvasLayer = hud_script.new()
	root.add_child(hud)
	await process_frame
	hud.update_player(90, 120, 2, 75, 100)
	hud.update_score(1250)
	hud.update_boss("Big Bad Burger", 130, 260, true)

	if hud.health_bar.size.x <= 0 or hud.special_bar.size.x <= 0:
		push_error("ui_smoke_test: HUD bars did not update")
		quit(1)
		return
	if hud.boss_bar.size.x <= 0 or not hud.boss_frame.visible:
		push_error("ui_smoke_test: boss HUD did not update")
		quit(1)
		return
	if _count_labels(hud) < 8:
		push_error("ui_smoke_test: HUD label count unexpectedly low")
		quit(1)
		return

	var main_script := load("res://scripts/Main.gd")
	var main: Node2D = main_script.new()
	root.add_child(main)
	await process_frame
	var menu_labels := _collect_labels(main)
	if not menu_labels.has("PIZZA FISH TACO") or not menu_labels.has("PRESS ENTER / START"):
		push_error("ui_smoke_test: menu labels missing")
		quit(1)
		return

	print("ui_smoke_test: hud_labels=", _count_labels(hud), " menu_labels=", menu_labels)
	quit()

func _count_labels(node: Node) -> int:
	var total := 0
	for child in node.get_children():
		if child is Label:
			total += 1
		total += _count_labels(child)
	return total

func _collect_labels(node: Node) -> Array[String]:
	var labels: Array[String] = []
	for child in node.get_children():
		if child is Label:
			labels.append(child.text)
		labels.append_array(_collect_labels(child))
	return labels
