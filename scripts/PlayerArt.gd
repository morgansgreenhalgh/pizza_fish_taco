extends Node2D
class_name PlayerArt

const PLAYER_FRAME_DIR := "res://assets/characters/pizza_fish_taco/frames/"
const PLAYER_FRAME_NAMES := [
	"idle_0",
	"idle_1",
	"idle_2",
	"run_0",
	"run_1",
	"run_2",
	"run_3",
	"bite_0",
	"bite_1",
	"sauce_0",
	"hurt_0",
	"spin_0",
	"spin_1",
	"crouch_0",
	"jump_0",
]

var facing := 1
var current_animation := ""
var current_frames: Array = []
var frame_index := 0
var frame_elapsed := 0.0
var parts := {}
var using_sprite_art := false
var sprite: Sprite2D
var sprite_textures := {}

func _ready() -> void:
	_build()
	play("idle")

func set_facing(value: int) -> void:
	facing = value
	scale.x = -facing if using_sprite_art else facing

func play(animation_name: String, force := false) -> void:
	if current_animation == animation_name and not force:
		return
	current_animation = animation_name
	current_frames = _frames_for(animation_name)
	frame_index = 0
	frame_elapsed = 0.0
	if current_frames.is_empty():
		return
	_apply_frame(current_frames[0])

func _process(delta: float) -> void:
	if current_frames.is_empty():
		return
	frame_elapsed += delta
	var frame: Dictionary = current_frames[frame_index]
	if frame_elapsed < frame.get("duration", 0.1):
		return
	frame_elapsed = 0.0
	frame_index += 1
	if frame_index >= current_frames.size():
		if _loops(current_animation):
			frame_index = 0
		else:
			frame_index = current_frames.size() - 1
	_apply_frame(current_frames[frame_index])

func flash(color: Color, duration := 0.12) -> void:
	modulate = color
	var tween := create_tween()
	tween.tween_interval(duration)
	tween.tween_property(self, "modulate", Color.WHITE, 0.01)

func _loops(animation_name: String) -> bool:
	return animation_name in ["idle", "run", "jump", "fall"]

