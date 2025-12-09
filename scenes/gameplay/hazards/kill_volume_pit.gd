# res://scenes/gameplay/hazards/kill_volume_pit.gd
## Kill volume that triggers player death when entered (e.g., pits or drop-offs).

extends Area3D
class_name KillVolumePit

# ================================
#             EXPORTS
# ================================

@export_enum("fall", "enemy_capture")
var death_reason: String = "fall"

## Optional override for the SFX played when falling.
## If empty, default SFX from AudioManager is used.
@export var death_sfx_id: String = ""

# ================================
#         LIFECYCLE HOOKS
# ================================

func _ready() -> void:
	body_entered.connect(_on_body_entered)

# ================================
#            SIGNAL HANDLERS
# ================================

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	_kill_now()

# ================================
#            KILL LOGIC
# ================================

func _kill_now() -> void:
	var sfx_id := death_sfx_id
	if sfx_id.is_empty():
		# Use the central default "fall" SFX from AudioManager
		sfx_id = AudioManager.SFX_DEATH_FALL if AudioManager.has_method("play_sfx") else "death_fall"

	AudioManager.play_sfx(sfx_id)
	GameState.kill_player(death_reason)
