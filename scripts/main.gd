# Followed tutorial by Godot Dev Checkpoint to learn about windows with Godot
# Used this for window presets, making window around the screen, clicking through window, and performance enhancements
# https://youtube.com/playlist?list=PLVzjdZVCXNTyVHAtpgF_uFbsz8MA8uWKO&si=FOG2BfnqTqjJTduE

extends Node2D

@onready var sprite : AnimatedSprite2D = $PetSprite

#get access to the OS Window (not just the game node)
@onready var window : Window = get_window()
# @onready var main_screen : int = window.current_screen
# The 'Safe Area' that the window shouldn't leave --- usable_rect() = screen area minus taskbar/docks
var usable_rect = DisplayServer.screen_get_usable_rect()
# var screen_size = DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
var taskbar_level = usable_rect.end.y

# Pet Stats
var nickname: String = "Desktop Pet" # Pet's name, shows in UI and as Window title
var move_speed = usable_rect.size.x * 0.0015 # Pet speed based on the size of the screen
var direction = Vector2(0, 0) # Direction of Pet Not Moving
var fullness: int = 100 # Pet's hunger, 100 = full
var happines: int = 100 # Pet's happiness, 100 = happy
var age: int = 0 # How old the pet is in minutes
var stage: int = 0 # How many evolution's the pet has undergone
var money: int = 0 # How much money the player/pet has
enum Types {BIRD, BUNNY, OCTOPUS} # Possible species that the pet can be
var type: Types = Types.BIRD # What species the pet is (bird set as default)
enum Activities {CLICKED, GREETING, IDLE, LIFTED, SITTING, SLEEPING, STARING, WALKING, WORKING} # Possible states for Pet
var activity:  Activities = Activities.IDLE # Current state of Pet (idle set as default)
enum Patterns {DEFAULT, UNCOMMON, RARE, EPIC, LEGENDARY} # Possible patterns the Pet can have
var pattern:  Patterns = Patterns.DEFAULT # Current pattern of Pet (starts as default)
enum Personality {NONE} # Possible personalities the Pet can have
var personality:  Personality = Personality.NONE # Current personality of Pet (starts as default)
var is_stopped: bool = false

# Game Variables
var decision_time: bool = false # Pet must wait Timer wait time before making their first decision
var save_time: bool = false # Game waits 10 seconds before saving using this bool
var fall_time: bool = true # Countdown to slowly increase fall speed to feel better
var screen_count: int = DisplayServer.get_screen_count() # How many monitors the player has
var gravity: bool = true # Gravity to keep Pet on taskbar, disabled when lifting
var OS_base_color: Color = DisplayServer.get_base_color() # Find the computer's chosen base colour
var OS_accent_color: Color = DisplayServer.get_accent_color() # Find the computer's chosen accent colour
var shader_on: bool = false # Whether the pet should use the distortion shade or not, changed in settings

# Bug-Testing 
var debugMovement = false
var debugScreen = true

## Notes:
## Use os theme colour to colour ui, tint b&w images
## One Click gets pets attention and stops them say hi, after too many clicks gets mad
## Hold Click on pet lets you drag them around
## Two Clicks on pet opens menu

# Check for inputs
func _input(event):
	# Check for Left Mouse Button Press
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not is_stopped:
			# start_stopping()
			pass


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
	
	# Sets the window and pet's size
	set_size()
	
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
	change_type("bird")
	
	# Sets the window name to the Pet's name
	window.set_title(nickname)
	
	# Run once at the start and then every time the sprite changes
	#_update_mouse_mask()
	#sprite.frame_changed.connect(_update_mouse_mask)
	
	# Changes test sprite to OS colour for testing (works)
	#$ColorTest.set_modulate(OS_accent_color)
	# Alert test (works)
	#OS.alert("I'm huuungryyyyy :(", "Alert!") 
	# Attention test (works)
	#DisplayServer.window_request_attention()
	
	# Framerate Cap
	Engine.max_fps = 30


