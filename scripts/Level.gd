extends Node2D
class_name Level

signal level_finished(won: bool, score: int, lives: int)
signal restart_requested
signal menu_requested

const PlayerScene := preload("res://scenes/Player.tscn")
const EnemyScene := preload("res://scenes/Enemy.tscn")
const PickupScene := preload("res://scripts/Pickup.gd")
const HUDScript := preload("res://scripts/HUD.gd")
const InputSetupScript := preload("res://scripts/InputSetup.gd")

const GAME_HEIGHT := 540
const WORLD_WIDTH := 3200
const GROUND_Y := 452

var player: Node
var hud: CanvasLayer
var camera: Camera2D
var boss: Node
var boss_spawned := false
var active_wave_index := -1
var active_wave_enemies: Array[Node] = []
var gate_body: StaticBody2D
var gate_visual: ColorRect
var gate_locked := false
var gate_pulse_time := 0.0
var boss_intro_running := false
var pause_layer: CanvasLayer
var level_clear_layer: CanvasLayer
var gameplay_paused := false
var level_ending := false
var waves := [
	{"trigger": 260.0, "gate": 850.0, "spawned": false, "enemies": [{"kind": "burger_grunt", "x": 640.0}, {"kind": "burger_grunt", "x": 770.0}]},
	{"trigger": 880.0, "gate": 1390.0, "spawned": false, "enemies": [{"kind": "burger_grunt", "x": 1180.0}, {"kind": "fry_goblin", "x": 1280.0}]},
	{"trigger": 1540.0, "gate": 2110.0, "spawned": false, "enemies": [{"kind": "fry_goblin", "x": 1780.0}, {"kind": "burger_grunt", "x": 1880.0}, {"kind": "burger_grunt", "x": 1990.0}]},
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	InputSetupScript.configure()
	_build_background()
	_build_ground()
	player = PlayerScene.instantiate()
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	player.global_position = Vector2(130, GROUND_Y - 76)
	add_child(player)
	player.stats_changed.connect(_on_player_stats_changed)
	player.score_changed.connect(_on_score_changed)
	player.died.connect(_on_player_died)
	player.attack_landed.connect(_on_player_attack_landed)

	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	camera.limit_left = 0
	camera.limit_right = WORLD_WIDTH
	camera.limit_top = 0
	camera.limit_bottom = GAME_HEIGHT
	player.add_child(camera)
	camera.make_current()

	hud = HUDScript.new()
	add_child(hud)
	player.emit_stats()
	hud.update_score(0)
	hud.show_status("SNACK CITY STREETS", 2.0)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause") and not level_ending:
		_toggle_pause()
	if gameplay_paused:
		return
	_spawn_waves()
	_spawn_boss_if_ready()
	_update_active_wave()
	_update_gate_pulse(delta)
	if boss and is_instance_valid(boss):
		hud.update_boss(boss.display_name, boss.health, boss.max_health, true)

func _spawn_waves() -> void:
	for wave in waves:
		if not wave.spawned and player.global_position.x >= wave.trigger:
			wave.spawned = true
			active_wave_index = waves.find(wave)
			active_wave_enemies.clear()
			_lock_gate(wave.gate)
			hud.show_status("BURGER AMBUSH!", 1.2, Color("#ff9f39"))
			for item in wave.enemies:
				active_wave_enemies.append(_spawn_enemy(item.kind, item.x))

func _spawn_boss_if_ready() -> void:
	if boss_spawned or boss_intro_running or player.global_position.x < WORLD_WIDTH - 760:
		return
	boss_spawned = true
	boss_intro_running = true
	_lock_gate(WORLD_WIDTH - 120)
	hud.show_status("BIG BAD BURGER APPROACHES", 1.8, Color("#ff3847"))
	if camera:
		camera.offset = Vector2(10, -4)
		await get_tree().create_timer(0.12).timeout
		camera.offset = Vector2(-8, 3)
		await get_tree().create_timer(0.12).timeout
		camera.offset = Vector2.ZERO
	await get_tree().create_timer(0.45).timeout
	boss = _spawn_enemy("big_bad_burger", WORLD_WIDTH - 340)
	active_wave_index = waves.size()
	active_wave_enemies = [boss]
	boss_intro_running = false

func _spawn_enemy(kind: String, x: float) -> Node:
	var enemy := EnemyScene.instantiate()
	enemy.process_mode = Node.PROCESS_MODE_PAUSABLE
	enemy.configure(kind, player)
	enemy.global_position = Vector2(x, GROUND_Y - (112 if kind == "big_bad_burger" else 58) + randf_range(-2, 2))
	add_child(enemy)
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.health_changed.connect(_on_enemy_health_changed)
	enemy.attack_started.connect(_on_enemy_attack_started)
	enemy.attack_committed.connect(_on_enemy_attack_committed)
	return enemy

func _on_enemy_defeated(enemy: Node) -> void:
	player.add_score(enemy.score_value)
	_spawn_hit_spark(enemy.global_position + Vector2(0, -26))
	_spawn_crumb_burst(enemy.global_position + Vector2(0, -12))
	if enemy.is_boss:
		hud.update_boss(enemy.display_name, 0, enemy.max_health, false)
		_unlock_gate()
		await get_tree().create_timer(0.9).timeout
		_show_level_clear()
	else:
		_maybe_spawn_pickup(enemy.global_position + Vector2(0, -24))
		active_wave_enemies.erase(enemy)
		_update_active_wave()

func _on_enemy_health_changed(enemy: Node, amount: int) -> void:
	_spawn_hit_spark(enemy.global_position + Vector2(0, -26))
	_spawn_damage_number(enemy.global_position + Vector2(randf_range(-10, 10), -58), amount)
	_hit_stop(0.035)
	if enemy.is_boss:
		hud.update_boss(enemy.display_name, enemy.health, enemy.max_health, true)
	if camera:
		camera.offset = Vector2(randf_range(-4, 4), randf_range(-3, 3))
		await get_tree().create_timer(0.08).timeout
		camera.offset = Vector2.ZERO

func _update_active_wave() -> void:
	if active_wave_index < 0:
		return
	active_wave_enemies = active_wave_enemies.filter(func(enemy: Node) -> bool:
		return enemy and is_instance_valid(enemy) and not enemy.is_dead
	)
	if active_wave_enemies.is_empty():
		if gate_locked:
			_unlock_gate()
			hud.show_status("GO!", 0.9, Color("#69ff7b"))
		active_wave_index = -1

func _lock_gate(x: float) -> void:
	_unlock_gate()
	gate_locked = true
	gate_body = StaticBody2D.new()
	gate_body.collision_layer = 1
	gate_body.collision_mask = 2
	add_child(gate_body)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(34, 220)
	shape.shape = rect
	shape.position = Vector2(x, GROUND_Y - 90)
	gate_body.add_child(shape)
	gate_visual = ColorRect.new()
	gate_visual.position = Vector2(x - 15, GROUND_Y - 205)
	gate_visual.size = Vector2(30, 170)
	gate_visual.color = Color(0.15, 0.95, 1.0, 0.16)
	add_child(gate_visual)
	gate_pulse_time = 0.0

func _unlock_gate() -> void:
	gate_locked = false
	if gate_body and is_instance_valid(gate_body):
		gate_body.queue_free()
	gate_body = null
	if gate_visual and is_instance_valid(gate_visual):
		var visual := gate_visual
		gate_visual = null
		var tween := create_tween()
		tween.tween_property(visual, "modulate:a", 0.0, 0.2)
		tween.tween_callback(visual.queue_free)

func _update_gate_pulse(delta: float) -> void:
	if not gate_visual or not is_instance_valid(gate_visual):
		return
	gate_pulse_time += delta * 7.0
	gate_visual.modulate.a = 0.24 + sin(gate_pulse_time) * 0.18

func _on_player_attack_landed(target: Node, _hitbox: Node) -> void:
	if target and is_instance_valid(target):
		_spawn_hit_spark(target.global_position + Vector2(randf_range(-10, 10), -30))

func _on_enemy_attack_started(_enemy: Node, warning_position: Vector2, warning_size: Vector2) -> void:
	var warning := ColorRect.new()
	warning.position = warning_position - warning_size * 0.5
	warning.size = warning_size
	warning.color = Color(1.0, 0.15, 0.05, 0.22)
	add_child(warning)
	var tween := create_tween()
	tween.tween_property(warning, "modulate:a", 0.65, 0.12)
	tween.tween_property(warning, "modulate:a", 0.0, 0.16)
	tween.tween_callback(warning.queue_free)

func _on_enemy_attack_committed(enemy: Node) -> void:
	if camera and enemy and is_instance_valid(enemy):
		camera.offset = Vector2(randf_range(-3, 3), randf_range(-2, 2))
		await get_tree().create_timer(0.05).timeout
		camera.offset = Vector2.ZERO

func _on_player_stats_changed(health: int, max_health: int, lives: int, special: int, max_special: int) -> void:
	hud.update_player(health, max_health, lives, special, max_special)

func _on_score_changed(score: int) -> void:
	hud.update_score(score)

func _on_player_died() -> void:
	if player.lives <= 0:
		await get_tree().create_timer(1.1).timeout
		level_finished.emit(false, player.score, player.lives)

func _maybe_spawn_pickup(pos: Vector2) -> void:
	var roll := randf()
	if roll > 0.45:
		return
	var kind := "score"
	var value := 250
	if roll < 0.12 and player.health < player.max_health:
		kind = "health"
		value = 28
	elif roll < 0.28:
		kind = "special"
		value = 26
	_spawn_pickup(kind, value, pos)

func _spawn_pickup(kind: String, value: int, pos: Vector2) -> void:
	var pickup := PickupScene.new()
	pickup.process_mode = Node.PROCESS_MODE_PAUSABLE
	pickup.configure(kind, value)
	pickup.global_position = pos
	add_child(pickup)
	pickup.collected.connect(_on_pickup_collected)

func _on_pickup_collected(pickup: Node, body: Node) -> void:
	if pickup.pickup_type == "health":
		body.heal(pickup.value)
		hud.show_status("+HEALTH", 0.8, Color("#69ff7b"))
	elif pickup.pickup_type == "special":
		body.add_special(pickup.value)
		hud.show_status("+SAUCE", 0.8, Color("#34c9ff"))
	else:
		body.add_score(pickup.value)
		hud.show_status("+%d" % pickup.value, 0.8, Color("#ffe964"))
	_spawn_pickup_burst(pickup.global_position, pickup.pickup_type)

func _toggle_pause() -> void:
	if level_clear_layer:
		return
	gameplay_paused = not gameplay_paused
	get_tree().paused = gameplay_paused
	if gameplay_paused:
		_show_pause()
	else:
		_hide_pause()

func _show_pause() -> void:
	pause_layer = CanvasLayer.new()
	pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(pause_layer)
	_add_rect_to(pause_layer, Vector2.ZERO, Vector2(960, 540), Color(0, 0, 0, 0.58))
	_add_rect_to(pause_layer, Vector2(250, 110), Vector2(460, 300), Color("#170b14"), Color("#f7dfb4"), 4)
	_add_label_to(pause_layer, "PAUSED", Vector2(480, 142), 42, Color("#ffe964"), true)
	_add_label_to(pause_layer, "Esc / Start: Resume", Vector2(480, 220), 22, Color.WHITE, true)
	_add_label_to(pause_layer, "R: Restart Level", Vector2(480, 264), 22, Color.WHITE, true)
	_add_label_to(pause_layer, "M: Return To Menu", Vector2(480, 308), 22, Color.WHITE, true)
	_add_label_to(pause_layer, "J Combo  K Heavy  L Sauce Spin", Vector2(480, 362), 16, Color("#37e6ff"), true)

func _hide_pause() -> void:
	if pause_layer and is_instance_valid(pause_layer):
		pause_layer.queue_free()
	pause_layer = null

func _unhandled_input(event: InputEvent) -> void:
	if not gameplay_paused:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_R:
			_hide_pause()
			get_tree().paused = false
			gameplay_paused = false
			restart_requested.emit()
		elif event.physical_keycode == KEY_M:
			_hide_pause()
			get_tree().paused = false
			gameplay_paused = false
			menu_requested.emit()

func _show_level_clear() -> void:
	level_ending = true
	var base_score: int = player.score
	var lives_bonus: int = max(0, player.lives) * 500
	var final_score: int = base_score + lives_bonus
	player.add_score(lives_bonus)
	level_clear_layer = CanvasLayer.new()
	level_clear_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(level_clear_layer)
	_add_rect_to(level_clear_layer, Vector2.ZERO, Vector2(960, 540), Color(0.02, 0.08, 0.04, 0.68))
	_add_rect_to(level_clear_layer, Vector2(210, 112), Vector2(540, 318), Color("#102316"), Color("#69ff7b"), 4)
	_add_label_to(level_clear_layer, "SNACK CITY STREETS CLEARED", Vector2(480, 148), 30, Color("#69ff7b"), true)
	_add_label_to(level_clear_layer, "Score %06d" % base_score, Vector2(480, 224), 24, Color.WHITE, true)
	_add_label_to(level_clear_layer, "Lives Bonus %06d" % lives_bonus, Vector2(480, 270), 24, Color("#ffe964"), true)
	_add_label_to(level_clear_layer, "Final %06d" % final_score, Vector2(480, 326), 30, Color("#37e6ff"), true)
	_add_label_to(level_clear_layer, "Press Enter / Start", Vector2(480, 386), 22, Color.WHITE, true)
	await _wait_for_start()
	level_finished.emit(true, final_score, player.lives)

func _wait_for_start() -> void:
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("start") or Input.is_action_just_pressed("pause"):
			return

func _build_background() -> void:
	_add_rect(Vector2(0, 0), Vector2(WORLD_WIDTH, GAME_HEIGHT), Color("#130512"))
	_add_rect(Vector2(0, 64), Vector2(WORLD_WIDTH, 236), Color("#2a081d"))
	_add_rect(Vector2(0, 300), Vector2(WORLD_WIDTH, 92), Color("#12030f"))
	_add_circle(Vector2(430, 118), 150, Color(0.96, 0.16, 0.1, 0.12))
	_add_circle(Vector2(1650, 142), 190, Color(0.19, 0.82, 1.0, 0.09))
	_add_circle(Vector2(2520, 128), 170, Color(0.95, 0.76, 0.1, 0.1))

	for i in range(14):
		var x := i * 260 - 36
		var height := 190 + (i % 5) * 24
		_add_rect(Vector2(x, 92 + 224 - height), Vector2(190, height), Color("#21091b"))
		_add_window_grid(Vector2(x + 22, 126), 5, 5, Color(0.07, 0.78, 0.9, 0.32))
		if i % 3 == 0:
			_add_neon_sign(Vector2(x + 28, 106), Vector2(92, 30), "EAT", Color("#37e6ff"))

	for i in range(10):
		var x := i * 350 + 60
		_add_rect(Vector2(x, 154), Vector2(220, 182), Color("#3b1027"))
		_add_rect(Vector2(x, 154), Vector2(220, 16), Color("#5b1837"))
		_add_window_grid(Vector2(x + 22, 184), 4, 3, Color(1.0, 0.27, 0.15, 0.42))
		_add_drips(Vector2(x + 18, 170), 5, Color("#ff8b1a"))
		if i % 2 == 0:
			_add_neon_sign(Vector2(x + 36, 112), Vector2(144, 38), "SNACK", Color("#ff4d2a"))
		else:
			_add_neon_sign(Vector2(x + 44, 116), Vector2(128, 34), "SAUCE", Color("#ffe964"))

	for i in range(8):
		var x := i * 430 + 120
		_add_rect(Vector2(x - 74, GROUND_Y - 170), Vector2(190, 88), Color("#6b331c"), Color("#1b0908"), 5)
		_add_rect(Vector2(x - 64, GROUND_Y - 160), Vector2(170, 18), Color("#9d3b20"))
		_add_label("HOT SAUCE" if i % 2 == 0 else "EXTRA CHEESE", Vector2(x - 52, GROUND_Y - 132), 15, Color("#ffb24a"))
		_add_circle(Vector2(x + 124, GROUND_Y - 102), 22, Color(1.0, 0.19, 0.09, 0.24))

	for i in range(17):
		var x := i * 205 + 42
		_add_circle(Vector2(x, 390 + (i % 3) * 10), 52, Color(0.5, 0.12, 0.09, 0.72))
		_add_rect(Vector2(x - 42, GROUND_Y - 54), Vector2(136, 10), Color("#ffd159"), Color("#1b0908"), 1)
		_add_rect(Vector2(x - 42, GROUND_Y - 44), Vector2(136, 52), Color("#b94d25"), Color("#33100b"), 2)
		_add_rect(Vector2(x - 38, GROUND_Y - 39), Vector2(128, 10), Color("#e05a2d"))
		_add_circle(Vector2(x - 76, GROUND_Y - 24), 7, Color("#ffe071"))
		_add_circle(Vector2(x + 12, GROUND_Y - 18), 6, Color("#ef3322"))

	_add_neon_sign(Vector2(210, 338), Vector2(272, 48), "SNACK CITY", Color("#ffe964"))
	_add_neon_sign(Vector2(2340, 326), Vector2(212, 42), "BOSS BITES", Color("#ff3847"))
	_add_pizza_slice(Vector2(720, 358), 0.8)
	_add_taco_icon(Vector2(1510, 350), 0.72)
	_add_sauce_bottle(Vector2(2050, 356), 0.72)

func _build_ground() -> void:
	var ground := StaticBody2D.new()
	ground.collision_layer = 1
	ground.collision_mask = 6
	add_child(ground)
	var collision := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(WORLD_WIDTH, 86)
	collision.shape = rect
	collision.position = Vector2(WORLD_WIDTH / 2.0, GROUND_Y + 42)
	ground.add_child(collision)
	_add_rect(Vector2(0, GROUND_Y), Vector2(WORLD_WIDTH, 86), Color("#7b3422"), Color("#efac4f"), 4)
	_add_rect(Vector2(0, GROUND_Y), Vector2(WORLD_WIDTH, 10), Color("#ffcf55"), Color("#1b0908"), 2)
	for i in range(34):
		var x := i * 96
		_add_rect(Vector2(x + 12, GROUND_Y + 16), Vector2(64, 4), Color(0.22, 0.06, 0.03, 0.42))
		_add_rect(Vector2(x + 42, GROUND_Y + 42), Vector2(72, 4), Color(0.22, 0.06, 0.03, 0.34))

func _spawn_hit_spark(pos: Vector2) -> void:
	var spark := Polygon2D.new()
	var points := PackedVector2Array()
	for i in range(14):
		var radius := 24 if i % 2 == 0 else 7
		var angle := TAU * i / 14.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	spark.polygon = points
	spark.color = Color("#fff06b")
	spark.position = pos
	add_child(spark)
	var tween := create_tween()
	tween.tween_property(spark, "scale", Vector2(1.8, 1.8), 0.16)
	tween.parallel().tween_property(spark, "modulate:a", 0.0, 0.16)
	tween.tween_callback(spark.queue_free)

func _spawn_damage_number(pos: Vector2, amount: int) -> void:
	var label := Label.new()
	label.text = str(amount)
	label.position = pos
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color("#fff06b"))
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)
	add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "position", pos + Vector2(randf_range(-12, 12), -36), 0.48)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.48)
	tween.tween_callback(label.queue_free)

