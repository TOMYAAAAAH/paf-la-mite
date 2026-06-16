extends Node2D

# Connect this function to the Button's "pressed" signal
func _on_reset_button_pressed():
	# Reloads the current scene, effectively resetting the game
	get_tree().reload_current_scene()
