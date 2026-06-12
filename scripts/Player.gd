extends CharacterBody2D
class_name Player

signal stats_changed(health: int, max_health: int, lives: int, special: int, max_special: int)
signal score_changed(score: int)
signal died
signal attack_landed(target: Node, hitbox: Node)

const AttackHitboxScene := preload("res://scripts/AttackHitbox.gd")
const PlayerArtScene := preload("res://scripts/PlayerArt.gd")

const GRAVITY := 2100.0
const SPEED := 320.0
const ACCELERATION := 2600.0
const DECELERATION := 3400.0
const JUMP_VELOCITY := -700.0
const INPUT_BUFFER_TIME := 0.16
const COYOTE_TIME := 0.1

var health := 120
var max_health := 120
var lives := 3
var special := 50
var max_special := 100
var score := 0
var facing := 1
var is_attacking := false
var is_hurt := false
var is_dead := false

var combo_step := 0
var combo_reset_at := 0.0
var attack_lock_until := 0.0
var invulnerable_until := 0.0
var last_floor_time := 0.0
var buffered_attack := ""
var buffered_attack_until := 0.0
var buffered_jump_until := 0.0
var current_pose := ""

var art_root: Node

func _ready() -> void:
	add_to_group("player")
	art_root = PlayerArtScene.new()
	add_child(art_root)
	_build_collision()
	_set_pose("idle", true)
	emit_stats()

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity.y += GRAVITY * delta
		move_and_slide()
		return

	var now := Time.get_ticks_msec() / 1000.0
	if is_on_floor():
		last_floor_time = now
	if now > combo_reset_at:
		combo_step = 0
	_capture_buffers(now)

	var horizontal := Input.get_axis("move_left", "move_right")
	if not is_attacking and not is_hurt:
		var target_speed := horizontal * SPEED
		var rate := ACCELERATION if abs(horizontal) > 0.1 else DECELERATION
		velocity.x = move_toward(velocity.x, target_speed, rate * delta)
		if abs(horizontal) > 0.1:
			facing = sign(horizontal)
			art_root.set_facing(facing)
	elif is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, DECELERATION * 0.45 * delta)

	if Input.is_action_just_pressed("jump"):
		buffered_jump_until = now + INPUT_BUFFER_TIME

	if buffered_jump_until >= now and (is_on_floor() or now - last_floor_time <= COYOTE_TIME) and not is_attacking:
		velocity.y = JUMP_VELOCITY
		buffered_jump_until = 0.0

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if now >= attack_lock_until and not is_hurt:
		_consume_buffered_attack(now)

	move_and_slide()
	_update_pose(horizontal)

