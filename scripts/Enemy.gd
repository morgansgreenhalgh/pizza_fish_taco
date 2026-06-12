extends CharacterBody2D
class_name Enemy

signal defeated(enemy: Enemy)
signal health_changed(enemy: Enemy, amount: int)
signal attack_started(enemy: Enemy, warning_position: Vector2, warning_size: Vector2)
signal attack_committed(enemy: Enemy)

const GRAVITY := 1900.0
const BURGER_GRUNT_FRAME_DIR := "res://assets/enemies/burger_grunt/frames/"
const FRY_GOBLIN_FRAME_DIR := "res://assets/enemies/fry_goblin/frames/"
const BIG_BAD_BURGER_FRAME_DIR := "res://assets/bosses/big_bad_burger/frames/"
const ENEMY_FRAME_NAMES := [
	"idle_0",
	"walk_0",
	"walk_1",
	"windup_0",
	"attack_0",
	"hurt_0",
	"knockback_0",
	"defeated_0",
	"taunt_0",
	"run_0",
	"stunned_0",
	"recover_0",
]
const BIG_BAD_BURGER_FRAME_NAMES := [
	"idle_0",
	"walk_0",
	"walk_1",
	"chomp_windup_0",
	"chomp_attack_0",
	"charge_windup_0",
	"charge_attack_0",
	"slam_windup_0",
	"slam_impact_0",
	"hurt_0",
	"stunned_0",
	"defeated_0",
]

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
var using_sprite_art := false
var sprite: Sprite2D
var sprite_textures := {}
var current_art_pose := ""
var art_frames: Array = []
var art_frame_index := 0
var art_elapsed := 0.0
var current_attack_name := ""

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
	_update_art_pose()

func _process(delta: float) -> void:
	if not using_sprite_art or art_frames.is_empty():
		return
	art_elapsed += delta
	var frame: Dictionary = art_frames[art_frame_index]
	if art_elapsed < frame.get("duration", 0.12):
		return
	art_elapsed = 0.0
	art_frame_index += 1
	if art_frame_index >= art_frames.size():
		art_frame_index = 0 if _art_pose_loops(current_art_pose) else art_frames.size() - 1
	_apply_art_frame()

