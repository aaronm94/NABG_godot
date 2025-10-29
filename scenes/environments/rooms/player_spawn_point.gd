@tool
extends Node3D

func _ready():
	$"..".connect("dungeon_done_generating", GameState.spawn_player)
