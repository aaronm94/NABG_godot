extends Control


func startbutton_pressed():
	pass # Replace with function body.
	get_tree().change_scene_to_file("res://scenes/environments/first_floor.tscn")

func exitbutton_pressed():
	pass # Replace with function body.
	get_tree().quit()


func options_pressed():
	pass # Replace with function body.
	get_tree().change_scene_to_file("res://MainMenu/options.tscn")
