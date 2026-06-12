extends Area2D
class_name AttackHitbox

signal landed(target: Node, hitbox: AttackHitbox)

var damage := 10
var knockback := Vector2(260, -160)
var source_x := 0.0
var owner_node: Node
var hit_targets: Array[Node] = []

func setup(owner: Node, rect_size: Vector2, offset: Vector2, attack_damage: int, attack_knockback: Vector2, lifetime: float, color := Color(1.0, 0.85, 0.25, 0.55)) -> void:
	owner_node = owner
	damage = attack_damage
	knockback = attack_knockback
	source_x = owner.global_position.x
	position = offset
	collision_layer = 8
	collision_mask = 4
	monitoring = true
	monitorable = false

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = rect_size
	shape.shape = rect
	add_child(shape)
	_build_arc(rect_size, color)

	body_entered.connect(_on_body_entered)
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _on_body_entered(body: Node) -> void:
	if body == owner_node or hit_targets.has(body):
		return
	if body.has_method("receive_damage"):
		hit_targets.append(body)
		body.receive_damage(damage, knockback, source_x)
		landed.emit(body, self)

func _build_arc(rect_size: Vector2, color: Color) -> void:
	var slash := Polygon2D.new()
	var width := rect_size.x
	var height := rect_size.y
	slash.polygon = PackedVector2Array([
		Vector2(-width * 0.5, -height * 0.2),
		Vector2(width * 0.35, -height * 0.5),
		Vector2(width * 0.5, -height * 0.18),
		Vector2(-width * 0.24, height * 0.5),
	])
	slash.color = color
	add_child(slash)
	var line := Line2D.new()
	line.points = slash.polygon
	line.closed = true
	line.width = 3
	line.default_color = Color(1.0, 0.97, 0.72, 0.7)
	add_child(line)
