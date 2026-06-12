extends CharacterBody2D
class_name Enemy

signal defeated(enemy: Enemy)
signal health_changed(enemy: Enemy, amount: int)
signal attack_started(enemy: Enemy, warning_position: Vector2, warning_size: Vector2)
signal attack_committed(enemy: Enemy)

const GRAVITY := 1900.0

var kind := "burger_grunt"
var display_name := "Burger Grunt"
var health := 42
var max_health := 42
var damage := 10
var move_speed := 95.0
var score_value := 100
var is_boss := false
var is_dead := false
var is_hurt := false
var is_attacking := false
var attack_cooldown_until := 0.0
var attack_serial := 0
var target: Node2D
var facing := -1
var health_back: ColorRect
var health_fill: ColorRect
var retreat_until := 0.0
var next_ai_decision_at := 0.0
var preferred_side := 1
var boss_attack_index := 0

@onready var art_root := Node2D.new()

func _ready() -> void:
	add_to_group("enemies")
	add_child(art_root)
	_apply_kind()
	_build_collision()
	_build_art()
	_build_health_bar()
	_update_health_bar()
	_spawn_pop()

func configure(enemy_kind: String, player: Node2D) -> void:
	kind = enemy_kind
	target = player
	preferred_side = [-1, 1].pick_random()

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity.y += GRAVITY * delta
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if target and not is_hurt and not is_attacking:
		_update_ai(delta)
	elif is_attacking and is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, 1600.0 * delta)

	move_and_slide()