func _frames_for(animation_name: String) -> Array:
	match animation_name:
		"idle":
			return [
				{"duration": 0.22, "root_scale": Vector2(1.0, 1.0), "root_pos": Vector2.ZERO, "body_rot": 0.0, "fin_rot": 0.0, "leg_offset": 0.0},
				{"duration": 0.22, "root_scale": Vector2(1.015, 0.985), "root_pos": Vector2(0, 1), "body_rot": -1.0, "fin_rot": 4.0, "leg_offset": 1.0},
				{"duration": 0.22, "root_scale": Vector2(0.995, 1.005), "root_pos": Vector2(0, 0), "body_rot": 1.0, "fin_rot": -2.0, "leg_offset": 0.0},
			]
		"run":
			return [
				{"duration": 0.085, "root_scale": Vector2(1.08, 0.92), "root_pos": Vector2(0, 3), "body_rot": -4.0, "fin_rot": 12.0, "leg_offset": -4.0},
				{"duration": 0.085, "root_scale": Vector2(0.96, 1.06), "root_pos": Vector2(0, -3), "body_rot": 3.0, "fin_rot": -9.0, "leg_offset": 5.0},
				{"duration": 0.085, "root_scale": Vector2(1.06, 0.94), "root_pos": Vector2(0, 2), "body_rot": 4.0, "fin_rot": 10.0, "leg_offset": -5.0},
				{"duration": 0.085, "root_scale": Vector2(0.98, 1.03), "root_pos": Vector2(0, -2), "body_rot": -2.0, "fin_rot": -8.0, "leg_offset": 4.0},
			]
		"jump":
			return [{"duration": 0.16, "root_scale": Vector2(0.9, 1.12), "root_pos": Vector2(0, -5), "body_rot": -4.0, "fin_rot": -16.0, "leg_offset": -8.0}]
		"fall":
			return [{"duration": 0.16, "root_scale": Vector2(1.08, 0.94), "root_pos": Vector2(0, 4), "body_rot": 3.0, "fin_rot": 13.0, "leg_offset": 7.0}]
		"hurt":
			return [
				{"duration": 0.08, "root_scale": Vector2(1.18, 0.84), "root_pos": Vector2(-4, 1), "body_rot": -13.0, "fin_rot": 22.0, "leg_offset": 3.0},
				{"duration": 0.12, "root_scale": Vector2(0.94, 1.08), "root_pos": Vector2(2, -2), "body_rot": 8.0, "fin_rot": -12.0, "leg_offset": -3.0},
			]
		"death":
			return [{"duration": 0.4, "root_scale": Vector2(1.05, 0.9), "root_pos": Vector2(0, 10), "body_rot": 28.0, "fin_rot": -24.0, "leg_offset": 10.0}]
		"light_1":
			return [
				{"duration": 0.045, "root_scale": Vector2(0.94, 1.04), "root_pos": Vector2(-5, 0), "body_rot": -9.0, "fin_rot": -18.0, "leg_offset": 0.0},
				{"duration": 0.085, "root_scale": Vector2(1.18, 0.9), "root_pos": Vector2(9, 0), "body_rot": 14.0, "fin_rot": 28.0, "leg_offset": -2.0},
				{"duration": 0.08, "root_scale": Vector2(1.0, 1.0), "root_pos": Vector2.ZERO, "body_rot": 0.0, "fin_rot": 0.0, "leg_offset": 0.0},
			]
		"light_2":
			return [
				{"duration": 0.055, "root_scale": Vector2(0.92, 1.06), "root_pos": Vector2(-7, -1), "body_rot": 10.0, "fin_rot": -24.0, "leg_offset": 2.0},
				{"duration": 0.09, "root_scale": Vector2(1.2, 0.88), "root_pos": Vector2(10, 1), "body_rot": -16.0, "fin_rot": 30.0, "leg_offset": -3.0},
				{"duration": 0.08, "root_scale": Vector2(1.0, 1.0), "root_pos": Vector2.ZERO, "body_rot": 0.0, "fin_rot": 0.0, "leg_offset": 0.0},
			]
		"light_3":
			return [
				{"duration": 0.075, "root_scale": Vector2(0.9, 1.1), "root_pos": Vector2(-9, -2), "body_rot": -12.0, "fin_rot": -30.0, "leg_offset": 1.0},
				{"duration": 0.11, "root_scale": Vector2(1.26, 0.84), "root_pos": Vector2(14, 0), "body_rot": 20.0, "fin_rot": 38.0, "leg_offset": -6.0},
				{"duration": 0.12, "root_scale": Vector2(0.98, 1.0), "root_pos": Vector2.ZERO, "body_rot": 0.0, "fin_rot": 0.0, "leg_offset": 0.0},
			]
		"heavy":
			return [
				{"duration": 0.16, "root_scale": Vector2(0.84, 1.14), "root_pos": Vector2(-12, -2), "body_rot": -18.0, "fin_rot": -36.0, "leg_offset": 2.0},
				{"duration": 0.14, "root_scale": Vector2(1.32, 0.8), "root_pos": Vector2(16, 1), "body_rot": 24.0, "fin_rot": 42.0, "leg_offset": -7.0},
				{"duration": 0.18, "root_scale": Vector2(1.0, 1.0), "root_pos": Vector2.ZERO, "body_rot": 0.0, "fin_rot": 0.0, "leg_offset": 0.0},
			]
		"sauce_spin":
			return [
				{"duration": 0.08, "root_scale": Vector2(1.08, 1.08), "root_pos": Vector2.ZERO, "body_rot": 0.0, "fin_rot": 35.0, "leg_offset": -4.0},
				{"duration": 0.08, "root_scale": Vector2(1.1, 1.04), "root_pos": Vector2.ZERO, "body_rot": 90.0, "fin_rot": -35.0, "leg_offset": 4.0},
				{"duration": 0.08, "root_scale": Vector2(1.08, 1.08), "root_pos": Vector2.ZERO, "body_rot": 180.0, "fin_rot": 35.0, "leg_offset": -4.0},
				{"duration": 0.08, "root_scale": Vector2(1.1, 1.04), "root_pos": Vector2.ZERO, "body_rot": 270.0, "fin_rot": -35.0, "leg_offset": 4.0},
				{"duration": 0.1, "root_scale": Vector2(1.0, 1.0), "root_pos": Vector2.ZERO, "body_rot": 360.0, "fin_rot": 0.0, "leg_offset": 0.0},
			]
	return []

func _apply_frame(frame: Dictionary) -> void:
	position = frame.get("root_pos", Vector2.ZERO)
	var visual_facing := -facing if using_sprite_art else facing
	scale = Vector2(visual_facing, 1) * frame.get("root_scale", Vector2.ONE)
	var body_rot: float = frame.get("body_rot", 0.0)
	var fin_rot: float = frame.get("fin_rot", 0.0)
	var leg_offset: float = frame.get("leg_offset", 0.0)
	if using_sprite_art:
		_apply_sprite_frame(body_rot, leg_offset)
		return
	parts.body.rotation_degrees = body_rot
	parts.pizza.rotation_degrees = body_rot * 0.55
	parts.fish.rotation_degrees = body_rot * 0.4
	parts.left_fin.rotation_degrees = -8 + fin_rot
	parts.right_fin.rotation_degrees = 8 - fin_rot
	parts.left_leg.position.y = 45 + leg_offset
	parts.right_leg.position.y = 45 - leg_offset
	parts.left_foot.position.y = 67 + leg_offset
	parts.right_foot.position.y = 67 - leg_offset