func receive_damage(amount: int, knockback: Vector2, source_x: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if is_dead or now < invulnerable_until:
		return

	health = max(0, health - amount)
	var direction := 1 if global_position.x >= source_x else -1
	velocity = Vector2(knockback.x * direction, knockback.y)
	is_hurt = true
	invulnerable_until = now + 0.82
	art_root.flash(Color(1.0, 0.88, 0.65), 0.14)
	_set_pose("hurt")
	emit_stats()

	await get_tree().create_timer(0.36).timeout
	is_hurt = false

	if health <= 0:
		_lose_life()

func add_score(value: int) -> void:
	score += value
	special = min(max_special, special + 12)
	score_changed.emit(score)
	emit_stats()

func emit_stats() -> void:
	stats_changed.emit(health, max_health, lives, special, max_special)

func _start_attack(data: Dictionary) -> void:
	is_attacking = true
	_set_pose(data.pose, true)
	attack_lock_until = Time.get_ticks_msec() / 1000.0 + data.strike_at + data.active + data.recovery
	velocity.x = data.step_speed * facing

	await get_tree().create_timer(data.strike_at).timeout

	var hitbox := AttackHitboxScene.new()
	add_child(hitbox)
	var knockback: Vector2 = data.knockback
	knockback.x *= facing
	hitbox.landed.connect(_on_attack_landed)
	hitbox.setup(self, data.range, data.offset, data.damage, knockback, data.active, data.arc_color)

	await get_tree().create_timer(data.active).timeout
	await get_tree().create_timer(data.recovery).timeout
	is_attacking = false

func _light_attack_data(step: int) -> Dictionary:
	if step == 1:
		return {"damage": 10, "knockback": Vector2(310, -130), "range": Vector2(72, 54), "offset": Vector2(66 * facing, -2), "strike_at": 0.045, "active": 0.085, "recovery": 0.1, "step_speed": 120.0, "arc_color": Color(1.0, 0.92, 0.25, 0.55), "pose": "light_1"}
	if step == 2:
		return {"damage": 12, "knockback": Vector2(360, -155), "range": Vector2(82, 56), "offset": Vector2(72 * facing, -1), "strike_at": 0.055, "active": 0.09, "recovery": 0.11, "step_speed": 140.0, "arc_color": Color(0.6, 0.95, 1.0, 0.52), "pose": "light_2"}
	return {"damage": 20, "knockback": Vector2(560, -270), "range": Vector2(98, 62), "offset": Vector2(82 * facing, 0), "strike_at": 0.075, "active": 0.11, "recovery": 0.18, "step_speed": 190.0, "arc_color": Color(1.0, 0.28, 0.16, 0.62), "pose": "light_3"}

func _capture_buffers(now: float) -> void:
	if Input.is_action_just_pressed("light_attack"):
		buffered_attack = "light"
		buffered_attack_until = now + INPUT_BUFFER_TIME
	elif Input.is_action_just_pressed("heavy_attack"):
		buffered_attack = "heavy"
		buffered_attack_until = now + INPUT_BUFFER_TIME
	elif Input.is_action_just_pressed("special_attack"):
		buffered_attack = "special"
		buffered_attack_until = now + INPUT_BUFFER_TIME

func _consume_buffered_attack(now: float) -> void:
	if buffered_attack == "" or buffered_attack_until < now:
		buffered_attack = ""
		return
	var attack := buffered_attack
	buffered_attack = ""
	if attack == "light":
		combo_step = (combo_step % 3) + 1
		combo_reset_at = now + 0.72
		_start_attack(_light_attack_data(combo_step))
	elif attack == "heavy":
		combo_step = 0
		_start_attack({"damage": 32, "knockback": Vector2(650, -290), "range": Vector2(112, 72), "offset": Vector2(84 * facing, -1), "strike_at": 0.16, "active": 0.14, "recovery": 0.28, "step_speed": 80.0, "arc_color": Color(1.0, 0.55, 0.08, 0.65), "pose": "heavy"})
	elif attack == "special" and special >= 35:
		combo_step = 0
		special -= 35
		emit_stats()
		_start_attack({"damage": 24, "knockback": Vector2(620, -235), "range": Vector2(148, 100), "offset": Vector2(48 * facing, 0), "strike_at": 0.08, "active": 0.38, "recovery": 0.24, "step_speed": 60.0, "arc_color": Color(0.15, 0.9, 1.0, 0.42), "pose": "sauce_spin"})

func _on_attack_landed(target: Node, hitbox: Node) -> void:
	attack_landed.emit(target, hitbox)

func _lose_life() -> void:
	lives -= 1
	is_dead = true
	velocity = Vector2(0, -420)
	_set_pose("death", true)
	art_root.modulate = Color(0.35, 0.14, 0.2)
	emit_stats()
	died.emit()

	if lives > 0:
		await get_tree().create_timer(1.2).timeout
		health = max_health
		special = max(40, special)
		global_position = Vector2(max(130, global_position.x - 180), 330)
		velocity = Vector2.ZERO
		is_dead = false
		is_hurt = false
		art_root.modulate = Color.WHITE
		_set_pose("idle", true)
		emit_stats()

func _build_collision() -> void:
	var collision := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(72, 82)
	collision.shape = rect
	collision.position = Vector2(0, 8)
	add_child(collision)

func _update_pose(horizontal: float) -> void:
	if is_dead or is_hurt or is_attacking:
		return
	if not is_on_floor():
		_set_pose("jump" if velocity.y < 0 else "fall")
	elif abs(horizontal) > 0.1:
		_set_pose("run")
	else:
		_set_pose("idle")

func _set_pose(pose: String, force := false) -> void:
	if current_pose == pose:
		return
	current_pose = pose
	art_root.play(pose, force)
