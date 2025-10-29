extends CanvasLayer

@onready var control: Control = $Control
@onready var vbox: VBoxContainer = $Control/MarginContainer/VBoxContainer

func _ready() -> void:
	# Layer above HUDs and still respond when paused
	layer = 100
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	# Block gameplay clicks
	control.mouse_filter = Control.MOUSE_FILTER_STOP

	visible = get_tree().paused
	GameState.paused_changed.connect(_on_paused_changed)

	# Auto-connect all buttons by name
	for child in vbox.get_children():
		if child is Button:
			child.pressed.connect(_on_button_pressed.bind(child))

func _on_paused_changed(p: bool) -> void:
	visible = p
	if p:
		_focus_first_button()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		GameState.set_paused(false)
		get_viewport().set_input_as_handled()

func _on_button_pressed(button: Button) -> void:
	match button.name.to_lower():
		"resume":
			GameState.set_paused(false)
		"restart":
			GameState.set_paused(false)
			GameState.respawn_player()
		"mainmenu":
			GameState.set_paused(false)
			GameState.goto_scene("res://scenes/ui/main_menu/main_menu.tscn")
		"quit":
			GameState.quit()

func _focus_first_button() -> void:
	for child in vbox.get_children():
		if child is Button:
			child.grab_focus()
			break
