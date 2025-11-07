# interactable.gd
extends Node
class_name Interactable

func interact(__: Node = null) -> void:
	push_warning("%s: interact() not implemented" % get_path())
