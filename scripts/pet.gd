# Followed tutorial by Godot Dev Checkpoint to learn about windows with Godot
# Used this for window presets, making window around the screen, clicking through window, and performance enhancements
# https://youtube.com/playlist?list=PLVzjdZVCXNTyVHAtpgF_uFbsz8MA8uWKO&si=FOG2BfnqTqjJTduE

##TO DO:

extends Node2D

# get access to the OS Window (not just the game node)
@onready var window : Window = get_window()

@onready var sprite : AnimatedSprite2D = $PetSprite

# @onready var _ClickPolygon: CollisionPolygon2D = $PetSprite/ClickArea/ClickPolygon

# The 'Safe Area' that the window shouldn't leave --- usable_rect() = screen area minus taskbar/docks
var usable_rect = DisplayServer.screen_get_usable_rect()
# var screen_size = DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
var taskbar_level = usable_rect.end.y

# Pet Stats
var nickname: String = "Desktop Pet" # Pet's name, shows in UI and as Window title
var move_speed = usable_rect.size.x * 0.0008 # Pet speed based on the size of the screen
var direction = Vector2(0, 0) # Direction that the pet will move in and is facing
var velocity = Vector2(0, 0) # Velocity of the pet while falling/being thrown
var fullness: int = 100 # Pet's hunger, 100 = full
var happines: int = 100 # Pet's happiness, 100 = happy
var age: int = 0 # How old the pet is in minutes
var stage: int = 0 # How many evolution's the pet has undergone
var money: int = 0 # How much money the player/pet has
enum Types {BIRD, BUNNY, OCTOPUS} # Possible species that the pet can be
var type: Types = Types.BIRD # What species the pet is (bird set as default)
enum Activities {FALLING, GRABBED, GREETING, IDLE, SITTING, SLEEPING, STARING, STOPPED, WALKING, WORKING} # Possible states for Pet
var activity:  Activities = Activities.IDLE # Current state of Pet (idle set as starting default)
enum Patterns {DEFAULT, UNCOMMON, RARE, EPIC, LEGENDARY} # Possible patterns the Pet can have
var pattern:  Patterns = Patterns.DEFAULT # Current pattern of Pet (starts as default)
enum Personality {NONE} # Possible personalities the Pet can have
var personality:  Personality = Personality.NONE # Current personality of Pet (starts as default)
var pet_scale: float = 1.0 # scale for the pet to resized with in set_size()

# Game Variables
var decision_time: bool = false # Pet must wait Timer wait time before making their first decision
var save_time: bool = false # Game waits 10 seconds before saving using this bool
var screen_count: int = DisplayServer.get_screen_count() # How many monitors the player has
var OS_base_color: Color = DisplayServer.get_base_color() # Find the computer's chosen base colour
var OS_accent_color: Color = DisplayServer.get_accent_color() # Find the computer's chosen accent colour
var grab_offset: Vector2 = Vector2.ZERO
var in_air: bool = false # if the pet is in the air or not
var is_stopped: bool = false # bool to stop functions when pet is lifted
var out_of_bounds: int = 0 # counter for how long pet has been out of bounds
var shader_on: bool = false # Whether the pet should use the distortion shade or not, changed in settings

# Bug-Testing 
var debugMovement = true
var debugScreen = true
var debugInput = false

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
			start_stopping(true)
		
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed == false and is_stopped:
		if is_stopped:
			start_stopping(false)
			if window.position.y == taskbar_level - window.size.y:
				$Menu.visible = true
				$Menu.position = Vector2i(window.position.x, window.position.y - $Menu.size.y)


func _ready() -> void:
	# Prints to test issues with getting screen data
	if debugScreen:
		print("_Debug Info_")
		print("Window ID: ", window)
		print("Current Screen: ", window.current_screen)
		print("Primary Screen: ", DisplayServer.get_primary_screen())
		print("Screen Count: ", screen_count)
		print("Usable Rect: ", usable_rect)
		print("Taskbar Level: ", taskbar_level) 
		print("Operating System: ", DisplayServer.get_name())
		print("")
	
	# Sets the window and pet's size
	set_size()
	# get_viewport().size_changed.connect(set_size()) # signal to change size when window resized
	
	## Window settings are set here as well as in the project just in case
	# We enable transparency for both the Godot Viewport and OS Window
	window.transparent_bg = true
	window.transparent = true
	# We remove the borders so it looks like the character is floating
	window.borderless = true
	# Keep them above everything
	window.always_on_top = true
	# Force borderless
	window.unresizable = true
	
	# Move the sprite to centre of the screen at above the taskbar
	window.position = Vector2i(DisplayServer.screen_get_size().x/2 - (window.size.x/2), taskbar_level - window.size.y)
	print("Starting Pet Position: ", window.position)
	
	
	
	# Start the timer for pet decision
	$DecisionTimer.start()
	
	# Call the function to decide random or specific starting pet, and prints the result
	change_type("random") # set as random when exporting
	
	# Sets the window name to the Pet's name
	window.set_title(nickname)
	
	# Run once here then whenever animation changes
	_update_click_polygon()
	sprite.frame_changed.connect(_update_click_polygon)
	
	## Things I was testing to use later
	# Changes test sprite to OS colour for testing (works)
	#$ColorTest.set_modulate(OS_accent_color)
	# Alert test (works)
	#OS.alert("I'm huuungryyyyy :(", "Alert!") 
	# Attention test (works)
	#DisplayServer.window_request_attention()
	
	# Framerate Cap
	Engine.max_fps = 60

