extends CSGBox3D
class_name ExitDoor


func _ready() -> void:
		pass


func interact() -> void:
	GameState.level_finished()
