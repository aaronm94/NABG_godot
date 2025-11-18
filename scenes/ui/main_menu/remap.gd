extends Button
@export var action : String
@onready var input_mapper: Control = $".."

func _init():
	toggle_mode = true

func _ready():
	set_process_unhandled_input(false)

func _toggled(button_pressed):
	set_process_unhandled_input(button_pressed)
	if button_pressed:
		text = "Awaiting"

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		
		if event.keycode == 0:
			if event.shift_pressed:
				event.keycode = KEY_SHIFT
				# Optional: distinguish left/right:
				if event.physical_keycode == KEY_SHIFT:
					event.keycode = event.physical_keycode
			elif event.ctrl_pressed:
				event.keycode = KEY_CTRL
			elif event.alt_pressed:
				event.keycode = KEY_ALT
		
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, event)
		input_mapper.keymaps[action] = event
		input_mapper.save_keymap()
		button_pressed = false
		release_focus()
		update_text()

func update_text():
	text = InputMap.action_get_events(action)[0].as_text()