var last_window_pos : Vector2 = Vector2.ZERO
func _process(_delta):
	# If we are stopped then return and stop reading code
	if is_stopped: 
		var mouse_pos = get_global_mouse_position()
		window.position = Vector2(window.position) + mouse_pos - grab_offset
		velocity = (velocity + (Vector2(window.position) - last_window_pos))/3
		if debugInput:
			print("Current Mouse Pos: ", mouse_pos)
			print("Velocity: ", velocity)
			print("")
		last_window_pos = window.position
		return

	# Vector2i used to tell Windows to move to an exact pixel coordinate (integer)
	var move_vector = Vector2i(direction * move_speed) # How Pet will move around screen
	
	if window.position.y < (taskbar_level - window.size.y):
		in_air = true
	else:
		in_air = false
	if window.position.x > 0 and window.position.x + window.size.x < usable_rect.size.x:
		out_of_bounds = 0
	
	# Make decision about movement every timer end
	if decision_time == true:
		brain() # tells the brain to make a decision
	
	if activity == Activities.WALKING: # only if pet is moving
		move(move_vector) # moves the pet depending on the activity and type of the pet
	
	# Check edges to flip and change direction if touching, sprite flip done in set_sprite()
	if window.position.x < 0:
		direction.x = 1 # Change Direction
		if in_air and velocity.x < 0:
			velocity.x = velocity.x * -1
		_update_click_polygon(false)
		sprite.flip_h = false # This is done in set_sprite() too but I set here for instant change
		out_of_bounds += 1
		if debugMovement:
				print("Bounce off left")
	if window.position.x + window.size.x > usable_rect.size.x:
		direction.x = -1 # Change Direction
		if in_air and velocity.x > 0:
			velocity.x = velocity.x * -1
		_update_click_polygon(true)
		sprite.flip_h = true # This is done in set_sprite() too but I set here for instant change
		out_of_bounds += 1
		if debugMovement:
				print("Bounce off right")
	if window.position.y < 0: # Mainly to check if pet is thrown agains the top
		if direction.y < 0:
			direction.y = 0
		if velocity.y < 0:
			velocity.y = velocity.y * -1
		if debugMovement:
				print("Bounce off top")
	
	# Check if pet is above taskbar to fall back down
	if in_air:
		velocity.y += 0.3 # increase fall speed slowly while falling
		velocity = velocity * .99
		if velocity.x > 0:
			velocity.x -= 0.2
		elif velocity.x < 0:
			velocity.x += 0.2
		velocity = Vector2(snapped(velocity.x, 0.001), snapped(velocity.y, 0.001))
		window.position += Vector2i(velocity * move_speed)
		if debugMovement:
			print("Falling with velocity ", velocity)
	elif window.position.y > (taskbar_level - window.size.y):
		if debugMovement:
			print("Reached Floor with velocity ", velocity)
		window.position.y = (taskbar_level - window.size.y)
		velocity = Vector2.ZERO # reset fall speed upon reaching ground
	else:
		velocity = Vector2.ZERO # reset fall speed upon reaching ground
		if activity == Activities.FALLING:
			activity = Activities.SITTING
			brain()
	
	# If pet is out of bounds for 60 frames, reset position
	if out_of_bounds >= 60:
		out_of_bounds = 0
		window.position = Vector2i(DisplayServer.screen_get_size().x/2 - (window.size.x/2), taskbar_level - window.size.y)
		print("Pet Position Reset to ", window.position)
	
	# Check for settings
	# Shader by enekoassets at https://godotshaders.com/shader/random-displacement-animation-easy-ui-animation/
	if shader_on:
		sprite.set_material(load("res://shaders/baba_shader_material.tres"))


