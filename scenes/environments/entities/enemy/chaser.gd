extends CharacterBody3D

@export var base_speed: float = 5.0
@export var speed_increase_amount: float = 0.5
@export var speed_increase_interval: float = 60.0
@export var acceleration: float = 6.0

var current_speed: float
var time_since_increase := 0.0
var player: CharacterBody3D

@onready var hitbox = $Hitbox


func _ready():
	# Try to find player immediately (may fail)
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

	current_speed = base_speed

	# Connect kill collision
	hitbox.body_entered.connect(_on_body_entered)


# Keep searching until player exists
func _process(_delta: float) -> void:
	if player == null:
		print("Chaser: player still NULL, searching...")

		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
			print("Chaser: found player after generation!")
		return


func _physics_process(delta):
	print("Enemy moving toward:", player.global_transform.origin)
	if player == null:
		return

	# Speed ramp
	time_since_increase += delta
	if time_since_increase >= speed_increase_interval:
		current_speed += speed_increase_amount
		time_since_increase = 0.0
		print("Chaser speed increased:", current_speed)

	# Chase
	var dir = (player.global_transform.origin - global_transform.origin).normalized()
	velocity = velocity.lerp(dir * current_speed, acceleration * delta)
	move_and_slide()


# Kill player on contact
func _on_body_entered(body):
	if body.is_in_group("player"):
		print("Player touched enemy → YOU DIED")

		body.can_move = false
		if body.has_variable("health"):
			body.health = 0
