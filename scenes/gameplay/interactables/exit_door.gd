# res://scenes/gameplay/interactables/exit_door.gd
## Exit door that triggers level completion when interacted with.
## (Future-proofed for key requirements or SFX.)

extends CSGBox3D
class_name ExitDoor

# ================================
#             EXPORTS
# ================================

## Optional SFX for opening/activation.
@export var activate_sfx_id: String = ""

## Whether the door requires a key (future behaviour).
@export var requires_key: bool = false

# ================================
#         ONREADY NODES
# ================================

@onready var hover_label: Label3D = $HoverLabel

# ================================
#         LIFECYCLE HOOKS
# ================================

func _ready() -> void:
	hover_label.visible = false

# ================================
#        HIGHLIGHT / UI LOGIC
# ================================

## Show or hide the hover label when the player looks at the door.
func set_highlighted(on: bool) -> void:
	hover_label.visible = on

# ================================
#            INTERACTION
# ================================

## Called by the player's interaction system.
func interact() -> void:
	# Only if key picked up, not yet implemented so skip to level complete
	GameState.level_complete()
