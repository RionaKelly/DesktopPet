extends Node2D

# Check for inputs
func _input(event):
	# Check for Left Mouse Button Press
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not $Pet.is_stopped:
			$Pet.start_stopping(true)
		
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed == false and $Pet.is_stopped:
		if $Pet.is_stopped:
			$Pet.start_stopping(false)