func _build() -> void:
	if _build_sprite_art():
		return
	parts.body = _add_poly([Vector2(-45, -32), Vector2(39, -32), Vector2(50, 20), Vector2(-38, 30), Vector2(-55, 0)], Color("#f0a736"), true)
	parts.pizza = _add_poly([Vector2(-40, -38), Vector2(36, -66), Vector2(58, -28)], Color("#f14120"), true)
	parts.left_fin = _add_poly([Vector2(-50, -16), Vector2(-82, 0), Vector2(-50, 18)], Color("#ffd86b"), true)
	parts.right_fin = _add_poly([Vector2(46, -16), Vector2(80, 0), Vector2(46, 18)], Color("#ffd86b"), true)
	parts.fish = _add_ellipse(Vector2(0, -34), Vector2(39, 15), Color("#2d9ce3"), true)
	_add_circle(Vector2(-18, -8), 10, Color.WHITE, true)
	_add_circle(Vector2(17, -8), 10, Color.WHITE, true)
	_add_circle(Vector2(-14, -8), 4, Color("#160707"), false)
	_add_circle(Vector2(13, -8), 4, Color("#160707"), false)
	_add_rect(Vector2(-17, 12), Vector2(38, 15), Color("#fff2e2"), true)
	parts.left_leg = _add_rect(Vector2(-32, 45), Vector2(12, 34), Color("#c55a7e"), true)
	parts.right_leg = _add_rect(Vector2(22, 45), Vector2(12, 34), Color("#c55a7e"), true)
	parts.left_foot = _add_ellipse(Vector2(-39, 67), Vector2(28, 10), Color("#ff9b7a"), true)
	parts.right_foot = _add_ellipse(Vector2(37, 67), Vector2(28, 10), Color("#ff9b7a"), true)

func _build_sprite_art() -> bool:
	for frame_name in PLAYER_FRAME_NAMES:
		var path: String = PLAYER_FRAME_DIR + str(frame_name) + ".png"
		var texture := _load_png_texture(path)
		if texture != null:
			sprite_textures[frame_name] = texture
	if not sprite_textures.has("idle_0"):
		return false

	using_sprite_art = true
	sprite = Sprite2D.new()
	sprite.texture = sprite_textures.idle_0
	sprite.centered = true
	sprite.position = Vector2(0, 2)
	add_child(sprite)
	return true

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

func _apply_sprite_frame(body_rot: float, leg_offset: float) -> void:
	var sequence := _sprite_sequence_for(current_animation)
	if not sequence.is_empty():
		var texture_key: String = sequence[min(frame_index, sequence.size() - 1)]
		if sprite_textures.has(texture_key):
			sprite.texture = sprite_textures[texture_key]
	sprite.rotation_degrees = body_rot
	sprite.position.y = 2 + leg_offset * 0.25

func _sprite_sequence_for(animation_name: String) -> Array:
	match animation_name:
		"idle":
			return ["idle_0", "idle_1", "idle_2"]
		"run":
			return ["run_0", "run_1", "run_2", "run_3"]
		"jump", "fall":
			return ["jump_0"]
		"hurt":
			return ["hurt_0", "hurt_0"]
		"death":
			return ["crouch_0"]
		"light_1":
			return ["idle_0", "bite_0", "idle_0"]
		"light_2":
			return ["idle_1", "bite_1", "idle_0"]
		"light_3":
			return ["idle_2", "sauce_0", "idle_0"]
		"heavy":
			return ["crouch_0", "bite_1", "idle_0"]
		"sauce_spin":
			return ["spin_0", "spin_1", "spin_0", "spin_1", "idle_0"]
	return ["idle_0"]

func _add_poly(points: PackedVector2Array, color: Color, outlined: bool) -> Node2D:
	var holder := Node2D.new()
	add_child(holder)
	var poly := Polygon2D.new()
	poly.polygon = points
	poly.color = color
	holder.add_child(poly)
	if outlined:
		var line := Line2D.new()
		line.points = points
		line.closed = true
		line.width = 5
		line.default_color = Color("#160707")
		holder.add_child(line)
	return holder

func _add_circle(pos: Vector2, radius: float, color: Color, outlined: bool) -> Node2D:
	return _add_ellipse(pos, Vector2(radius * 2, radius * 2), color, outlined)

func _add_ellipse(pos: Vector2, size: Vector2, color: Color, outlined: bool) -> Node2D:
	var points := PackedVector2Array()
	for i in range(24):
		var angle := TAU * i / 24.0
		points.append(pos + Vector2(cos(angle) * size.x * 0.5, sin(angle) * size.y * 0.5))
	return _add_poly(points, color, outlined)

func _add_rect(pos: Vector2, size: Vector2, color: Color, outlined: bool) -> Node2D:
	return _add_poly(PackedVector2Array([pos, pos + Vector2(size.x, 0), pos + size, pos + Vector2(0, size.y)]), color, outlined)