func _spawn_crumb_burst(pos: Vector2) -> void:
	for i in range(10):
		var crumb := ColorRect.new()
		crumb.position = pos
		crumb.size = Vector2(randf_range(4, 8), randf_range(4, 8))
		crumb.color = [Color("#f0b14b"), Color("#ffdf6c"), Color("#bd6a2c"), Color("#f14120")].pick_random()
		add_child(crumb)
		var target := pos + Vector2(randf_range(-48, 48), randf_range(-58, 18))
		var tween := create_tween()
		tween.tween_property(crumb, "position", target, randf_range(0.26, 0.46))
		tween.parallel().tween_property(crumb, "rotation", randf_range(-2.5, 2.5), 0.38)
		tween.parallel().tween_property(crumb, "modulate:a", 0.0, 0.42)
		tween.tween_callback(crumb.queue_free)

func _spawn_pickup_burst(pos: Vector2, kind: String) -> void:
	var color := Color("#ffe071")
	if kind == "health":
		color = Color("#69ff7b")
	elif kind == "special":
		color = Color("#34c9ff")
	for i in range(8):
		var sparkle := Polygon2D.new()
		sparkle.polygon = PackedVector2Array([Vector2(0, -6), Vector2(4, 0), Vector2(0, 6), Vector2(-4, 0)])
		sparkle.color = color
		sparkle.position = pos
		add_child(sparkle)
		var target := pos + Vector2(randf_range(-34, 34), randf_range(-36, 10))
		var tween := create_tween()
		tween.tween_property(sparkle, "position", target, 0.32)
		tween.parallel().tween_property(sparkle, "modulate:a", 0.0, 0.32)
		tween.tween_callback(sparkle.queue_free)

