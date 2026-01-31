# Followed tutorial by Godot Dev Checkpoint to learn about windows with Godot
# Used this for window presets (invisible, borderless etc.) and making them move around the screen
# https://www.youtube.com/watch?v=9JHFrnt5j_k

extends Node2D

# Set which Screen the game should use
# var screen_choice = 1 # 0 = primary, 1 = secondary

#get access to the OS Window (not just the game node)
@onready var window = get_window()

# The 'Safe Area' that the window shouldn't leave --- usable_rect() = screen area minus taskbar/docks
var usable_rect = DisplayServer.screen_get_usable_rect()

# Game Stats
var move_speed = usable_rect.size.x * 0.001 # Pet speed based on the size of the screen
var direction = Vector2(0, 0) # Not Moving
var decision_time: bool = false # Pet must wait Timer wait time before making their first decision

# Bug-Testing
var debugMovement = false

func _ready() -> void:
	# DisplayServer.window_set_current_screen.call_deferred(screen_choice)
	print("Screen: ", DisplayServer.window_get_current_screen())
	
	# Prints for bugtesting
	print("Screen End: ", usable_rect.end)
	print("Screen Position: ", usable_rect.position)
	print("Screen Size: ", usable_rect.size)
	
	# Calculates pet (window and sprite) size based on monitor size
	var pet_size = (usable_rect.size.x * usable_rect.size.y) * 0.00002
	var pet_scale = (pet_size/160.0)
	print("Pet Size: ", pet_size)
	print("Pet Scale ", pet_scale)
	window.size = Vector2i(pet_size, pet_size)
	$AnimatedSprite2D.scale = Vector2(pet_scale, pet_scale)
	
	# We enable transparency for both the Godot Viewport and OS Window
	get_viewport().transparent_bg = true
	window.transparent = true

	# We remove the borders so it looks like the character is floating
	window.borderless = true
	
	# Keep them above everything
	window.always_on_top = true
	
	# Force borderless
	window.unresizable = false
	
	# Find the floor
	# Calculate the floor position --- end.y is pixel coordinate where the taskbar starts
	var target_y = usable_rect.size.y - window.size.y
	# Move the sprite there --- x = center of screen, y = the floor
	window.position = Vector2i((usable_rect.size.x / 2) - (window.size.x / 2), target_y)
	
	# Start the timer for pet decision
	$Timer.start()
	
func _process(_delta):
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
			if debugMovement:
				print("Stop")
		elif rand_choice < 0.65 and window.position.x + window.size.x < ((usable_rect.size.x)*0.9):
			direction.x = 1
			decision_time = false
			if debugMovement:
				print("Turn Right")
		elif rand_choice < 0.9 and window.position.x > (usable_rect.size.x * 0.1):
			direction.x = -1
			if debugMovement:
				print("Turn Left")
		else:
			if debugMovement:
				print("No Change")
		decision_time = false
		$Timer.wait_time = rand_wait
		if debugMovement:
			print("Wait ", rand_wait)
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
	if window.position.x + window.size.x > usable_rect.size.x or window.position.x < usable_rect.position.x:
		direction.x = direction.x * -1 # Change Direction
		if $AnimatedSprite2D.flip_h == true:
			$AnimatedSprite2D.flip_h = false
			if debugMovement:
				print("Bounce off left")
		else:
			$AnimatedSprite2D.flip_h = true
			if debugMovement:
				print("Bounce off right")

# Resets the decision timer after random amount of seconds
func _on_timer_timeout():
	decision_time = true
	if debugMovement:
		print("Decide")

# Waits for click to change sprite
# func change_sprite(event):
	
