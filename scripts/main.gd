# Followed tutorial by Godot Dev Checkpoint to learn about windows with Godot
# Used this for window presets (invisible, borderless etc.) and making them move around the screen
# https://www.youtube.com/watch?v=9JHFrnt5j_k

extends Node2D

@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D

#get access to the OS Window (not just the game node)
@onready var window : Window = get_window()
# @onready var main_screen : int = window.current_screen
# The 'Safe Area' that the window shouldn't leave --- usable_rect() = screen area minus taskbar/docks
var usable_rect = DisplayServer.screen_get_usable_rect()
# var screen_size = DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
var taskbar_level = usable_rect.end.y

# Pet Stats
var move_speed = usable_rect.size.x * 0.001 # Pet speed based on the size of the screen
var direction = Vector2(0, 0) # Not Moving
enum Types {BIRD, BUNNY, OCTOPUS} # Possible species that the pet can be
var type : Types = Types.BIRD # What species the pet is (bird set as default)
enum Activities {CLICKED, GREETING, IDLE, SITTING, WALKING, STARING} # Possible states for Pet
var activity:  Activities = Activities.IDLE # Current state of Pet (idle set as default)

# Game Variables
var decision_time : bool = false # Pet must wait Timer wait time before making their first decision
var save_time : bool = false # Game waits 10 seconds before saving using this bool
var fall_time : bool = true # Countdown to slowly increase fall speed to feel better
var screen_count : int = DisplayServer.get_screen_count() # How many monitors the player has
var gravity : bool = true # Gravity to keep Pet on taskbar, disabled when lifting
var OS_base_color : Color = DisplayServer.get_base_color() # Find the computer's chosen base colour
var OS_accent_color : Color = DisplayServer.get_accent_color() # Find the computer's chosen accent colour

# Bug-Testing 
var debugMovement = false
var debugScreen = true


## Notes:
## Use os theme colour to colour ui, tint b&w images
## One Click gets pets attention and stops them say hi, after too many clicks gets mad
## Hold Click on pet lets you drag them around
## Two Clicks on pet opens menu

func _ready() -> void:
	# Prints to test issues with getting screen data
	if debugScreen:
		print("_Debug Info_")
		print("Current Screen: ", window.current_screen)
		print("Primary Screen: ", DisplayServer.get_primary_screen())
		print("Screen Count: ", screen_count)
		print("Usable Rect: ", usable_rect)
		print("Taskbar Level: ", taskbar_level)
		print("Operating System: ", DisplayServer.get_name())
		print("")
		print(OS_accent_color, OS_base_color)
		
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
	window.unresizable = true
	
	# Move the sprite to centre of the screen at above the taskbar
	#window.position.x = (usable_rect.size.x / 2) - (window.size.x / 2)
	#window.position.y = (usable_rect.size.y - window.size.y)
	window.position = Vector2i(DisplayServer.screen_get_size().x/2 - (window.size.x/2), taskbar_level - window.size.y)
	print("Starting Pet Position: ", window.position)
	
	# Start the timer for pet decision
	$DecisionTimer.start()
	
	# Call the function to decide random or specific starting pet, and prints the result
	change_type("random")

func _process(_delta):
	# Vector2i used to tell Windows to move to an exact pixel coordinate (integer)
	var move_vector = Vector2i(direction * move_speed) # How Pet will move around screen
	
	# Make decision about movement every timer end
	if decision_time == true:
		brain() # tells the brain to make a decision
	
	sprite_set() # changes the Pet's sprite to match what they're doing
	
	if activity == Activities.WALKING: # only if pet is moving
		move(move_vector) # moves the pet depending on the activity and type of the pet
	
	# Check edges to flip in case touching, sprite flip done in sprite_set()
	if window.position.x < 0:
		direction.x = 1 # Change Direction
		if debugMovement:
				print("Bounce off left")
	if window.position.x + window.size.x > usable_rect.size.x:
		direction.x = -1 # Change Direction
		if debugMovement:
				print("Bounce off right")
	
	if save_time:
		save()
	
	# Check if pet is above taskbar to fall back down (if gravity is enabled)
	if gravity || (window.position.y != (taskbar_level - window.size.y)):
		if fall_time:
			direction.y += 1
			fall_time = false
			$FallTimer.start()
		if window.position.y < (taskbar_level - window.size.y):
			window.position.y += move_vector.y
		elif window.position.y > (taskbar_level - window.size.y):
			$FallTimer.stop()
			window.position.y = (taskbar_level - window.size.y)
			activity = Activities.SITTING
			direction.x = 0
			if debugMovement:
				print("Sit")
	if window.position.y == (taskbar_level - window.size.y):
		direction.y = 0
		$FallTimer.stop()

# Moves the window around the screen depending on state and type
func move(move_vector):
	var current_frame = $AnimatedSprite2D.get_frame()
	
	# In-progress code to make the Bunny move differently to make the animation look smoother
	# Apply movement to OS Window depending on type
	if type == Types.BUNNY:
		if current_frame == 3 or current_frame == 4 or current_frame == 5:
			window.position.x += move_vector.x
		else:
			pass
	else:
		window.position.x += move_vector.x

