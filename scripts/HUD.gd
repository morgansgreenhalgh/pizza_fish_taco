extends CanvasLayer
class_name HUD

var health_bar: ColorRect
var special_bar: ColorRect
var lives_label: Label
var score_label: Label
var boss_frame: ColorRect
var boss_bar: ColorRect
var boss_label: Label
var status_label: Label
var status_tween: Tween

func _ready() -> void:
	_build()

func update_player(health: int, max_health: int, lives: int, special: int, max_special: int) -> void:
	health_bar.size.x = 318.0 * float(health) / max_health
	special_bar.size.x = 220.0 * float(special) / max_special
	lives_label.text = "x%d" % lives

func update_score(score: int) -> void:
	score_label.text = "SCORE %06d\nLVL 1-1" % score

func update_boss(name: String, health: int, max_health: int, active: bool) -> void:
	boss_frame.visible = active
	boss_bar.visible = active
	boss_label.visible = active
	boss_label.text = name.to_upper()
	boss_bar.size.x = 412.0 * float(health) / max_health

func show_status(text: String, duration := 1.6, color := Color("#ffe964")) -> void:
	if status_tween:
		status_tween.kill()
	status_label.text = text
	status_label.add_theme_color_override("font_color", color)
	status_label.modulate.a = 1.0
	status_tween = create_tween()
	status_tween.tween_interval(duration)
	status_tween.tween_property(status_label, "modulate:a", 0.0, 0.35)

func _build() -> void:
	_add_rect(Vector2(0, 0), Vector2(960, 96), Color(0.07, 0.03, 0.07, 0.86))
	_add_rect(Vector2(22, 18), Vector2(76, 76), Color("#13070b"), Color("#f8e6c1"), 4)
	_add_portrait(Vector2(60, 56))
	_add_label("PIZZA FISH TACO", Vector2(112, 10), 28, Color.WHITE)
	_add_rect(Vector2(112, 38), Vector2(326, 24), Color("#22111b"), Color("#faf0d7"), 4)
	health_bar = _add_rect(Vector2(116, 45), Vector2(318, 14), Color("#67ef1c"))
	for i in range(1, 14):
		_add_rect(Vector2(116 + i * 22.7, 44), Vector2(2, 16), Color(0.05, 0.2, 0.07, 0.55))
	_add_rect(Vector2(112, 70), Vector2(226, 16), Color("#22111b"), Color("#faf0d7"), 3)
	special_bar = _add_rect(Vector2(115, 74), Vector2(110, 8), Color("#34c9ff"))
	lives_label = _add_label("x3", Vector2(456, 36), 24, Color.WHITE)
	score_label = _add_label("SCORE 000000\nLVL 1-1", Vector2(22, 112), 24, Color("#ffe900"))
	_build_minimap()
	_build_ability_bar()
	boss_frame = _add_rect(Vector2(270, 104), Vector2(420, 24), Color("#220914"), Color("#ffd347"), 4)
	boss_bar = _add_rect(Vector2(276, 109), Vector2(0, 14), Color("#ff3847"))
	boss_label = _add_label("", Vector2(480, 76), 20, Color.WHITE, true)
	status_label = _add_label("", Vector2(480, 154), 24, Color("#ffe964"), true)
	status_label.size = Vector2(600, 34)
	status_label.position.x = 180
	status_label.modulate.a = 0.0
	update_boss("", 1, 1, false)

func _build_minimap() -> void:
	_add_rect(Vector2(802, 18), Vector2(156, 72), Color(0.07, 0.03, 0.05, 0.92), Color("#35f6ff"), 3)
	for i in range(1, 5):
		_add_rect(Vector2(802 + i * 31, 18), Vector2(1, 72), Color(0.06, 0.5, 0.53, 0.55))
	for i in range(1, 3):
		_add_rect(Vector2(802, 18 + i * 24), Vector2(156, 1), Color(0.06, 0.5, 0.53, 0.55))
	_add_rect(Vector2(854, 36), Vector2(34, 30), Color(0.62, 0.17, 0.17, 0.85))
	_add_circle(Vector2(874, 54), 4, Color("#ffd447"))

func _build_ability_bar() -> void:
	var labels := ["BITE", "SPIN", "SAUCE", "JUMP"]
	var colors := [Color("#ffd85c"), Color("#38e6ff"), Color("#ff4d27"), Color("#b05cff")]
	for i in range(4):
		var x := 363 + i * 78
		_add_rect(Vector2(x - 29, 452), Vector2(58, 58), Color("#170b14"), Color("#f7dfb4"), 3)
		_add_circle(Vector2(x, 481), 18, colors[i], Color("#160707"), 5)
		_add_circle(Vector2(x, 481), 8, colors[i])
		_add_label(labels[i], Vector2(x, 512), 15, Color.WHITE, true)

func _add_portrait(center: Vector2) -> void:
	_add_rect(center + Vector2(-24, -16), Vector2(48, 42), Color("#f0a736"), Color("#160707"), 4)
	_add_polygon(PackedVector2Array([center + Vector2(-25, -18), center + Vector2(20, -32), center + Vector2(29, -7)]), Color("#f14120"), Color("#160707"), 4)
	_add_circle(center + Vector2(-11, 3), 5, Color.WHITE)
	_add_circle(center + Vector2(9, 3), 5, Color.WHITE)
	_add_rect(center + Vector2(-12, 16), Vector2(24, 8), Color("#fff2e2"), Color("#160707"), 3)

func _add_label(text: String, pos: Vector2, size: int, color: Color, centered := false) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)
	if centered:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.size = Vector2(160, 30)
		label.position.x -= 80
	add_child(label)
	return label

func _add_rect(pos: Vector2, size: Vector2, color: Color, outline := Color.TRANSPARENT, outline_width := 0) -> ColorRect:
	var rect := ColorRect.new()
	rect.position = pos
	rect.size = size
	rect.color = color
	add_child(rect)
	if outline_width > 0:
		var line := Line2D.new()
		line.points = PackedVector2Array([pos, pos + Vector2(size.x, 0), pos + size, pos + Vector2(0, size.y)])
		line.closed = true
		line.width = outline_width
		line.default_color = outline
		add_child(line)
	return rect

func _add_circle(pos: Vector2, radius: float, color: Color, outline := Color.TRANSPARENT, outline_width := 0) -> void:
	var points := PackedVector2Array()
	for i in range(24):
		var angle := TAU * i / 24.0
		points.append(pos + Vector2(cos(angle), sin(angle)) * radius)
	_add_polygon(points, color, outline, outline_width)

func _add_polygon(points: PackedVector2Array, color: Color, outline := Color.TRANSPARENT, outline_width := 0) -> void:
	var poly := Polygon2D.new()
	poly.polygon = points
	poly.color = color
	add_child(poly)
	if outline_width > 0:
		var line := Line2D.new()
		line.points = points
		line.closed = true
		line.width = outline_width
		line.default_color = outline
		add_child(line)
