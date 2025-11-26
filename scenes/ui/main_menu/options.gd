extends Control

@onready var music_slider: HSlider = $ColorRect/Music/MusicSlider
@onready var confirm_button: Button = $ColorRect/ConfirmButton

var original_volume: float
var pending_volume: float

func _ready() -> void:
	# Load last confirmed volume from AudioSettings
	original_volume = AudioSettings.music_volume        # 0.0 – 1.0
	pending_volume = original_volume

	# Show it on the slider
	music_slider.value = original_volume

	# Disable confirm (no changes yet)
	confirm_button.disabled = true

func _on_MusicSlider_value_changed(value: float) -> void:
	# Update pending value *and* preview it immediately
	pending_volume = value
	AudioSettings.set_music_volume(pending_volume)

	# Enable confirm only if value differs from original
	confirm_button.disabled = (pending_volume == original_volume)

func _on_ConfirmButton_pressed() -> void:
	# Save changes
	AudioSettings.set_music_volume(pending_volume)
	original_volume = pending_volume

	# Disable confirm — no more pending changes
	confirm_button.disabled = true

func _on_BackButton_pressed() -> void:
	# Discard any unconfirmed changes: revert to last confirmed volume
	AudioSettings.set_music_volume(original_volume)

	GameState.goto_scene("res://scenes/ui/main_menu/main_menu.tscn")