func _hit_stop(duration: float) -> void:
	if Engine.time_scale < 1.0:
		return
	Engine.time_scale = 0.12
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

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

func _add_circle(pos: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(24):
		var angle := TAU * i / 24.0
		points.append(pos + Vector2(cos(angle), sin(angle)) * radius)
	var poly := Polygon2D.new()
	poly.polygon = points
	poly.color = color
	add_child(poly)

func _add_poly(points: PackedVector2Array, color: Color, outline := Color.TRANSPARENT, outline_width := 0) -> Polygon2D:
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
	return poly

func _add_line(points: PackedVector2Array, color: Color, width := 3.0) -> Line2D:
	var line := Line2D.new()
	line.points = points
	line.width = width
	line.default_color = color
	add_child(line)
	return line

func _add_window_grid(pos: Vector2, columns: int, rows: int, glow: Color) -> void:
	for y in range(rows):
		for x in range(columns):
			if (x + y) % 4 == 0:
				continue
			var window_pos := pos + Vector2(x * 28, y * 24)
			_add_rect(window_pos, Vector2(16, 10), Color(glow.r, glow.g, glow.b, 0.18))
			_add_rect(window_pos + Vector2(2, 2), Vector2(12, 6), glow)

func _add_neon_sign(pos: Vector2, size: Vector2, text: String, glow: Color) -> void:
	_add_rect(pos - Vector2(5, 5), size + Vector2(10, 10), Color(glow.r, glow.g, glow.b, 0.12))
	_add_rect(pos, size, Color("#120611"), glow, 3)
	_add_label(text, pos + Vector2(12, 6), 15, glow)
	_add_line(PackedVector2Array([pos + Vector2(8, size.y - 7), pos + Vector2(size.x - 8, size.y - 7)]), Color(glow.r, glow.g, glow.b, 0.42), 2)

func _add_drips(pos: Vector2, count: int, color: Color) -> void:
	for i in range(count):
		var x := pos.x + i * 32 + (i % 2) * 8
		var length := 18 + (i % 3) * 9
		_add_rect(Vector2(x, pos.y), Vector2(9, length), color)
		_add_circle(Vector2(x + 4, pos.y + length), 6, color)

func _add_pizza_slice(pos: Vector2, scale_size: float) -> void:
	var points := PackedVector2Array([
		pos + Vector2(0, -34) * scale_size,
		pos + Vector2(62, 20) * scale_size,
		pos + Vector2(-58, 24) * scale_size,
	])
	_add_poly(points, Color("#ffd15b"), Color("#160707"), 4)
	_add_line(PackedVector2Array([points[1], points[2]]), Color("#f14120"), 6)
	_add_circle(pos + Vector2(-18, 2) * scale_size, 7 * scale_size, Color("#ef3322"))
	_add_circle(pos + Vector2(18, 5) * scale_size, 7 * scale_size, Color("#ef3322"))

func _add_taco_icon(pos: Vector2, scale_size: float) -> void:
	var points := PackedVector2Array()
	for i in range(18):
		var angle := PI + PI * i / 17.0
		points.append(pos + Vector2(cos(angle) * 62, sin(angle) * 42) * scale_size)
	points.append(pos + Vector2(62, 8) * scale_size)
	points.append(pos + Vector2(-62, 8) * scale_size)
	_add_poly(points, Color("#f0b14b"), Color("#160707"), 4)
	_add_circle(pos + Vector2(-20, -8) * scale_size, 7 * scale_size, Color("#69ff7b"))
	_add_circle(pos + Vector2(12, -10) * scale_size, 7 * scale_size, Color("#ef3322"))

func _add_sauce_bottle(pos: Vector2, scale_size: float) -> void:
	_add_rect(pos + Vector2(-18, -44) * scale_size, Vector2(36, 18) * scale_size, Color("#8b1838"), Color("#160707"), 3)
	_add_rect(pos + Vector2(-24, -26) * scale_size, Vector2(48, 72) * scale_size, Color("#e63b20"), Color("#160707"), 4)
	_add_rect(pos + Vector2(-16, -6) * scale_size, Vector2(32, 20) * scale_size, Color("#ffe071"))
	_add_circle(pos + Vector2(0, 28) * scale_size, 8 * scale_size, Color("#ff9f39"))

func _add_label(text: String, pos: Vector2, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)
	add_child(label)
	return label

func _add_rect_to(parent: Node, pos: Vector2, size: Vector2, color: Color, outline := Color.TRANSPARENT, outline_width := 0) -> ColorRect:
	var rect := ColorRect.new()
	rect.position = pos
	rect.size = size
	rect.color = color
	parent.add_child(rect)
	if outline_width > 0:
		var line := Line2D.new()
		line.points = PackedVector2Array([pos, pos + Vector2(size.x, 0), pos + size, pos + Vector2(0, size.y)])
		line.closed = true
		line.width = outline_width
		line.default_color = outline
		parent.add_child(line)
	return rect

func _add_label_to(parent: Node, text: String, pos: Vector2, size: int, color: Color, centered := false) -> Label:
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
		label.size = Vector2(720, 40)
		label.position.x -= 360
	parent.add_child(label)
	return label
