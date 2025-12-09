# res://scenes/ui/main_menu/options.gd
## Options menu for adjusting Music and SFX volumes.
## Supports live preview (sliders) and confirm/revert behavior.

extends Control
class_name OptionsMenu

# ================================
#         ONREADY NODES
# ================================

@onready var music_slider: HSlider = $ColorRect/VBoxContainer/Music/MusicSlider
@onready var sfx_slider: HSlider = $ColorRect/VBoxContainer/SFX/SFXSlider
@onready var confirm_button: Button = $ColorRect/ConfirmButton

# ================================
#       VOLUME STATE TRACKING
# ================================

var original_music_volume: float
var original_sfx_volume: float

var pending_music_volume: float
var pending_sfx_volume: float

# ================================
#             READY
# ================================

func _ready() -> void:
	# Load last confirmed values from AudioSettings
	original_music_volume = AudioSettings.music_volume
	original_sfx_volume   = AudioSettings.sfx_volume

	pending_music_volume = original_music_volume
	pending_sfx_volume   = original_sfx_volume

	# Initialize UI
	music_slider.value = original_music_volume
	sfx_slider.value   = original_sfx_volume

	# No changes yet
	confirm_button.disabled = true

	# Ensure menu is unpaused and mouse is free
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# ================================
#       SLIDER CALLBACKS
# ================================

func _on_MusicSlider_value_changed(value: float) -> void:
	pending_music_volume = value
	AudioSettings.set_music_volume(value)
	_update_confirm_state()

func _on_SFXSlider_value_changed(value: float) -> void:
	pending_sfx_volume = value
	AudioSettings.set_sfx_volume(value)
	_update_confirm_state()

# ================================
#          BUTTON CALLBACKS
# ================================

func _on_ConfirmButton_pressed() -> void:
	# Commit changes to AudioSettings
	original_music_volume = pending_music_volume
	original_sfx_volume   = pending_sfx_volume

	AudioSettings.set_music_volume(original_music_volume)
	AudioSettings.set_sfx_volume(original_sfx_volume)

	confirm_button.disabled = true

func _on_BackButton_pressed() -> void:
	# Revert unconfirmed changes
	AudioSettings.set_music_volume(original_music_volume)
	AudioSettings.set_sfx_volume(original_sfx_volume)

	GameState.goto_scene("res://scenes/ui/main_menu/main_menu.tscn")

# ================================
#        INTERNAL HELPERS
# ================================

func _update_confirm_state() -> void:
	var changed := (
		pending_music_volume != original_music_volume
		or pending_sfx_volume != original_sfx_volume
	)
	confirm_button.disabled = not changed
