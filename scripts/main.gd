# Followed tutorial by Godot Dev Checkpoint to learn about windows with Godot
# Used this for window presets (invisible, borderless etc.) and making them move around the screen
# https://www.youtube.com/watch?v=9JHFrnt5j_k

extends Node2D

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D

#get access to the OS Window (not just the game node)
@onready var window = get_window()
@onready var main_screen : int = window.current_screen
# The 'Safe Area' that the window shouldn't leave --- usable_rect() = screen area minus taskbar/docks
var usable_rect = DisplayServer.screen_get_usable_rect(main_screen)

# Game Stats
var move_speed = usable_rect.size.x * 0.001 # Pet speed based on the size of the screen
var direction = Vector2(0, 0) # Not Moving
var decision_time: bool = false # Pet must wait Timer wait time before making their first decision
var pet_type = "" # What species the pet is

# Bug-Testing 
var debugMovement = false
var debugScreen = true

func _ready() -> void:
	# prints to test issues with getting screen data
	if debugScreen:
		print("Window: ", window)
		print("Screen: ", DisplayServer.window_get_current_screen())
		print("Screen End: ", usable_rect.end)
		print("Screen Position: ", usable_rect.position)
		print("Screen Size: ", usable_rect.size)
	
	# Calculates pet (window and sprite) size based on monitor size 
	var pet_size : int = (usable_rect.size.y / 12) # size of the window in pixels
	var pet_scale = (pet_size/16.0) # scale for the sprite to fit in the window
	window.size = Vector2i(pet_size, pet_size)
	$AnimatedSprite2D.scale = Vector2(pet_scale, pet_scale)
	if debugScreen:
		print("Pet Size: ", pet_size)
		print("Pet Scale: ", pet_scale)
	
	# We enable transparency for both the Godot Viewport and OS Window
	get_viewport().transparent_bg = true
	window.transparent = true

	# We remove the borders so it looks like the character is floating
	window.borderless = true
	
	# Keep them above everything
	window.always_on_top = true
	
	# Force borderless
	window.unresizable = false
	
	# Move the sprite to centre of the screen at above the taskbar
	window.position.x = (usable_rect.size.x / 2) - (window.size.x / 2)
	window.position.y = (usable_rect.end.y - window.size.y)
	print("Starting Pet Position: ", window.position)
	
	# Start the timer for pet decision
	$Timer.start()
	
	# Call the function to decide random starting pet, and prints the result
	change_sprite("random")

func _process(_delta):
	# Vector2i used to tell Windows to move to an exact pixel coordinate (integer) 
	# Calculate the move
	var move_vector = Vector2i(direction * move_speed)
	
	brain() # tells the brain to make a decision

	# Apply movement to OS Window
	window.position += move_vector
	
	# Check edges to flip in case touching
	if window.position.x + window.size.x > usable_rect.size.x or window.position.x < 0:
		direction.x = direction.x * -1 # Change Direction
		if sprite.flip_h == true:
			sprite.flip_h = false
			if debugMovement:
				print("Bounce off left")
		else:
			sprite.flip_h = true
			if debugMovement:
				print("Bounce off right")

# Resets the decision timer after random amount of seconds
func _on_timer_timeout():
	decision_time = true
	if debugMovement:
		print("Decide")
		print("Current Position: ", window.position)

# Handles all of the decision making for the Pet
func brain():
	# Randomise decision & time
	var rand_choice = randf()
	var rand_wait = 1.2 # Temporary wait time
	
	# rand multiple of 1.2 or 0.6 depending on species to play animations most cleanly
	if pet_type == "bird":
		rand_wait = randi_range(1, 6) * 0.6
	else: 
		rand_wait = randi_range(1, 3) * 1.2
	
	# Make decision about movement every timer end
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
		sprite.play("walk")
		sprite.flip_h = false
	elif direction.x == -1:
		sprite.play("walk")
		sprite.flip_h = true
	elif direction.x == 0:
		sprite.play("idle")

# Changes sprite when called, takes sprite name or rand for random choice
func change_sprite(choice):
	# establish pet variable to return with chosen pet, we set this here in case it is random
	var random = false
	
	match choice:
		"bird":
			pet_type = "Bird"
			sprite.set_sprite_frames(load("res://sprite_frames/bird.tres"))
		"bunny":
			pet_type = "Bunny"
			sprite.set_sprite_frames(load("res://sprite_frames/bunny.tres"))
		"random": # chooses a random pet using a random integer from a range
			random = true
			match randi_range(1, 2):
				1:
					pet_type = "Bird"
					sprite.set_sprite_frames(load("res://sprite_frames/bird.tres"))
				2:
					pet_type = "Bunny"
					sprite.set_sprite_frames(load("res://sprite_frames/bunny.tres"))
		
	
	# Modifies the string to tell me whether the returned pet was random or chosen, for testing
	if random:
		pet_type = ("Random Pet: " + pet_type)
	else:
		pet_type = ("Chosen Pet: " + pet_type)
	print (pet_type)