func _update_ai(delta: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var dx := target.global_position.x - global_position.x
	facing = 1 if dx >= 0 else -1
	_apply_art_root_scale()

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
	_set_art_pose("hurt", true)
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
	current_attack_name = attack.name
	attack_cooldown_until = now + attack.cooldown
	var warning_size: Vector2 = attack.warning_size
	var warning_pos := global_position + Vector2(facing * warning_size.x * 0.45, -6)
	attack_started.emit(self, warning_pos, warning_size)
	art_root.modulate = Color(1.0, 0.38, 0.3) if is_boss else Color(1.0, 0.85, 0.35)
	art_root.rotation_degrees = -attack.windup_tilt * facing
	_set_art_pose("windup", true)
	await get_tree().create_timer(attack.windup).timeout
	if is_dead or is_hurt or this_attack != attack_serial:
		return
	attack_committed.emit(self)
	velocity.x = facing * attack.lunge_speed
	art_root.rotation_degrees = attack.commit_tilt * facing
	_set_art_pose("attack", true)
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
		current_attack_name = ""

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
	_set_art_pose("defeated", true)
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
	_apply_art_root_scale()
	if _build_sprite_art():
		return
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

func _build_sprite_art() -> bool:
	var frame_dir := _frame_dir_for_kind()
	if frame_dir == "":
		return false
	for frame_name in _frame_names_for_kind():
		var path: String = frame_dir + str(frame_name) + ".png"
		var texture := _load_png_texture(path)
		if texture != null:
			sprite_textures[frame_name] = texture
	if not sprite_textures.has("idle_0"):
		return false

	using_sprite_art = true
	_apply_art_root_scale()
	sprite = Sprite2D.new()
	sprite.texture = sprite_textures.idle_0
	sprite.centered = true
	sprite.position = Vector2(0, -2)
	art_root.add_child(sprite)
	_set_art_pose("idle", true)
	return true

func _frame_dir_for_kind() -> String:
	if kind == "burger_grunt":
		return BURGER_GRUNT_FRAME_DIR
	if kind == "fry_goblin":
		return FRY_GOBLIN_FRAME_DIR
	if kind == "big_bad_burger":
		return BIG_BAD_BURGER_FRAME_DIR
	return ""

func _frame_names_for_kind() -> Array:
	if kind == "big_bad_burger":
		return BIG_BAD_BURGER_FRAME_NAMES
	return ENEMY_FRAME_NAMES

func _base_art_scale() -> Vector2:
	if is_boss and not using_sprite_art:
		return Vector2(1.9, 1.9)
	return Vector2.ONE

func _apply_art_root_scale() -> void:
	var base_scale := _base_art_scale()
	art_root.scale = Vector2(base_scale.x * facing, base_scale.y)

func _load_png_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var imported_texture := load(path)
		if imported_texture is Texture2D:
			return imported_texture

	var image := Image.new()
	var error := image.load(ProjectSettings.globalize_path(path))
	if error != OK:
		return null
	return ImageTexture.create_from_image(image)

func _update_art_pose() -> void:
	if not using_sprite_art or is_dead or is_hurt or is_attacking:
		return
	if abs(velocity.x) > 18.0:
		_set_art_pose("walk")
	else:
		_set_art_pose("idle")

func _set_art_pose(pose: String, force := false) -> void:
	if not using_sprite_art:
		return
	if current_art_pose == pose and not force:
		return
	current_art_pose = pose
	art_frames = _art_frames_for(pose)
	art_frame_index = 0
	art_elapsed = 0.0
	_apply_art_frame()

func _art_frames_for(pose: String) -> Array:
	match pose:
		"idle":
			return [
				{"texture": "idle_0", "duration": 0.28},
				{"texture": "taunt_0", "duration": 0.18},
				{"texture": "idle_0", "duration": 0.34},
			]
		"walk":
			if kind == "fry_goblin":
				return [
					{"texture": "walk_0", "duration": 0.085},
					{"texture": "run_0", "duration": 0.085},
					{"texture": "walk_1", "duration": 0.085},
				]
			return [
				{"texture": "walk_0", "duration": 0.12},
				{"texture": "walk_1", "duration": 0.12},
			]
		"windup":
			if kind == "big_bad_burger":
				match current_attack_name:
					"mega_chomp":
						return [{"texture": "chomp_windup_0", "duration": 0.2}]
					"burger_charge":
						return [{"texture": "charge_windup_0", "duration": 0.2}]
					"sauce_slam":
						return [{"texture": "slam_windup_0", "duration": 0.2}]
			return [{"texture": "windup_0", "duration": 0.2}]
		"attack":
			if kind == "big_bad_burger":
				match current_attack_name:
					"mega_chomp":
						return [{"texture": "chomp_attack_0", "duration": 0.16}]
					"burger_charge":
						return [{"texture": "charge_attack_0", "duration": 0.16}]
					"sauce_slam":
						return [{"texture": "slam_impact_0", "duration": 0.16}]
			return [{"texture": "attack_0", "duration": 0.16}]
		"hurt":
			return [
				{"texture": "hurt_0", "duration": 0.12},
				{"texture": "knockback_0", "duration": 0.12},
			]
		"defeated":
			return [{"texture": "defeated_0", "duration": 0.4}]
	return [{"texture": "idle_0", "duration": 0.2}]

func _art_pose_loops(pose: String) -> bool:
	return pose in ["idle", "walk"]

func _apply_art_frame() -> void:
	if not using_sprite_art or art_frames.is_empty():
		return
	var frame: Dictionary = art_frames[art_frame_index]
	var texture_key: String = frame.get("texture", "idle_0")
	if sprite_textures.has(texture_key):
		sprite.texture = sprite_textures[texture_key]
	_apply_sprite_metrics()

func _apply_sprite_metrics() -> void:
	if not sprite or not sprite.texture:
		return
	var sprite_scale := _sprite_art_scale()
	var texture_size := sprite.texture.get_size()
	sprite.scale = sprite_scale
	sprite.position = Vector2(0, _sprite_ground_bottom() - texture_size.y * sprite_scale.y * 0.5)

func _sprite_art_scale() -> Vector2:
	if kind == "big_bad_burger":
		return Vector2(1.18, 1.18)
	if kind == "fry_goblin":
		return Vector2(0.9, 0.9)
	if kind == "burger_grunt":
		return Vector2(0.92, 0.92)
	return Vector2.ONE

func _sprite_ground_bottom() -> float:
	if kind == "big_bad_burger":
		return 68.0
	if kind == "fry_goblin":
		return 34.0
	if kind == "burger_grunt":
		return 37.0
	return 38.0

func _build_health_bar() -> void:
	var y := -128 if is_boss and using_sprite_art else (-98 if is_boss else -56)
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
	var target_scale := _base_art_scale()
	target_scale.x *= facing
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
