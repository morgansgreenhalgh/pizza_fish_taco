extends Node2D

const LevelScene := preload("res://scenes/Level.tscn")
const InputSetupScript := preload("res://scripts/InputSetup.gd")

var current_level: Node
var menu_root: CanvasLayer
var game_over_root: CanvasLayer
var last_score := 0
var last_lives := 0

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
	_add_menu_backdrop(menu_root)
	_add_label(menu_root, "PIZZA FISH TACO", Vector2(480, 56), 52, Color.WHITE, true)
	_add_label(menu_root, "DEFENDS THE PLANET", Vector2(480, 116), 28, Color("#37e6ff"), true)
	_add_label(menu_root, "SNACK CITY STREETS", Vector2(480, 152), 19, Color("#ffe964"), true)
	_add_menu_hero(menu_root, Vector2(480, 292))
	_add_framed_prompt(menu_root, Vector2(318, 408), Vector2(324, 54), "PRESS ENTER / START")
	_add_label(menu_root, "A/D MOVE   SPACE JUMP   J BITE   K HEAVY   L SAUCE", Vector2(480, 492), 14, Color.WHITE, true)
	_add_label(menu_root, "CONTROLLER READY", Vector2(480, 516), 14, Color("#69ff7b"), true)

func _start_level() -> void:
	if menu_root:
		menu_root.queue_free()
		menu_root = null
	_clear_game_over()
	current_level = LevelScene.instantiate()
	add_child(current_level)
	current_level.level_finished.connect(_on_level_finished)
	current_level.restart_requested.connect(_restart_level)
	current_level.menu_requested.connect(_show_menu)

func _on_level_finished(won: bool, score: int, lives: int) -> void:
	last_score = score
	last_lives = lives
	_clear_level()
	_show_game_over(won)

func _restart_level() -> void:
	_clear_level()
	_start_level()

func _show_game_over(won: bool) -> void:
	game_over_root = CanvasLayer.new()
	add_child(game_over_root)
	_add_menu_backdrop(game_over_root, Color("#0e2316") if won else Color("#1a0710"))
	_add_rect(game_over_root, Vector2(228, 122), Vector2(504, 278), Color(0.05, 0.02, 0.05, 0.82), Color("#f7dfb4"), 4)
	_add_label(game_over_root, "SNACK CITY SAVED!" if won else "PIZZA FISH TACO FELL", Vector2(480, 158), 38, Color("#69ff7b") if won else Color("#ff5555"), true)
	_add_label(game_over_root, "SCORE %06d" % last_score, Vector2(480, 242), 28, Color.WHITE, true)
	if won:
		_add_label(game_over_root, "LIVES BONUS x%d" % last_lives, Vector2(480, 292), 20, Color("#ffe964"), true)
	_add_framed_prompt(game_over_root, Vector2(316, 336), Vector2(328, 48), "ENTER / START")

func _clear_level() -> void:
	if current_level:
		current_level.queue_free()
		current_level = null

func _clear_game_over() -> void:
	if game_over_root:
		game_over_root.queue_free()
		game_over_root = null

func _add_menu_hero(parent: Node, center: Vector2) -> void:
	_add_circle(parent, center + Vector2(-8, 8), 126, Color(0.96, 0.18, 0.1, 0.16))
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([center + Vector2(-95, -45), center + Vector2(80, -45), center + Vector2(105, 38), center + Vector2(-85, 54), center + Vector2(-112, 0)])
	body.color = Color("#f0a736")
	parent.add_child(body)
	_add_line(parent, body.polygon, Color("#160707"), 6, true)
	var top := Polygon2D.new()
	top.polygon = PackedVector2Array([center + Vector2(-88, -56), center + Vector2(65, -120), center + Vector2(114, -38)])
	top.color = Color("#f14120")
	parent.add_child(top)
	_add_line(parent, top.polygon, Color("#160707"), 6, true)
	_add_circle(parent, center + Vector2(-34, -10), 13, Color.WHITE, Color("#160707"), 4)
	_add_circle(parent, center + Vector2(24, -10), 13, Color.WHITE, Color("#160707"), 4)
	_add_circle(parent, center + Vector2(-29, -8), 5, Color("#160707"))
	_add_circle(parent, center + Vector2(19, -8), 5, Color("#160707"))
	_add_rect(parent, center + Vector2(-32, 22), Vector2(62, 18), Color("#fff2e2"), Color("#160707"), 4)
	_add_line(parent, PackedVector2Array([center + Vector2(-50, -32), center + Vector2(-20, -46)]), Color("#160707"), 4)
	_add_line(parent, PackedVector2Array([center + Vector2(48, -34), center + Vector2(15, -46)]), Color("#160707"), 4)

func _add_menu_backdrop(parent: Node, tint := Color("#180716")) -> void:
	_add_rect(parent, Vector2.ZERO, Vector2(960, 540), tint)
	_add_rect(parent, Vector2(0, 64), Vector2(960, 212), Color(0.18, 0.04, 0.14, 0.76))
	for i in range(7):
		var x := i * 150 - 20
		_add_rect(parent, Vector2(x, 116 + (i % 3) * 20), Vector2(112, 190), Color("#25091c"))
		for j in range(3):
			_add_rect(parent, Vector2(x + 16 + j * 30, 154), Vector2(14, 72), Color(0.07, 0.78, 0.9, 0.26))
	for i in range(4):
		var x := 150 + i * 200
		_add_rect(parent, Vector2(x, 342), Vector2(132, 50), Color("#6b331c"), Color("#1b0908"), 4)
	_add_rect(parent, Vector2(0, 448), Vector2(960, 92), Color("#3b1814"), Color("#efac4f"), 4)
	_add_rect(parent, Vector2(0, 448), Vector2(960, 10), Color("#ffcf55"))

func _add_framed_prompt(parent: Node, pos: Vector2, size: Vector2, text: String) -> void:
	_add_rect(parent, pos, size, Color("#13070b"), Color("#ffe964"), 4)
	_add_label(parent, text, pos + Vector2(size.x * 0.5, 11), 21, Color("#ffe964"), true)

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

func _add_rect(parent: Node, pos: Vector2, size: Vector2, color: Color, outline := Color.TRANSPARENT, outline_width := 0) -> ColorRect:
	var rect := ColorRect.new()
	rect.position = pos
	rect.size = size
	rect.color = color
	parent.add_child(rect)
	if outline_width > 0:
		_add_line(parent, PackedVector2Array([pos, pos + Vector2(size.x, 0), pos + size, pos + Vector2(0, size.y)]), outline, outline_width, true)
	return rect

func _add_circle(parent: Node, pos: Vector2, radius: float, color: Color, outline := Color.TRANSPARENT, outline_width := 0) -> void:
	var points := PackedVector2Array()
	for i in range(24):
		var angle := TAU * i / 24.0
		points.append(pos + Vector2(cos(angle), sin(angle)) * radius)
	var poly := Polygon2D.new()
	poly.polygon = points
	poly.color = color
	parent.add_child(poly)
	if outline_width > 0:
		_add_line(parent, points, outline, outline_width, true)

func _add_line(parent: Node, points: PackedVector2Array, color: Color, width := 3.0, closed := false) -> void:
	var line := Line2D.new()
	line.points = points
	line.closed = closed
	line.width = width
	line.default_color = color
	parent.add_child(line)