func _update_ai(delta: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var dx := target.global_position.x - global_position.x
	facing = 1 if dx >= 0 else -1
	art_root.scale.x = facing

	var attack_range := 118.0 if is_boss else 62.0
	var crowding := _is_crowded_near_player()
	var desired_speed := move_speed
	if kind == "fry_goblin":
		desired_speed *= 1.08

	if now < retreat_until:
		velocity.x = move_toward(velocity.x, -facing * desired_speed * 0.75, 1400.0 * delta)
		return

	if abs(dx) <= attack_range:
		velocity.x = move_toward(velocity.x, 0.0, 1800.0 * delta)
		_try_attack()
		return

	if not is_boss and crowding:
		velocity.x = move_toward(velocity.x, -facing * desired_speed * 0.45, 1200.0 * delta)
		return

	if not is_boss and now < attack_cooldown_until and abs(dx) < 132.0:
		velocity.x = move_toward(velocity.x, -facing * desired_speed * 0.52, 1200.0 * delta)
		return

	var flank_bias := 0.0
	if not is_boss and abs(dx) < 220.0:
		flank_bias = preferred_side * 42.0
	var desired_x: float = target.global_position.x - facing * (attack_range - 8.0) + flank_bias
	var direction: float = sign(desired_x - global_position.x)
	velocity.x = move_toward(velocity.x, direction * desired_speed, 1300.0 * delta)

func _is_crowded_near_player() -> bool:
	if is_boss or not target:
		return false
	var same_side_count := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == self or not is_instance_valid(enemy) or enemy.is_dead:
			continue
		if abs(enemy.global_position.x - target.global_position.x) < 95.0 and sign(enemy.global_position.x - target.global_position.x) == sign(global_position.x - target.global_position.x):
			same_side_count += 1
	return same_side_count >= 1

func receive_damage(amount: int, knockback: Vector2, source_x: float) -> void:
	if is_dead:
		return

	health = max(0, health - amount)
	var direction := 1 if global_position.x >= source_x else -1
	velocity = Vector2(abs(knockback.x) * direction, knockback.y)
	is_hurt = true
	is_attacking = false
	retreat_until = Time.get_ticks_msec() / 1000.0 + (0.28 if not is_boss else 0.12)
	attack_serial += 1
	art_root.modulate = Color.WHITE
	art_root.rotation_degrees = 0
	health_changed.emit(self, amount)
	_update_health_bar()

	await get_tree().create_timer(0.12).timeout
	art_root.modulate = Color(1, 0.72, 0.62)
	await get_tree().create_timer(0.16).timeout
	is_hurt = false
	art_root.modulate = Color.WHITE

	if health <= 0:
		_die()

func _try_attack() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now < attack_cooldown_until:
		return
	is_attacking = true
	attack_serial += 1
	var this_attack := attack_serial
	var attack := _attack_profile()
	attack_cooldown_until = now + attack.cooldown
	var warning_size: Vector2 = attack.warning_size
	var warning_pos := global_position + Vector2(facing * warning_size.x * 0.45, -6)
	attack_started.emit(self, warning_pos, warning_size)
	art_root.modulate = Color(1.0, 0.38, 0.3) if is_boss else Color(1.0, 0.85, 0.35)
	art_root.rotation_degrees = -attack.windup_tilt * facing
	await get_tree().create_timer(attack.windup).timeout
	if is_dead or is_hurt or this_attack != attack_serial:
		return
	attack_committed.emit(self)
	velocity.x = facing * attack.lunge_speed
	art_root.rotation_degrees = attack.commit_tilt * facing
	if is_boss and attack.name == "sauce_slam":
		velocity.y = -220
	await get_tree().create_timer(attack.commit_time).timeout
	if is_dead or is_hurt or this_attack != attack_serial:
		return
	art_root.modulate = Color.WHITE
	art_root.rotation_degrees = 0

	if target and global_position.distance_to(target.global_position) < attack.hit_distance and target.has_method("receive_damage"):
		target.receive_damage(attack.damage, attack.knockback, global_position.x)
	if not is_boss:
		retreat_until = now + 0.55
	await get_tree().create_timer(attack.recovery).timeout
	if this_attack == attack_serial:
		is_attacking = false

func _attack_profile() -> Dictionary:
	if not is_boss:
		return {
			"name": "bite",
			"cooldown": 1.0 if kind == "fry_goblin" else 1.12,
			"warning_size": Vector2(74, 58),
			"windup": 0.22 if kind == "fry_goblin" else 0.28,
			"commit_time": 0.08,
			"recovery": 0.22,
			"lunge_speed": 210 if kind == "fry_goblin" else 170,
			"damage": damage,
			"knockback": Vector2(330, -180),
			"hit_distance": 78,
			"windup_tilt": 8,
			"commit_tilt": 12,
		}

	boss_attack_index = (boss_attack_index + 1) % 3
	if boss_attack_index == 0:
		return {
			"name": "mega_chomp",
			"cooldown": 1.55,
			"warning_size": Vector2(142, 98),
			"windup": 0.42,
			"commit_time": 0.1,
			"recovery": 0.22,
			"lunge_speed": 270,
			"damage": 18,
			"knockback": Vector2(520, -260),
			"hit_distance": 136,
			"windup_tilt": 8,
			"commit_tilt": 12,
		}
	if boss_attack_index == 1:
		return {
			"name": "burger_charge",
			"cooldown": 1.8,
			"warning_size": Vector2(196, 82),
			"windup": 0.52,
			"commit_time": 0.16,
			"recovery": 0.32,
			"lunge_speed": 460,
			"damage": 20,
			"knockback": Vector2(680, -210),
			"hit_distance": 168,
			"windup_tilt": 4,
			"commit_tilt": 18,
		}
	return {
		"name": "sauce_slam",
		"cooldown": 2.0,
		"warning_size": Vector2(174, 126),
		"windup": 0.62,
		"commit_time": 0.18,
		"recovery": 0.38,
		"lunge_speed": 120,
		"damage": 24,
		"knockback": Vector2(430, -380),
		"hit_distance": 158,
		"windup_tilt": 12,
		"commit_tilt": 0,
	}

func _die() -> void:
	is_dead = true
	is_attacking = false
	attack_serial += 1
	defeated.emit(self)
	if health_back:
		health_back.visible = false
	art_root.modulate = Color(0.35, 0.35, 0.35)
	velocity = Vector2(0, -260)
	await get_tree().create_timer(0.55).timeout
	queue_free()

func _apply_kind() -> void:
	if kind == "fry_goblin":
		display_name = "Fry Goblin"
		health = 34
		max_health = 34
		damage = 8
		move_speed = 135
		score_value = 125
	elif kind == "big_bad_burger":
		display_name = "Big Bad Burger"
		health = 260
		max_health = 260
		damage = 18
		move_speed = 82
		score_value = 1000
		is_boss = true
	else:
		display_name = "Burger Grunt"

func _build_collision() -> void:
	var collision := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(112, 118) if is_boss else Vector2(58, 64)
	collision.shape = rect
	collision.position = Vector2(0, 4)
	add_child(collision)

func _build_art() -> void:
	var scale_size := 1.9 if is_boss else 1.0
	art_root.scale = Vector2(scale_size, scale_size)
	var bun := Color("#f0b14b")
	var patty := Color("#7d3520") if is_boss else Color("#bd6a2c")
	if kind == "fry_goblin":
		patty = Color("#f3cc3f")
		for i in range(4):
			_add_rect(Vector2(-22 + i * 12, -50), Vector2(8, 34), Color("#f7d749"), true)
	_add_ellipse(Vector2(0, -22), Vector2(70, 34), bun, true)
	_add_rect(Vector2(-28, -12), Vector2(56, 10), Color("#4f2214"), false)
	_add_ellipse(Vector2(0, 4), Vector2(66, 24), patty, true)
	_add_rect(Vector2(-28, -2), Vector2(56, 8), Color("#ffdf6c"), false)
	_add_ellipse(Vector2(0, 21), Vector2(62, 24), bun, true)
	_add_circle(Vector2(-13, -24), 6, Color.WHITE, true)
	_add_circle(Vector2(14, -24), 6, Color.WHITE, true)
	_add_circle(Vector2(-11, -24), 2.5, Color("#160707"), false)
	_add_circle(Vector2(12, -24), 2.5, Color("#160707"), false)
	_add_rect(Vector2(-14, 33), Vector2(28, 5), Color("#160707"), false)
	if is_boss:
		_add_poly(PackedVector2Array([Vector2(-44, -52), Vector2(-20, -36), Vector2(-37, -28)]), Color("#ff4d2a"), true)
		_add_poly(PackedVector2Array([Vector2(44, -52), Vector2(20, -36), Vector2(37, -28)]), Color("#ff4d2a"), true)

func _build_health_bar() -> void:
	var y := -98 if is_boss else -56
	var width := 84 if is_boss else 46
	health_back = ColorRect.new()
	health_back.position = Vector2(-width * 0.5, y)
	health_back.size = Vector2(width, 6)
	health_back.color = Color("#160707")
	add_child(health_back)
	health_fill = ColorRect.new()
	health_fill.position = health_back.position + Vector2(2, 2)
	health_fill.size = Vector2(width - 4, 2)
	health_fill.color = Color("#67ef1c")
	add_child(health_fill)

func _update_health_bar() -> void:
	if not health_fill:
		return
	var full_width := (84 if is_boss else 46) - 4
	health_fill.size.x = max(0.0, full_width * float(health) / max_health)
	if health <= max_health * 0.35:
		health_fill.color = Color("#ff3847")
	elif health <= max_health * 0.65:
		health_fill.color = Color("#ffd347")
	else:
		health_fill.color = Color("#67ef1c")

func _spawn_pop() -> void:
	art_root.scale *= 0.72
	var target_scale := Vector2(1.9, 1.9) if is_boss else Vector2.ONE
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(art_root, "scale", target_scale, 0.22)

func _add_poly(points: PackedVector2Array, color: Color, outlined: bool) -> void:
	var poly := Polygon2D.new()
	poly.polygon = points
	poly.color = color
	art_root.add_child(poly)
	if outlined:
		var line := Line2D.new()
		line.points = points
		line.closed = true
		line.width = 4
		line.default_color = Color("#160707")
		art_root.add_child(line)

func _add_circle(pos: Vector2, radius: float, color: Color, outlined: bool) -> void:
	_add_ellipse(pos, Vector2(radius * 2, radius * 2), color, outlined)

func _add_ellipse(pos: Vector2, size: Vector2, color: Color, outlined: bool) -> void:
	var points := PackedVector2Array()
	for i in range(22):
		var angle := TAU * i / 22.0
		points.append(pos + Vector2(cos(angle) * size.x * 0.5, sin(angle) * size.y * 0.5))
	_add_poly(points, color, outlined)

func _add_rect(pos: Vector2, size: Vector2, color: Color, outlined: bool) -> void:
	_add_poly(PackedVector2Array([pos, pos + Vector2(size.x, 0), pos + size, pos + Vector2(0, size.y)]), color, outlined)
