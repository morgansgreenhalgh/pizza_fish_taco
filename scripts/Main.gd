extends Node2D

const LevelScene := preload("res://scenes/Level.tscn")
const InputSetupScript := preload("res://scripts/InputSetup.gd")

var current_level: Node
var menu_root: CanvasLayer
var game_over_root: CanvasLayer
var last_score := 0

func _ready() -> void:
	InputSetupScript.configure()
	_show_menu()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("start"):
		if menu_root:
			_start_level()
		elif game_over_root:
			_show_menu()

func _show_menu() -> void:
	_clear_game_over()
	_clear_level()
	menu_root = CanvasLayer.new()
	add_child(menu_root)
	_add_rect(menu_root, Vector2.ZERO, Vector2(960, 540), Color("#180716"))
	_add_rect(menu_root, Vector2(0, 448), Vector2(960, 92), Color("#3b1814"))
	_add_label(menu_root, "PIZZA FISH TACO", Vector2(480, 84), 48, Color.WHITE, true)
	_add_label(menu_root, "DEFENDS THE PLANET", Vector2(480, 140), 28, Color("#37e6ff"), true)
	_add_menu_hero(menu_root, Vector2(480, 280))
	_add_label(menu_root, "SNACK CITY STREETS\nPress Enter or Start", Vector2(480, 398), 24, Color("#ffe964"), true)
	_add_label(menu_root, "Move: A/D or Arrows | Jump: Space | Combo: J | Heavy: K | Sauce Spin: L", Vector2(480, 494), 15, Color.WHITE, true)
	_add_label(menu_root, "Pad: Left Stick/D-pad | A Jump | X Combo | B Heavy | Y/RB Sauce Spin", Vector2(480, 518), 14, Color("#37e6ff"), true)

func _start_level() -> void:
	if menu_root:
		menu_root.queue_free()
		menu_root = null
	_clear_game_over()
	current_level = LevelScene.instantiate()
	add_child(current_level)
	current_level.level_finished.connect(_on_level_finished)

func _on_level_finished(won: bool, score: int) -> void:
	last_score = score
	_clear_level()
	_show_game_over(won)

func _show_game_over(won: bool) -> void:
	game_over_root = CanvasLayer.new()
	add_child(game_over_root)
	_add_rect(game_over_root, Vector2.ZERO, Vector2(960, 540), Color("#0e2316") if won else Color("#1a0710"))
	_add_label(game_over_root, "SNACK CITY SAVED!" if won else "PIZZA FISH TACO FELL", Vector2(480, 170), 42, Color("#69ff7b") if won else Color("#ff5555"), true)
	_add_label(game_over_root, "Score %d" % last_score, Vector2(480, 260), 28, Color.WHITE, true)
	_add_label(game_over_root, "Press Enter or Start to return to menu", Vector2(480, 346), 22, Color("#ffe964"), true)

func _clear_level() -> void:
	if current_level:
		current_level.queue_free()
		current_level = null

func _clear_game_over() -> void:
	if game_over_root:
		game_over_root.queue_free()
		game_over_root = null

func _add_menu_hero(parent: Node, center: Vector2) -> void:
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([center + Vector2(-95, -45), center + Vector2(80, -45), center + Vector2(105, 38), center + Vector2(-85, 54), center + Vector2(-112, 0)])
	body.color = Color("#f0a736")
	parent.add_child(body)
	var top := Polygon2D.new()
	top.polygon = PackedVector2Array([center + Vector2(-88, -56), center + Vector2(65, -120), center + Vector2(114, -38)])
	top.color = Color("#f14120")
	parent.add_child(top)
	_add_label(parent, "><", center + Vector2(-2, -12), 44, Color("#160707"), true)

func _add_label(parent: Node, text: String, pos: Vector2, size: int, color: Color, centered := false) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 4)
	label.add_theme_constant_override("shadow_offset_y", 4)
	if centered:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.size = Vector2(860, 80)
		label.position.x -= 430
	parent.add_child(label)
	return label

func _add_rect(parent: Node, pos: Vector2, size: Vector2, color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.position = pos
	rect.size = size
	rect.color = color
	parent.add_child(rect)
	return rect