# Sets the Pet's sprite/animation to match state
func sprite_set():
	# Makes pet face the right direction and play the right animation after moving/stopping
	match activity:
		Activities.IDLE:
			sprite.play("idle")
			if direction.x != 0: # This should happen anyway but I check here just in case
				direction.x = 0 
		Activities.SITTING:
			sprite.play("sit")
		Activities.WALKING:
			sprite.play("walk")
			if direction.x == 1:
				sprite.flip_h = false
			elif direction.x == -1:
				sprite.flip_h = true
			else: # extra check just in case direction variable is doing something weird
				print("Direction [", direction.x, "] outside of given rage")
		_:
			print("Activity [", activity, "] not recognised")

# Handles all of the decision making for the Pet
func brain():
	# Randomise decision & time
	var rand_choice = randf()
	var rand_wait = 1.2 # Temporary wait time to establish variable
	
	# Decides the Pet's next action based on what they are currently doing and a random number
	match activity:
		Activities.IDLE: # 3 : 3.5 : 3.5
			if rand_choice < 0.3:
				activity = Activities.SITTING
				direction.x = 0
				if debugMovement:
					print("Sit")
			elif rand_choice < 0.65 and window.position.x + window.size.x < ((usable_rect.size.x)*0.9):
				activity = Activities.WALKING
				direction.x = 1
				if debugMovement:
					print("Turn Right")
			elif window.position.x > (usable_rect.size.x * 0.1):
				activity = Activities.WALKING
				direction.x = -1
				if debugMovement:
					print("Turn Left")
		Activities.SITTING: # 7 : 3
			if rand_choice < 0.7:
				activity = Activities.IDLE
				direction.x = 0
				if debugMovement:
					print("Get Up")
			else:
				if debugMovement:
					print("Continue Sitting")
		Activities.WALKING: # 6 : 4
			if rand_choice < 0.6:
				activity = Activities.IDLE
				direction.x = 0
				if debugMovement:
					print("Stop")
			else:
				if debugMovement:
					print("Continue Walking")
		_:
			if debugMovement:
					print("No Change")
	
	match activity:
		Activities.IDLE: # wait time doesn't matter because no animation
			rand_wait = snappedf(randf_range(0.8, 3.9), 0.1) # rand num between 0.8 and 3.9 to 1 decimal place
		Activities.SITTING:
			rand_wait = snappedf(randf_range(2.0, 4.5), 0.1) # higher floor because sit for 1 second feels wrong
		_: # multiple of 1.2 or 0.6 depending on species to play animations most cleanly
			if type == Types.BIRD or type == Types.OCTOPUS: # Pets with animations that can stop halfway
				rand_wait = randi_range(1, 6) * 0.8
			else: 
				rand_wait = randi_range(1, 3) * 1.6
	
	decision_time = false
	
	if debugMovement:
		print("Wait ", rand_wait)
	$DecisionTimer.wait_time = rand_wait
	$DecisionTimer.start()

# Changes Pet's type and sprite set to given species or random
func change_type(choice):
	# establish pet variable to return with chosen pet, we set this here in case it is random
	var random = false
	var chosen_type:String = ""
	
	match choice:
		"bird":
			type = Types.BIRD
			chosen_type = "Bird"
			sprite.set_sprite_frames(load("res://sprite_frames/bird.tres"))
		"bunny":
			type = Types.BUNNY
			chosen_type = "Bunny"
			sprite.set_sprite_frames(load("res://sprite_frames/bunny.tres"))
		"octopus":
			type = Types.OCTOPUS
			chosen_type = "Octopus"
			sprite.set_sprite_frames(load("res://sprite_frames/octopus.tres"))
		"random": # chooses a random pet using a random integer from a range
			random = true
			match randi_range(1, 3):
				1:
					type = Types.BIRD
					chosen_type = "Bird"
					sprite.set_sprite_frames(load("res://sprite_frames/bird.tres"))
				2:
					type = Types.BUNNY
					chosen_type = "Bunny"
					sprite.set_sprite_frames(load("res://sprite_frames/bunny.tres"))
				3:
					type = Types.OCTOPUS
					chosen_type = "Octopus"
					sprite.set_sprite_frames(load("res://sprite_frames/octopus.tres"))
		_: # defaults to bird
			type = Types.BIRD
			chosen_type = "Bird"
			sprite.set_sprite_frames(load("res://sprite_frames/bird.tres"))
	
	# Modifies the string to tell me whether the returned pet was random or chosen, for testing
	if random:
		print ("Random Pet: ", chosen_type)
	else:
		print ("Chosen Pet: ", chosen_type)

# Saves the game's progress when called every 10 seconds
func save():
	print("Saving...")
	save_time = false

# Resets the Decision timer after random amount of seconds
func _on_timer_timeout() -> void:
	decision_time = true
	if debugMovement:
		print("Decide")
		print("Current Position: ", window.position)

func _on_save_timer_timeout() -> void:
	save_time = true

func _on_fall_timer_timeout() -> void:
	fall_time = true
	print(window.position)
