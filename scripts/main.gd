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
enum Types {BIRD, BUNNY} # Possible species that the pet can be
var type:Types = Types.BIRD # What species the pet is (bird set as default)
enum Activities {IDLE, WALKING, SITTING} # Possible states for Pet
var activity:Activities = Activities.IDLE # Current state of Pet (idle set as default)

# Global Booleans
var decision_time: bool = false # Pet must wait Timer wait time before making their first decision
var move_time: bool = false # Specific pets only move during set intervals to make animations seem clean

# Bug-Testing 
var debugMovement = true
var debugScreen = false

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
	$DecisionTimer.start()
	
	# Call the function to decide random or specific starting pet, and prints the result
	change_type("random")

func _process(_delta):
	
	# Make decision about movement every timer end
	if decision_time == true:
		brain() # tells the brain to make a decision
	
	sprite_set() # changes the Pet's sprite to match what they're doing
	
	if activity == Activities.WALKING: # only if pet is moving
		move() # moves the pet depending on the activity and type of the pet
	
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

# Moves the window around the screen depending on state and type
func move():
	# Vector2i used to tell Windows to move to an exact pixel coordinate (integer)
	var move_vector = Vector2i(direction * move_speed) # how Pet will move around screen
	
	## In-progress code to make the Bunny move differently to make the animation look smoother
	# Apply movement to OS Window depending on type
	#if pet_type == "bunny":
		#if move_time:
			#window.position += move_vector
			#$BunnyTimer.start() # starts the timer to count down till change
		#else:
			#$BunnyTimer.start() # starts the timer to count down till change
	#else:
	
	window.position += move_vector

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
	
	match activity:
		Activities.SITTING:
			if rand_choice < 0.7:
				activity = Activities.IDLE
				direction.x = 0
				if debugMovement:
					print("Get Up")
			else:
				if debugMovement:
					print("No Change")
		_:
			if rand_choice < 0.4:
				if activity == Activities.WALKING : # Sets Pet to stop
					activity = Activities.IDLE
					direction.x = 0
					if debugMovement:
						print("Stop")
				elif activity == Activities.IDLE: # Sets Pet to sit if already stopped
					activity = Activities.SITTING
					if debugMovement:
						print("Sit")
			elif rand_choice < 0.65 and window.position.x + window.size.x < ((usable_rect.size.x)*0.9):
				activity = Activities.WALKING
				direction.x = 1
				if debugMovement:
					print("Turn Right")
			elif rand_choice < 0.9 and window.position.x > (usable_rect.size.x * 0.1):
				activity = Activities.WALKING
				direction.x = -1
				if debugMovement:
					print("Turn Left")
			else:
				if debugMovement:
					print("No Change")
	
	match activity:
		Activities.IDLE: # wait time doesn't matter because no animation
			rand_wait = snappedf(randf_range(0.8, 3.9), 0.1) # rand num between 0.8 and 3.9 to 1 decimal place
		Activities.SITTING:
			rand_wait = snappedf(randf_range(2.0, 4.5), 0.1) # higher floor because sit for 1 second feels wrong
		_: # multiple of 1.2 or 0.6 depending on species to play animations most cleanly
			if type == Types.BIRD: # Pets with animations that can stop halfway
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
			$BunnyTimer.wait_time = 0.8
		"random": # chooses a random pet using a random integer from a range
			random = true
			match randi_range(1, 2):
				1:
					type = Types.BIRD
					chosen_type = "Bird"
					sprite.set_sprite_frames(load("res://sprite_frames/bird.tres"))
				2:
					type = Types.BUNNY
					chosen_type = "Bunny"
					sprite.set_sprite_frames(load("res://sprite_frames/bunny.tres"))
		
	
	# Modifies the string to tell me whether the returned pet was random or chosen, for testing
	if random:
		print ("Random Pet: ", chosen_type)
	else:
		print ("Chosen Pet: ", chosen_type)

# Resets the Decision timer after random amount of seconds
func _on_timer_timeout() -> void:
	decision_time = true
	if debugMovement:
		print("Decide")
		print("Current Position: ", window.position)

# Resets the Bunny movement timer after random amount of seconds
func _on_bunny_timer_timeout() -> void:
	if move_time:
		move_time = false
	else:
		move_time = true
	print("Bunny Timer Over, Move Time: ", move_time)
