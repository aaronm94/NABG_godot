# interactable.gd
extends Node
class_name Interactable

func interact(_by:= null) -> void:
	push_warning("%s: interact() not implemented" % get_path())
