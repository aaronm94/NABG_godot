extends CanvasLayer

enum MenuMode { NONE, PAUSE, DEATH }
var mode: MenuMode = MenuMode.NONE

@onready var pause_root: Control = $PauseRoot
@onready var death_root: Control = $DeathRoot

@onready var death_label: Label = $DeathRoot/ColorRect/DeathText
@onready var death_buttons: VBoxContainer = $DeathRoot/ColorRect/VBoxContainer
@onready var death_delay_timer: Timer = $DeathDelayTimer

var death_messages : Dictionary[String, String] = {
	"fall": "You slipped into the void.",
	"enemy_capture": "You were caught.",
	"": "You died."
}

var _last_death_reason: String = ""

const DEATH_MENU_DELAY: float = 2.5


func _ready() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	pause_root.visible = false
	death_root.visible = false
	visible = false
	
	# Hide buttons initially
	if is_instance_valid(death_buttons):
		death_buttons.visible = false

	# Timer config
	death_delay_timer.one_shot = true
	death_delay_timer.wait_time = DEATH_MENU_DELAY

	# React to global state
	GameState.mode_changed.connect(_on_mode_changed)
	GameState.player_died.connect(_on_player_died)
	
	# Auto-wire all buttons in both roots
	_connect_buttons_recursive(pause_root)
	_connect_buttons_recursive(death_root)

# ===================================================
#              BUTTON WIRING
# ===================================================

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
		"quit":
			GameState.quit()
		_:
			push_warning("Unknown menu button: %s" % key)

# ===================================================
#                MODE HANDLING
# ===================================================

func _show_pause_menu() -> void:
	mode = MenuMode.PAUSE
	visible = true
	pause_root.visible = true
	death_root.visible = false

func _show_death_menu() -> void:
	mode = MenuMode.DEATH
	visible = true
	pause_root.visible = false
	death_root.visible = true

	# Hide buttons until delay finishes
	if is_instance_valid(death_buttons):
		death_buttons.visible = false

	# Start label fully transparent, then tween alpha to 1
	if is_instance_valid(death_label):
		var color := death_label.modulate
		color.a = 0.0
		death_label.modulate = color

		var tween := create_tween()
		# Fade over the same time as the delay
		tween.tween_property(death_label, "modulate:a", 1.0, DEATH_MENU_DELAY* 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Start the timer; when it finishes, we'll show the buttons
	death_delay_timer.start()

func _on_death_delay_timeout() -> void:
	# Only show if we're still in DEATH mode
	if mode != MenuMode.DEATH:
		return

	if is_instance_valid(death_buttons):
		death_buttons.visible = true

func _hide_menu() -> void:
	mode = MenuMode.NONE
	visible = false
	pause_root.visible = false
	death_root.visible = false


# ===================================================
#           SIGNAL HANDLERS FROM GAMESTATE
# ===================================================

func _on_mode_changed(new_mode: GameState.GameMode) -> void:
	match new_mode:
		GameState.GameMode.PAUSED:
			_show_pause_menu()

		GameState.GameMode.GAMEPLAY:
			# Only hide if we were in PAUSE mode
			if mode == MenuMode.PAUSE:
				_hide_menu()

		GameState.GameMode.DEATH:
			_show_death_menu()

		GameState.GameMode.MENU:
			# Main menu likely uses separate UI; hide in-game menu
			_hide_menu()

func _on_player_died(reason: String) -> void:
	_last_death_reason = reason

	if is_instance_valid(death_label):
		var msg: String = death_messages.get(reason, "You died.") as String
		death_label.text = msg
