# res://scenes/ui/game_menu/game_menu.gd
## In-game menu layer.
## Handles:
##  - Pause menu
##  - Death screen (with delayed buttons + fade-in text)
##  - Level-complete screen

extends CanvasLayer
class_name GameMenu

# ================================
#             ENUMS
# ================================

enum MenuMode { NONE, PAUSE, DEATH, COMPLETE }

# ================================
#        MEMBER VARIABLES
# ================================

var mode: MenuMode = MenuMode.NONE

var death_messages: Dictionary[String, String] = {
	"fall": "You slipped into the void.",
	"enemy_capture": "You were caught.",
	"": "You died."
}

var _last_death_reason: String = ""

const DEATH_MENU_DELAY: float = 2.5

# ================================
#         ONREADY NODES
# ================================

@onready var pause_root: Control = $PauseRoot
@onready var death_root: Control = $DeathRoot
@onready var level_complete_root: Control = $LevelCompleteRoot

@onready var death_label: Label = $DeathRoot/ColorRect/DeathText
@onready var death_buttons: VBoxContainer = $DeathRoot/ColorRect/VBoxContainer
@onready var death_delay_timer: Timer = $DeathDelayTimer

# ================================
#         LIFECYCLE HOOKS
# ================================

func _ready() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	pause_root.visible = false
	death_root.visible = false
	level_complete_root.visible = false
	visible = false

	if is_instance_valid(death_buttons):
		death_buttons.visible = false

	# Timer config
	death_delay_timer.one_shot = true
	death_delay_timer.wait_time = DEATH_MENU_DELAY
	if not death_delay_timer.timeout.is_connected(_on_death_delay_timeout):
		death_delay_timer.timeout.connect(_on_death_delay_timeout)

	# Level complete root mouse capture
	level_complete_root.mouse_filter = Control.MOUSE_FILTER_STOP
	level_complete_root.focus_mode = Control.FOCUS_ALL

	# React to global game state
	GameState.mode_changed.connect(_on_mode_changed)
	GameState.player_died.connect(_on_player_died)

	# Auto-wire all buttons in all menu roots
	_connect_buttons_recursive(pause_root)
	_connect_buttons_recursive(death_root)
	_connect_buttons_recursive(level_complete_root)

# ================================
#           BUTTON WIRING
# ================================

func _connect_buttons_recursive(node: Node) -> void:
	for child in node.get_children():
		if child is Button:
			child.pressed.connect(_on_button_pressed.bind(child))
		_connect_buttons_recursive(child)

func _on_button_pressed(button: Button) -> void:
	var key := button.name.to_lower()

	match key:
		"resume":
			_hide_menu()
			GameState.toggle_pause()
		"restart":
			_hide_menu()
			GameState.restart_level()
		"mainmenu":
			_hide_menu()
			GameState.go_to_main_menu()
		"continue":
			_hide_menu()
			GameState.go_to_main_menu()
		"quit":
			GameState.quit()
		_:
			push_warning("GameMenu: Unknown menu button: %s" % key)

# ================================
#            MODE HANDLING
# ================================

func _show_pause_menu() -> void:
	mode = MenuMode.PAUSE
	visible = true

	pause_root.visible = true
	death_root.visible = false
	level_complete_root.visible = false

func _show_death_menu() -> void:
	mode = MenuMode.DEATH
	visible = true

	pause_root.visible = false
	death_root.visible = true
	level_complete_root.visible = false

	# Hide buttons until delay finishes
	if is_instance_valid(death_buttons):
		death_buttons.visible = false

	# Start label fully transparent, then tween alpha up
	if is_instance_valid(death_label):
		var color := death_label.modulate
		color.a = 0.0
		death_label.modulate = color

		var tween := create_tween()
		# Fade in over time; currently 2× the button delay
		tween.tween_property(
			death_label, "modulate:a", 1.0, DEATH_MENU_DELAY * 2.0
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	death_delay_timer.start()

func _on_death_delay_timeout() -> void:
	# Only show buttons if we're still in DEATH mode
	if mode != MenuMode.DEATH:
		return

	if is_instance_valid(death_buttons):
		death_buttons.visible = true

func _show_level_complete() -> void:
	mode = MenuMode.COMPLETE

	visible = true
	pause_root.visible = false
	death_root.visible = false
	level_complete_root.visible = true

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _hide_menu() -> void:
	mode = MenuMode.NONE

	visible = false
	pause_root.visible = false
	death_root.visible = false
	level_complete_root.visible = false

# ================================
#     HANDLERS FROM GAMESTATE
# ================================

func _on_mode_changed(new_mode: GameState.GameMode) -> void:
	match new_mode:
		GameState.GameMode.PAUSE:
			_show_pause_menu()

		GameState.GameMode.GAMEPLAY:
			# Only hide if we were in PAUSE mode
			if mode == MenuMode.PAUSE:
				_hide_menu()

		GameState.GameMode.DEATH:
			_show_death_menu()

		GameState.GameMode.COMPLETE:
			_show_level_complete()

		GameState.GameMode.MENU:
			# Main menu uses its own UI; hide this one
			_hide_menu()

func _on_player_died(reason: String) -> void:
	_last_death_reason = reason

	if is_instance_valid(death_label):
		var msg: String = death_messages.get(reason, "You died.") as String
		death_label.text = msg
