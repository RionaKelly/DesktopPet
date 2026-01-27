#Followed tutorial by Godot Dev Checkpoint to learn about making the Windows function for this game
extends Node2D

var move_speed = 5
var direction = Vector2(1, 0) # Moving Right
var decision_time: bool = true

func _ready() -> void:
	#get access to the OS Window (not just the game node)
	var window = get_window()
	
	# We enable transparency for both the Godot Viewport and OS Window
	get_viewport().transparent_bg = true
	window.transparent = true

	# We remove the borders so it looks like the character is floating
	window.borderless = true
	
	# Keep them above everything
	window.always_on_top = true
	
	# Force Windows to let us be borderless
	window.unresizable = false
	
	# Find the floor
	# 1. Get the safe area of screen
	var usable_rect = DisplayServer.screen_get_usable_rect()
	# 2. Calculate the floor position
	# end.y is pixel coordinate where the taskbar starts
	var target_y = usable_rect.end.y - window.size.y
	# 3. Move the sprite there
	# x = 0 (left edge), y = target_y (the floor)
	window.position = Vector2i(0, target_y)
	
func _process(_delta):
	#get access to the OS Window (not just the game node)
	var window = get_window()
	
	# The Safe Area
	# screen_get_usable_rect() returns screen area minus taskbar/docks
	var usable_rect = DisplayServer.screen_get_usable_rect()
	
	# Vector2i used to tell Windows to move to an exact pixel coordinate (integer) 
	# Calculate the move
	var move_vector = Vector2i(direction * move_speed)
	
	# Randomise decision & time
	var rand_choice = randf()
	var rand_wait = snappedf(randf_range(0.8, 3.9), 0.01) # rand num between 0.8 and 3.9 (3 digits max)
	
	# Make decision about movement every second
	if decision_time == true:
		if rand_choice < 0.4 and direction.x != 0:
			direction.x = 0
			print("Stop")
		elif rand_choice < 0.65 and window.position.x + window.size.x < ((usable_rect.end.x)*0.9):
			direction.x = 1
			decision_time = false
			print("Turn Right")
		elif rand_choice < 0.9 and window.position.x > (usable_rect.end.x * 0.1):
			direction.x = -1
			print("Turn Left")
		else:
			print("No Change")
		decision_time = false
		$Timer.wait_time = rand_wait
		print(rand_wait)
		$Timer.start()
		
	# Makes pet face the right direction and play the right animation after moving/stopping
	if direction.x == 1:
		$AnimatedSprite2D.set_animation("walk")
		$AnimatedSprite2D.flip_h = false
	elif direction.x == -1:
		$AnimatedSprite2D.set_animation("walk")
		$AnimatedSprite2D.flip_h = true
	elif direction.x == 0:
		$AnimatedSprite2D.set_animation("idle")

	# Apply movement to OS Window
	window.position += move_vector
	
	# Check edges to flip in case touching
	if window.position.x + window.size.x > usable_rect.end.x or window.position.x < usable_rect.position.x:
		direction.x = direction.x * -1 # Change Direction
		if $AnimatedSprite2D.flip_h == true:
			$AnimatedSprite2D.flip_h = false
		else:
			$AnimatedSprite2D.flip_h = true

# Resets the decision timer after random amount of seconds
func _on_timer_timeout():
	decision_time = true
	print("Decide")
