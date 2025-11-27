extends Control

@onready var music_slider: HSlider = $ColorRect/VBoxContainer/Music/MusicSlider
@onready var sfx_slider: HSlider = $ColorRect/VBoxContainer/SFX/SFXSlider
@onready var confirm_button: Button = $ColorRect/ConfirmButton

# Track original confirmed values
var original_music_volume: float
var original_sfx_volume: float

# Track temporary (not confirmed) values
var pending_music_volume: float
var pending_sfx_volume: float


func _ready() -> void:
	# Load last confirmed values from AudioSettings
	original_music_volume = AudioSettings.music_volume
	original_sfx_volume   = AudioSettings.sfx_volume

	# Initialize pending values
	pending_music_volume = original_music_volume
	pending_sfx_volume   = original_sfx_volume

	# Reflect in the UI
	music_slider.value = original_music_volume
	sfx_slider.value   = original_sfx_volume

	# No changes yet → confirm disabled
	confirm_button.disabled = true


# ======================================================
#           SLIDER CALLBACKS (Preview audio live)
# ======================================================

func _on_MusicSlider_value_changed(value: float) -> void:
	pending_music_volume = value
	AudioSettings.set_music_volume(value)
	_update_confirm_state()


func _on_SFXSlider_value_changed(value: float) -> void:
	pending_sfx_volume = value
	AudioSettings.set_sfx_volume(value)
	_update_confirm_state()


# ======================================================
#           BUTTONS
# ======================================================

func _on_ConfirmButton_pressed() -> void:
	# Commit changes
	original_music_volume = pending_music_volume
	original_sfx_volume   = pending_sfx_volume

	AudioSettings.set_music_volume(original_music_volume)
	AudioSettings.set_sfx_volume(original_sfx_volume)

	confirm_button.disabled = true


func _on_BackButton_pressed() -> void:
	# Revert changes
	AudioSettings.set_music_volume(original_music_volume)
	AudioSettings.set_sfx_volume(original_sfx_volume)

	GameState.goto_scene("res://scenes/ui/main_menu/main_menu.tscn")


# ======================================================
#     INTERNAL: Enable/Disable Confirm Button
# ======================================================

func _update_confirm_state() -> void:
	# Only enable confirm if *either* volume has changed
	var changed := (
		pending_music_volume != original_music_volume
		or pending_sfx_volume != original_sfx_volume
	)

	confirm_button.disabled = not changed
