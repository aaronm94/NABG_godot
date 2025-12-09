# res://scenes/gameplay/interactables/interactable.gd
## Base class for all interactable objects in the game.
## Override `interact(by)` and `set_highlighted(on)` in child classes.

extends Node3D
class_name Interactable

# ================================
#            METHODS
# ================================

## Called when a player (or other actor) interacts with this object.
## Child classes should override this to provide behaviour.
func interact() -> void:
	push_warning("%s: interact() not implemented (caller: %s)" % get_path())

## Called when this object should visually indicate focus / highlight.
## Child classes can override to enable hover labels, outlines, etc.
func set_highlighted(_on: bool) -> void:
	# Optional; children override if they have a highlight
	pass
