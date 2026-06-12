extends RefCounted
class_name InputSetup

static func configure() -> void:
	var actions := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_SPACE, KEY_W, KEY_UP],
		"light_attack": [KEY_J],
		"heavy_attack": [KEY_K],
		"special_attack": [KEY_L],
		"start": [KEY_ENTER],
	}
	for action in actions:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.25)
		for key_code in actions[action]:
			var key := InputEventKey.new()
			key.physical_keycode = key_code
			_add_event_once(action, key)
	_add_joy_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_joy_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_joy_button("move_left", JOY_BUTTON_DPAD_LEFT)
	_add_joy_button("move_right", JOY_BUTTON_DPAD_RIGHT)
	_add_joy_button("jump", JOY_BUTTON_A)
	_add_joy_button("light_attack", JOY_BUTTON_X)
	_add_joy_button("heavy_attack", JOY_BUTTON_B)
	_add_joy_button("special_attack", JOY_BUTTON_Y)
	_add_joy_button("special_attack", JOY_BUTTON_RIGHT_SHOULDER)
	_add_joy_button("start", JOY_BUTTON_START)

static func _add_joy_button(action: String, button_index: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button_index
	_add_event_once(action, event)

static func _add_joy_axis(action: String, axis_index: JoyAxis, axis_value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis_index
	event.axis_value = axis_value
	_add_event_once(action, event)

static func _add_event_once(action: String, event: InputEvent) -> void:
	for existing in InputMap.action_get_events(action):
		if existing.is_match(event, true):
			return
	InputMap.action_add_event(action, event)
