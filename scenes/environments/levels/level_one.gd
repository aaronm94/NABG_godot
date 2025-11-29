extends Node3D

@onready var enemy_scene = preload("res://scenes/environments/entities/enemy/chaser.tscn")

func _ready():
	spawn_enemy_after_delay(15.0)

func spawn_enemy_after_delay(t: float) -> void:
	await get_tree().create_timer(t).timeout
	spawn_enemy()


func spawn_enemy():
	var enemy = enemy_scene.instantiate()
	add_child(enemy)

	# Find player through group "player"
	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		print("No player found!")
		return

	var player = players[0]                            # FIXED (no := inference)
	var origin = player.global_transform.origin        # FIXED

	# Spawn enemy somewhere behind/right of player
	enemy.global_transform.origin = origin + Vector3(
		randf_range(-12, -6),
		0,
		randf_range(-12, -6)
	)

	# Match player movement speed (base walk)
	if player.has_variable("base_speed"):
		enemy.base_speed = player.base_speed

	print("Enemy spawned at: ", enemy.global_transform.origin)
