extends Area2D
class_name Pickup

signal collected(pickup: Pickup, body: Node)

var pickup_type := "score"
var value := 100
var base_y := 0.0
var drift_time := 0.0

func configure(kind: String, amount: int) -> void:
	pickup_type = kind
	value = amount

func _ready() -> void:
	collision_layer = 16
	collision_mask = 2
	monitoring = true
	body_entered.connect(_on_body_entered)
	base_y = position.y
	_build_collision()
	_build_art()

func _process(delta: float) -> void:
	drift_time += delta * 4.0
	position.y = base_y + sin(drift_time) * 5.0

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	collected.emit(self, body)
	queue_free()

func _build_collision() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 18
	shape.shape = circle
	add_child(shape)

func _build_art() -> void:
	var color := Color("#ffe071")
	var icon_color := Color("#160707")
	if pickup_type == "health":
		color = Color("#69ff7b")
		icon_color = Color("#1a0710")
	elif pickup_type == "special":
		color = Color("#34c9ff")
		icon_color = Color("#0d1330")
	var points := PackedVector2Array()
	for i in range(24):
		var angle := TAU * i / 24.0
		points.append(Vector2(cos(angle), sin(angle)) * 18)
	var disc := Polygon2D.new()
	disc.polygon = points
	disc.color = color
	add_child(disc)
	var outline := Line2D.new()
	outline.points = points
	outline.closed = true
	outline.width = 4
	outline.default_color = Color("#160707")
	add_child(outline)
	if pickup_type == "health":
		_add_rect(Vector2(-3, -10), Vector2(6, 20), icon_color)
		_add_rect(Vector2(-10, -3), Vector2(20, 6), icon_color)
	elif pickup_type == "special":
		var swirl := Line2D.new()
		swirl.width = 4
		swirl.default_color = icon_color
		swirl.points = PackedVector2Array([Vector2(-9, 3), Vector2(-4, -6), Vector2(5, -7), Vector2(10, 1), Vector2(4, 8)])
		add_child(swirl)
	else:
		_add_rect(Vector2(-8, -7), Vector2(16, 14), icon_color)

func _add_rect(pos: Vector2, size: Vector2, color: Color) -> void:
	var rect := ColorRect.new()
	rect.position = pos
	rect.size = size
	rect.color = color
	add_child(rect)