func _process(_delta):
	# The Red Light!
	# If we are stopped then hit returm and stop reading code
	if is_stopped: return
	
	# Vector2i used to tell Windows to move to an exact pixel coordinate (integer)
	var move_vector = Vector2i(direction * move_speed) # How Pet will move around screen
	
	# Make decision about movement every timer end
	if decision_time == true:
		brain() # tells the brain to make a decision
	
	set_sprite() # changes the Pet's sprite to match what they're doing
	
	if activity == Activities.WALKING: # only if pet is moving
		move(move_vector) # moves the pet depending on the activity and type of the pet
	
	# Check edges to flip in case touching, sprite flip done in set_sprite()
	if window.position.x < 0:
		direction.x = 1 # Change Direction
		if debugMovement:
				print("Bounce off left")
	if window.position.x + window.size.x > usable_rect.size.x:
		direction.x = -1 # Change Direction
		if debugMovement:
				print("Bounce off right")
	
	# Check if pet is above taskbar to fall back down (if gravity is enabled)
	if gravity or (window.position.y != (taskbar_level - window.size.y)):
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
	
	# Check for settings
	if shader_on: # Shader by enekoassets at https://godotshaders.com/shader/random-displacement-animation-easy-ui-animation/
		$PetSprite.set_material(load("res://shaders/baba_shader_material.tres"))


# Makes it so you can click through invisible space in the window
func _update_mouse_mask():
	## list activities with no animation to save resources
	#if activity == Activities.IDLE or activity == Activities.SITTING:
		#return
	
	# 1. Get the raw image date of the current frame
	var texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	var image = texture.get_image()
	# If the sprite is visually flipped, flip the image too
	if sprite.flip_h:
		image.flip_x()
	
	# 2. Create the Bitmap (map of solid pixels)
	var bitmap = BitMap.new()
	bitmap.create_from_image_alpha(image)
	
	# 3. Create the Polygons (shape), 0.1 means ignore fully transparent pixels
	var polygons = bitmap.opaque_to_polygons(Rect2(Vector2.ZERO, texture.get_size()), 0.1)
	
	# 4. Apply it to the OS Window
	DisplayServer.window_set_mouse_passthrough(polygons)
	print("Cut!")


# Moves the window around the screen depending on state and type
func move(move_vector):
	var current_frame = $PetSprite.get_frame()
	
	# In-progress code to make the Bunny move differently to make the animation look smoother
	# Apply movement to OS Window depending on type
	if type == Types.BUNNY:
		if current_frame == 3 or current_frame == 4 or current_frame == 5:
			window.position.x += move_vector.x
		else:
			pass
	else:
		window.position.x += move_vector.x


# Sets the Pet's size to fit on the window correctly, increaseing at evolution
func set_size():
	var size_div = 13 # default for stage 0
	# Increase size with each stage
	match stage:
		1:
			size_div = 12
		2:
			size_div = 11
		3:
			size_div = 10
	
	# Calculates pet (window and sprite) size based on monitor size 
	var pet_size : int = (usable_rect.size.y / size_div) # size of the window in pixels
	var pet_scale = (pet_size/16.0) # scale for the sprite to fit in the window
	window.size = Vector2i(pet_size, pet_size)
	$PetSprite.scale = Vector2(pet_scale, pet_scale)
	if debugScreen:
		print("Pet Size: ", pet_size)
		print("Pet Scale: ", pet_scale)


# Sets the Pet's sprite/animation to match state
func set_sprite():
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


# Tells the Pet to stop when needed
func start_stopping():
	is_stopped = true
	activity = Activities.IDLE
	$PetSprite.set_modulate(OS_accent_color)
	
	# We COULD use a Timer node, but instead we can use 'await', which created a timer waits, and destroys it
	await get_tree().create_timer(3.0).timeout
	
	# Time's up!
	is_stopped = false
	set_modulate(Color(1.0, 1.0, 1.0, 1.0))


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


# Evolves the pet
func evolve():
	if stage < 3:
		stage += 1
		set_size()
	else:
		pass # finish game code here


# Saves the game's progress when called every 10 seconds, also increases age
var age_secs = 0 # counter to increase age at 60 seconds
func save() -> void:
	age_secs += 1
	if age_secs == 6:
		age += 1
		age_secs = 0
		
	# Saving code here
	print("Saved at ", age, ":", age_secs, "0")


# Used to increase speed slowly when pet is falling
func _on_fall_timer_timeout() -> void:
	fall_time = true
	print(window.position)
