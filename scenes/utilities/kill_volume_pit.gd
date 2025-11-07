# scenes/props/kill_volume_pit.gd
extends Area3D
@export var death_reason: String = "Fell into pit"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	# Only kill the player, ignore others
	if body.is_in_group("player"):
		GameState.kill_player(death_reason)
