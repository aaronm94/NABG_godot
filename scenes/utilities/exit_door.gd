extends CSGBox3D
class_name ExitDoor

@onready var hover_label: Label3D = $HoverLabel

func _ready() -> void:
		hover_label.visible = false

func set_highlighted(on: bool) -> void:
	if not on:
		hover_label.visible = false
		return

	hover_label.visible = true

func interact() -> void:
	# Only if has key, not yet
	GameState.level_complete()
