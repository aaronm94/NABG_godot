# interactable.gd
extends Node3D
class_name Interactable

func interact(_by: Node) -> void:
	push_warning("%s: interact() not implemented" % get_path())

func set_highlighted(_on: bool) -> void:
	# Optional; children override if they have a highlight
	pass
