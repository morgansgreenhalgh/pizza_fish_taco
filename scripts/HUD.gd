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
	_add_rect(Vector2(0, 0), Vector2(960, 104), Color(0.06, 0.02, 0.06, 0.9))
	_add_rect(Vector2(0, 100), Vector2(960, 4), Color("#35f6ff"))
	_add_rect(Vector2(16, 14), Vector2(88, 84), Color("#13070b"), Color("#f8e6c1"), 4)
	_add_rect(Vector2(22, 20), Vector2(76, 72), Color("#220914"), Color("#35f6ff"), 2)
	_add_portrait(Vector2(60, 56))
	_add_label("PIZZA FISH TACO", Vector2(118, 10), 28, Color.WHITE)
	_add_label("PLANET DEFENDER FLAVOR", Vector2(120, 38), 11, Color("#69ff7b"))
	_add_rect(Vector2(112, 54), Vector2(326, 24), Color("#22111b"), Color("#faf0d7"), 4)
	health_bar = _add_rect(Vector2(116, 61), Vector2(318, 14), Color("#67ef1c"))
	for i in range(1, 14):
		_add_rect(Vector2(116 + i * 22.7, 60), Vector2(2, 16), Color(0.05, 0.2, 0.07, 0.55))
	_add_rect(Vector2(112, 82), Vector2(226, 16), Color("#22111b"), Color("#faf0d7"), 3)
	special_bar = _add_rect(Vector2(115, 86), Vector2(110, 8), Color("#34c9ff"))
	_add_sauce_drop(Vector2(354, 89), 0.42)
	lives_label = _add_label("x3", Vector2(468, 48), 26, Color.WHITE)
	_add_taco_badge(Vector2(450, 60), 0.42)
	score_label = _add_label("SCORE 000000\nLVL 1-1", Vector2(22, 118), 24, Color("#ffe900"))
	_build_minimap()
	_build_ability_bar()
	boss_frame = _add_rect(Vector2(270, 110), Vector2(420, 26), Color("#220914"), Color("#ffd347"), 4)
	boss_bar = _add_rect(Vector2(276, 116), Vector2(0, 14), Color("#ff3847"))
	boss_label = _add_label("", Vector2(480, 80), 20, Color.WHITE, true)
	status_label = _add_label("", Vector2(480, 154), 24, Color("#ffe964"), true)
	status_label.size = Vector2(600, 34)
	status_label.position.x = 180
	status_label.modulate.a = 0.0
	update_boss("", 1, 1, false)

func _build_minimap() -> void:
	_add_rect(Vector2(790, 14), Vector2(166, 82), Color(0.01, 0.01, 0.02, 0.65))
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
		_add_rect(Vector2(x - 31, 449), Vector2(62, 62), Color("#10060f"), Color("#f7dfb4"), 3)
		_add_rect(Vector2(x - 24, 456), Vector2(48, 48), Color("#1e0a17"), colors[i], 2)
		if i == 0:
			_add_bite_icon(Vector2(x, 480), 0.55)
		elif i == 1:
			_add_spin_icon(Vector2(x, 480), 0.58)
		elif i == 2:
			_add_sauce_drop(Vector2(x, 480), 0.55)
		else:
			_add_jump_icon(Vector2(x, 480), 0.56)
		_add_label(labels[i], Vector2(x, 512), 15, Color.WHITE, true)

func _add_portrait(center: Vector2) -> void:
	_add_rect(center + Vector2(-25, -15), Vector2(50, 42), Color("#f0a736"), Color("#160707"), 4)
	_add_polygon(PackedVector2Array([center + Vector2(-28, -20), center + Vector2(18, -34), center + Vector2(31, -6)]), Color("#f14120"), Color("#160707"), 4)
	_add_polygon(PackedVector2Array([center + Vector2(-26, 0), center + Vector2(-48, 10), center + Vector2(-26, 20)]), Color("#ffd86b"), Color("#160707"), 3)
	_add_circle(center + Vector2(-11, 3), 5, Color.WHITE)
	_add_circle(center + Vector2(9, 3), 5, Color.WHITE)
	_add_rect(center + Vector2(-12, 16), Vector2(24, 8), Color("#fff2e2"), Color("#160707"), 3)

func _add_bite_icon(center: Vector2, scale_size: float) -> void:
	_add_polygon(PackedVector2Array([
		center + Vector2(-24, -14) * scale_size,
		center + Vector2(24, -12) * scale_size,
		center + Vector2(18, 18) * scale_size,
		center + Vector2(-22, 16) * scale_size,
	]), Color("#ffd15b"), Color("#160707"), 4)
	_add_rect(center + Vector2(-15, 0) * scale_size, Vector2(30, 8) * scale_size, Color("#fff2e2"), Color("#160707"), 2)

func _add_spin_icon(center: Vector2, scale_size: float) -> void:
	for i in range(3):
		var radius := (18 + i * 8) * scale_size
		_add_arc(center, radius, Color("#34c9ff"), 4.0)
	_add_sauce_drop(center + Vector2(16, -8) * scale_size, 0.24)

func _add_sauce_drop(center: Vector2, scale_size: float) -> void:
	_add_circle(center + Vector2(0, 7) * scale_size, 12 * scale_size, Color("#ff4d27"), Color("#160707"), 3)
	_add_polygon(PackedVector2Array([
		center + Vector2(0, -18) * scale_size,
		center + Vector2(12, 5) * scale_size,
		center + Vector2(-12, 5) * scale_size,
	]), Color("#ff4d27"), Color("#160707"), 3)

func _add_jump_icon(center: Vector2, scale_size: float) -> void:
	_add_polygon(PackedVector2Array([
		center + Vector2(0, -24) * scale_size,
		center + Vector2(18, -2) * scale_size,
		center + Vector2(7, -2) * scale_size,
		center + Vector2(7, 22) * scale_size,
		center + Vector2(-7, 22) * scale_size,
		center + Vector2(-7, -2) * scale_size,
		center + Vector2(-18, -2) * scale_size,
	]), Color("#b05cff"), Color("#160707"), 4)

func _add_taco_badge(center: Vector2, scale_size: float) -> void:
	var points := PackedVector2Array()
	for i in range(16):
		var angle := PI + PI * i / 15.0
		points.append(center + Vector2(cos(angle) * 34, sin(angle) * 22) * scale_size)
	points.append(center + Vector2(34, 4) * scale_size)
	points.append(center + Vector2(-34, 4) * scale_size)
	_add_polygon(points, Color("#f0b14b"), Color("#160707"), 3)

func _add_arc(center: Vector2, radius: float, color: Color, width := 3.0) -> void:
	var points := PackedVector2Array()
	for i in range(22):
		var angle := -PI * 0.82 + PI * 1.58 * i / 21.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	var line := Line2D.new()
	line.points = points
	line.width = width
	line.default_color = color
	add_child(line)

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
