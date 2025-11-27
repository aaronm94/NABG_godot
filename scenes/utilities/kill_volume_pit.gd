# scenes/props/kill_volume_pit.gd
extends Area3D
@export_enum("fall", "enemy_capture") var death_reason: String = "fall"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	# Only kill the player, ignore others
	if not body.is_in_group("player"):
		return
	AudioManager.play_sfx("death_fall")
	GameState.kill_player(death_reason)