# Creates area of the window that can be clicked through
var last_activity = Activities.STOPPED # Random default that just needs to not be idle
func _update_click_polygon(flip = null):
	# 1. Stop function if it shouldn't be running
	# list activities with no animation to save resources
	if activity == Activities.IDLE or activity == Activities.SITTING:
		if last_activity == activity: 
			return
	last_activity = activity
	
	# 2. Find the current frame and animation to be used for getting the right image
	var current_frame : int = 0
	var current_animation : String = ""
	match activity:
		Activities.IDLE:
			current_animation = "idle"
		Activities.SITTING:
			current_animation = "sit"
		Activities.WALKING:
			current_animation = "walk"
			current_frame = sprite.frame
		_:
			current_animation = "idle" # default to match sprite if no animation is found
	if current_frame >= sprite.sprite_frames.get_frame_count(current_animation):
		current_frame = 0
	
	# 3. Get the raw image date of the frame and size/flip accordingly
	var current_sprite : Texture2D = sprite.sprite_frames.get_frame_texture(current_animation, current_frame)
	var image = current_sprite.get_image()
	image.resize((ceil(image.get_size().x * pet_scale) * 1.0), (ceil(image.get_size().y * pet_scale) * 1.0), 
	Image.Interpolation.INTERPOLATE_NEAREST)
	if flip == true or sprite.flip_h == true: # flips the polygon if the sprite is flipped
		image.flip_x()
	
	# 4. Create the Bitmap (map of solid pixels) from image
	var bitmap = BitMap.new()
	bitmap.create_from_image_alpha(image, 0.0)
	
	# 5. Create the Polygons (shape), 0.1 means ignore fully transparent pixels
	var polys = bitmap.opaque_to_polygons(Rect2(Vector2.ZERO, bitmap.get_size()), 1.0)
	var click_polygon = PackedVector2Array()
	for vec_i in range(polys.size()):		
		click_polygon.append_array(polys.get(vec_i))
	
	# 6. We set the PackedVector2Array as the passthrough area
	window.mouse_passthrough_polygon = click_polygon
	#print("Clickable Area: ", window.get_mouse_passthrough_polygon())


# Moves the window around the screen depending on state and type, typically when walking
func move(move_vector):
	var current_frame = sprite.get_frame()
	
	# Apply movement to OS Window depending on pet type
	if type == Types.BUNNY: 	# Makes the Bunny move differently to look better
		if current_frame == 3 or current_frame == 4 or current_frame == 5:
			window.position.x += move_vector.x
		else:
			pass
	else:
		window.position.x += move_vector.x

# Sets the Pet's size to fit on the window correctly, increasing at evolution
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
	var window_size = (usable_rect.size.y / size_div) # size of the window in pixels
	pet_scale = (window_size/16.0) # scale for the sprite to fit in the window
	window.size = Vector2i(window_size, window_size)
	sprite.scale = Vector2(pet_scale, pet_scale)
	
	# Sets the Menu window and object sizes
	$Menu.size = Vector2i(window_size * 3, window_size * 2)

	
	if debugScreen:
		print("Window Size: ", window_size)
		print("Pet Scale: ", pet_scale)


# Sets the Pet's sprite/animation to match state
func set_sprite():
	# Makes pet face the right direction and play the right animation after moving/stopping
	match activity:
		Activities.IDLE:
			_update_click_polygon()
			sprite.play("idle")
			#if direction.x != 0: # This should happen anyway but I check here just in case
				#direction.x = 0 
		Activities.SITTING:
			_update_click_polygon()
			sprite.play("sit")
		Activities.WALKING:
			if direction.x == 1:
				_update_click_polygon(false)
				sprite.flip_h = false
			elif direction.x == -1:
				_update_click_polygon(true)
				sprite.flip_h = true
			else: # extra check just in case direction variable is doing something weird
				print("Direction [", direction.x, "] outside of given rage")
			sprite.play("walk")
		_:
			print("Activity [", activity, "] not recognised")
			_update_click_polygon()
			sprite.play("idle") # default animation for if there is none ready


# Handles all of the decision making for the Pet
func brain():
	# Randomise decision & time
	var rand_choice = randf()
	var rand_wait = 1.2 # Temporary wait time while establishing variable
	
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
	
	set_sprite() # changes the Pet's sprite to match what they're doing


# Tells the Pet to stop
func start_stopping(stop):
	if stop: # stops events and s
		is_stopped = true
		#gravity = false
		grab_offset = get_global_mouse_position()
		activity = Activities.STOPPED
		set_sprite()
		#sprite.set_self_modulate(OS_accent_color)
		#sprite.set_speed_scale(0.0)
		$DecisionTimer.stop()
		print("Pet Stopped")
	
	else:
		print("Pet Continuing")
		#gravity = true
		grab_offset = Vector2.ZERO
		is_stopped = false
		#sprite.set_self_modulate(Color(1.0, 1.0, 1.0))
		#sprite.set_speed_scale(1.0)
		if window.position.y == taskbar_level - window.size.y:
			activity = Activities.SITTING
			brain()
		else:
			activity = Activities.FALLING


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


# Exits the game after saving when called
func exit() -> void:
	print("Saving...")
	save()
	print("Exitting Game")
	get_tree().quit() # default behavior


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		exit()
