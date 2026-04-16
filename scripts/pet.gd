# Followed tutorial by Godot Dev Checkpoint to learn about windows with Godot
# Used this for window presets, making window around the screen, clicking through window, and performance enhancements
# https://youtube.com/playlist?list=PLVzjdZVCXNTyVHAtpgF_uFbsz8MA8uWKO&si=FOG2BfnqTqjJTduE

## TO DO - ASAP
# Pet Info display
# Game Info display
# Game settings menu
# Happiness and Fullness
# Work Mode
# Personality Traits affecting decisions
# Shop
# Games
## TO DO - AFTER
# Taking good care of your pet gives higher chance of rare patterns and personalities
# Waving/Getting attention animation
# Right click to pet Pet
# More actions for pet to do
# More complicated decionmaking with cooldowns and stuff
# Better Evolution Animation
# New game start with rarity boost

extends Node2D

# get access to the OS Window (not just the game node)
@onready var window : Window = get_window()
@onready var sprite : AnimatedSprite2D = $PetSprite

# The 'Safe Area' that the window shouldn't leave --- usable_rect() = screen area minus taskbar/docks
var usable_rect = DisplayServer.screen_get_usable_rect()
# var screen_size = DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
var taskbar_level = usable_rect.end.y

# Game Variables
var decision_time: bool = false # Pet must wait Timer wait time before making their first decision
var screen_count: int = DisplayServer.get_screen_count() # How many monitors the player has
var OS_base_color: Color = DisplayServer.get_base_color() # Find the computer's chosen base colour
var OS_accent_color: Color = DisplayServer.get_accent_color() # Find the computer's chosen accent colour
var grab_offset: Vector2 = Vector2.ZERO
var in_air: bool = false # if the pet is in the air or not
var out_of_bounds: int = 0 # counter for how long pet has been out of bounds

# Pet Variables
var move_speed = usable_rect.size.x * 0.0008 # Pet speed based on the size of the screen
var direction = Vector2(0, 0) # Direction that the pet will move in and is facing
var velocity = Vector2(0, 0) # Velocity of the pet while falling/being thrown
enum Activities {EVOLVING, FALLING, GRABBED, GREETING, IDLE, SITTING, SLEEPING, STARING, STOPPED, WALKING, WORKING} # Possible states for Pet
var activity:  Activities = Activities.IDLE # Current state of Pet (idle set as starting default)
enum Types {BIRD, BUNNY, OCTOPUS} # Possible species that the pet can be
enum Patterns {NONE, UNCOMMON, RARE, ULTRA_RARE} # Possible patterns the Pet can have
enum Personalities {NONE, AFFECTIONATE, ENERGETIC, SLEEPY} # Possible personalities the Pet can have
var pet_scale: float = 1.0 # Ccale for the pet to resized with in set_size()
var sad_count: int = 0 # Counter to keep track of how much happiness should be lost during update based on what has happened
var hungry_count: int = 0 # Counter to keep track of how much fullness should be lost during update based on what has happened
var work_mode: bool = false # When work mode is on, pet will not disturb player at all
var is_stopped: bool = false # bool to stop functions when pet is lifted
var is_evolving: bool = false # bool to play evolution animation and stop functions if pet is evolving
var ready_to_evolve: bool = false # Whether the pet is ready to evolve and should alert the player
var evolution_step: int = 1 # The current step of the evolution animation that the pet is on for tracking
var sprite_material: ShaderMaterial = load("res://shaders/pet_shader_material.tres")# The sprite's Shader Material

# Bug-Testing 
var debugMovement = false
var debugScreen = false
var debugInput = false

## Variables from here are loaded from save data (or set to default) using data.gd
# Pet Data
var nickname: String # Pet's name, shows in UI and as Window title
var fullness: int # Pet's hunger, 100 = full
var happiness: int # Pet's happiness, 100 = happy
var age: int # How old the pet is in minutes
var stage: int # How many evolution's the pet has undergone
var money: int # How much money the player/pet has
var type: Types = Types.BIRD # What species the pet is (default = Bird)
var pattern: Patterns = Patterns.NONE# Current pattern of Pet (default = None)
var personality: Personalities = Personalities.NONE # Current personality of Pet (default = None)

# Game Settings
var silent: bool = false # Whether the app should not send alerts as to bother less
var main_screen: int = DisplayServer.get_primary_screen() # Screen for pet to be confined to, will be changed later
var shader_on: bool = false # Whether the pet should use the distortion shade or not, changed in settings
var large_hitbox: bool = false # Whether the pet should keep the default window-size hitbox for accesibility
var saveGame: bool = true

# Check for inputs
func _input(event):
	# Check for Left Mouse Button Press and make pet stopped
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not is_stopped:
			start_stopping(true)
	
	# When LMB Press released un-stop pet and create a window if pet is on the taskbar
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed == false and is_stopped:
		if is_stopped:
			start_stopping(false)
		if window.position.y == taskbar_level - window.size.y:
			# If ready to evolve, begin evolution when clicked
			if ready_to_evolve and !in_air and !is_stopped:
				evolution_manager()
				return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
		
		# Display Menu
		$Menu.show()
		# The window will move over more to the left or right if the pet is too close to the edge to avoid being cut off
		var padding: int
		if window.position.x + window.size.x > ((usable_rect.size.x)*0.95) + usable_rect.position.x:
			padding = $Menu.size.x - window.size.x
		elif window.position.x < (usable_rect.size.x * 0.05) + usable_rect.position.x:
			padding = 0
		else:
			padding = $Menu.size.x/3
		$Menu.position = Vector2i(window.position.x - padding, window.position.y - $Menu.size.y * 1.05)


func _ready() -> void:
	# Sets up the Pet's variables if this is the first boot or data file can't be found
	nickname = Data.nickname
	fullness = Data.fullness
	happiness = Data.happiness
	age = Data.age
	stage = Data.stage
	money = Data.money
	type = Data.type as Types
	pattern = Data.pattern as Patterns
	personality = Data.personality as Personalities
	main_screen = Data.main_screen
	shader_on = Data.shader_on
	large_hitbox = Data.large_hitbox
	saveGame = Data.save_game
	
	# Prints to test issues with getting screen data
	if debugScreen:
		print("_Debug Info_")
		print("Window ID: ", window)
		print("Current Screen: ", window.current_screen)
		print("Primary Screen: ", DisplayServer.get_primary_screen())
		print("Screen Count: ", screen_count)
		print("Usable Rect: ", usable_rect)
		print("Operating System: ", DisplayServer.get_name())
		print("")
	
	# Apply Shader, done here so that set_type() can modify variables
	sprite.set_material(sprite_material)
	# Enable/disable wobbly shader based on saved data
	if shader_on:
		sprite_material.set_shader_parameter("baba_shader_on", true)
	elif !shader_on:
		sprite_material.set_shader_parameter("baba_shader_on", false)
	
	# Sets the window and pet's size
	set_size()
	# Sets the pet's appearance to match their type, either from save data or randomised in data.gd
	set_type() 
	set_pattern()
	
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
	# Disallow quit requests so we can handle them ourselves to make sure the game saves
	get_tree().set_auto_accept_quit(false)
	
	# Move the sprite to centre of the last screen at above the taskbar
	window.position = Vector2i(DisplayServer.screen_get_size(main_screen).x/2 - (window.size.x/2) + 
	DisplayServer.screen_get_position(main_screen).x, taskbar_level - window.size.y)
	if debugMovement:
		print("Starting Pet Position: ", window.position)
	# Resets the usable rect if the pet is not starting on the default screen
	if main_screen != DisplayServer.get_primary_screen():
		change_screen()
	# Places the Menu
	$Menu.position = Vector2i(window.position.x - $Menu.size.x/3, window.position.y - $Menu.size.y * 1.05)
	
	# Start the timers for pet decision and saving
	$DecisionTimer.start()
	
	# Sets the window name to the Pet's name
	window.set_title(nickname)
	
	# Run click area creation once here then whenever animation changes or it is called again
	_update_click_polygon()
	sprite.frame_changed.connect(_update_click_polygon)
	
	## Things I was testing to use later
	# Changes test sprite to OS colour for testing (works)
	#$ColorTest.set_modulate(OS_accent_color)
	# Alert test (works)
	#OS.alert("I'm hungry :(", "Alert!") 
	# Attention test (works)
	#DisplayServer.window_request_attention()
	# Test mouse_entered() window signal
	
	# Framerate Cap
	Engine.max_fps = 60
	
	# Finally, saves the game with the assigned data just in case
	save() 

var last_window_pos : Vector2 = Vector2.ZERO
func _process(_delta):
	# If Pet is Evolving then run evolution function and skip everything else
	if is_evolving:
		evolve()
		return
	# If Pet is Stopped then follow mouse position, track velocity, skip everything else
	if is_stopped:
		var mouse_pos = get_global_mouse_position()
		window.position = Vector2(window.position) + mouse_pos - grab_offset
		velocity = (velocity + (Vector2(window.position) - last_window_pos))/3
		if main_screen != window.current_screen:
			change_screen()
		if debugInput:
			print("Current Mouse Pos: ", mouse_pos)
			print("Velocity: ", velocity)
			print("")
		last_window_pos = window.position
		return
	
	# Vector2i used to tell Window to move to an exact pixel coordinate
	var move_vector = Vector2i(direction * move_speed) # How Pet will move around screen
	
	# Checks if pet is in the air for throwing physics
	if window.position.y < (taskbar_level - window.size.y):
		in_air = true
	else:
		in_air = false
	# Checks to make sure the pet is not out of bounds
	if window.position.x > 0 + usable_rect.position.x and window.position.x + window.size.x < usable_rect.size.x + usable_rect.position.x:
		out_of_bounds = 0
	
	# Make decision about movement every timer end
	if decision_time == true:
		brain() # tells the brain to make a decision
	
	if activity == Activities.WALKING: # only if pet is moving
		move(move_vector) # moves the pet depending on the activity and type of the pet
	
	# Check edges to flip and change direction if touching, sprite flip done in set_sprite()
	if window.position.x < 0 + usable_rect.position.x:
		direction.x = 1 # Change Direction
		if in_air and velocity.x < 0:
			velocity.x = velocity.x * -1
		_update_click_polygon(false)
		sprite.flip_h = false # This is done in set_sprite() too but I set here for instant change
		out_of_bounds += 1
		if debugMovement:
				print("Bounce off left")
	if window.position.x + window.size.x > usable_rect.size.x + usable_rect.position.x:
		direction.x = -1 # Change Direction
		if in_air and velocity.x > 0:
			velocity.x = velocity.x * -1
		_update_click_polygon(true)
		sprite.flip_h = true # This is done in set_sprite() too but I set here for instant change
		out_of_bounds += 1
		if debugMovement:
				print("Bounce off right")
	if window.position.y < 0 + usable_rect.position.y: # Mainly to check if pet is thrown agains the top
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
		if main_screen == window.current_screen:
			window.position = Vector2i(DisplayServer.screen_get_size(main_screen).x/2 - (window.size.x/2) + 
			DisplayServer.screen_get_position(main_screen).x, taskbar_level - window.size.y)
			print("Pet Position Reset to ", window.position)
		else:
			print("Pet Found on Screen ", window.current_screen)
			change_screen()
	
	# This is normally in update_stats() but is here for now for immediate testing
	if ((stage == 0 and age >= 300) or (stage == 1 and age >= 900) or (stage == 2 and age >= 1800)) and !ready_to_evolve:
		ready_to_evolve = true # Lets pet evolve when not busy
		request_attention()
		evolution_step = 1 # Resets the evolution step for playing animation
		print("Ready to evolve")
	
	# Check if the window's name is correct and set it if not
	if 	window.get_title() != nickname:
		window.set_title(nickname)


# Creates area of the window that can be clicked through
var last_activity = Activities.STOPPED # Random default that just needs to not be idle
func _update_click_polygon(flip = null):
	# 1. Stop function if it shouldn't be running
	# function shouldnt run if player needs larger hitboxes
	if large_hitbox:
		window.mouse_passthrough_polygon = []

		return
	# List activities with no animation to save resources
	if (activity == Activities.IDLE or activity == Activities.SITTING) and last_activity == activity:
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
		Activities.EVOLVING:
			current_animation = "idle"
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
	var size_div = 14 - stage # Ranged between 14 and 11
	
	# Calculates pet (window and sprite) size based on monitor size 
	var window_size = (usable_rect.size.y / size_div) # size of the window in pixels
	pet_scale = (window_size/16.0) # scale for the sprite to fit in the window
	window.size = Vector2i(window_size, window_size)
	sprite.scale = Vector2(pet_scale, pet_scale)
	
	# Sets the Menu window and object sizes
	$Menu.size = Vector2i(window_size * 3.125, window_size * 2.375) # multiplied by the difference in size compared to the pet
	if $Menu.visible:
		$Menu.position = Vector2i(window.position.x - $Menu.size.x/3, window.position.y - $Menu.size.y * 1.05)
	
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


# Changes Pet's sprite to match the set type
func set_type():
	match type:
		0: # Bird
			sprite.set_sprite_frames(load("res://sprite_frames/bird.tres"))
			sprite_material.set_shader_parameter("primary_color", Color(0.729, 0.243, 0.243, 1.0))
			sprite_material.set_shader_parameter("secondary_color", Color(0.984, 0.882, 0.345, 1.0))
		1: # Bunny
			sprite.set_sprite_frames(load("res://sprite_frames/bunny.tres"))
			sprite_material.set_shader_parameter("primary_color", Color(0.831, 0.616, 0.765, 1.0))
			sprite_material.set_shader_parameter("secondary_color", Color(0.867, 0.549, 0.616, 1.0))
		2: # Octopus
			sprite.set_sprite_frames(load("res://sprite_frames/octopus.tres"))
			sprite_material.set_shader_parameter("primary_color", Color(0.447, 0.576, 0.749, 1.0))
			sprite_material.set_shader_parameter("secondary_color", Color(0.604, 0.482, 0.769, 1.0))
		# Backup to choos a random pet and run function again if no valid type is found
		_:
			print("Type Invalid, Sprite Randomised")
			match randi_range(0, 2):
				0:
					type = Types.BIRD
					set_type()
				1:
					type = Types.BUNNY
					set_type()
				2:
					type = Types.OCTOPUS
					set_type()
	# Prints the selected pet in an easily readable format
	print ("Pet: ", (Types.keys()[type]).capitalize())


# Changes the Pet's sprite's pattern to match the set pattern
func set_pattern():
	# Exit function if the pet has no pattern
	if pattern == 0: # None
		sprite_material.set_shader_parameter("change_color", false)
		return
	sprite_material.set_shader_parameter("change_color", true)
	
	var first_color: Color
	var second_color: Color
	match pattern:
		1: # Uncommon
			match type:
				0: # Bird
					first_color = Color(0.914, 0.451, 0.62, 1.0)
					second_color = Color(0.984, 0.773, 0.259, 1.0)
				1: # Bunny
					first_color = Color(0.918, 0.612, 0.486, 1.0)
					second_color = Color(0.929, 0.545, 0.69, 1.0)
				2: # Octopus
					first_color = Color(0.404, 0.675, 0.686, 1.0)
					second_color = Color(0.757, 0.518, 0.682, 1.0)
		2: # Rare
			match type:
				0: # Bird
					first_color = Color(0.317, 0.682, 0.769, 1.0)
					second_color = Color(0.986, 0.742, 0.489, 1.0)
				1: # Bunny
					first_color = Color(0.867, 0.851, 0.847, 1.0)
					second_color = Color(0.863, 0.745, 0.745, 1.0)
				2: # Octopus
					first_color = Color(0.973, 0.671, 0.392, 1.0)
					second_color = Color(0.961, 0.49, 0.365, 1.0)
		3: # Ultra Rare
			match type:
				0: # Bird
					first_color = Color(0.333, 0.302, 0.384, 1.0)
					second_color = Color(0.98, 0.482, 0.329, 1.0)
				1: # Bunny
					first_color = Color(0.427, 0.737, 0.427, 0.882)
					second_color = Color(0.624, 0.733, 0.463, 0.882)
				2: # Octopus
					first_color = Color(0.897, 0.879, 0.885, 1.0)
					second_color = Color(0.307, 0.29, 0.289, 1.0)
		# Backup print if pattern is invalid
		_:
			print("Pattern Invalid")

		
	# Applies the colour given
	sprite_material.set_shader_parameter("primary_replace_color", first_color)
	sprite_material.set_shader_parameter("secondary_replace_color", second_color)
	# Prints the applied pattern in an easily readable format
	print ("Applied Pattern: ", (Patterns.keys()[pattern]).capitalize())

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
			elif rand_choice < 0.65 and window.position.x + window.size.x < ((usable_rect.size.x)*0.9) + usable_rect.position.x:
				activity = Activities.WALKING
				direction.x = 1
				if debugMovement:
					print("Turn Right")
			elif window.position.x > (usable_rect.size.x * 0.1) + usable_rect.position.x:
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
					print("Activity Not Found")
	
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



# Recalculates the Pet's usable screen area when called, normally for when screen the Pet is on changes
func change_screen():
	main_screen = window.current_screen
	usable_rect = DisplayServer.screen_get_usable_rect()
	taskbar_level = usable_rect.end.y
	print("Main Screen Changed to ", main_screen)


# Called every minute to update the Pet's stats (age, fullness, happiness, etc.), also calls save()
func update_stats():
	# Increases the pet's age by 1 every 60 seconds
	age += 1 
	
	## Check if the pet is old enough to begin evolution (after 5, 15, and 30 hours)
	#if (stage == 0 and age >= 300) or (stage == 1 and age >= 900) or (stage == 2 and age >= 1800):
		#ready_to_evolve = true # Lets pet evolve when not busy
		#evolution_step = 0 # Resets the evolution step for playing animation
	#else:
		#ready_to_evolve = false


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
			if !ready_to_evolve: # Don't change animation when ready to evolve to let evolution animation play better
				activity = Activities.SITTING
			brain()
		else:
			activity = Activities.FALLING


# Starts the Evolution process for the Pet
func evolution_manager():
	# Begin animation
	match evolution_step:
		1:
			print("Evolving from Stage ", stage, " to ", stage + 1, "...")
			is_evolving = true
			$DecisionTimer.stop()
			activity = Activities.EVOLVING
		2: 
			# Increase stage and set new size
			stage += 1
			set_size()
			_update_click_polygon()
			window.position = Vector2i(window.position.x, taskbar_level - window.size.y)
			
			# Randomise whether pet should gain a trait (new personality or pattern)
			var rand_trait = randf()
			var rand_choice = randf()
			var new_trait = 0 # 0 means no new trait, 1 means pattern, 2 means personality
			# For now you are guaranteed to gain a new personality or pattern, chances will be changed in the future
			if rand_trait < 0.5: 
				if pattern == Patterns.NONE: # These checks make sure player doesnt already have a trait of this type
					new_trait = 1
				elif personality == Personalities.NONE:
					new_trait = 2
			elif rand_trait < 1.0:
				if personality == Personalities.NONE:
					new_trait = 2
				elif pattern == Patterns.NONE:
					new_trait = 1
			
			match new_trait:
				1: # 6 : 3.5 : 0.5
					if rand_choice < 0.6:
						pattern = Patterns.UNCOMMON
					elif rand_choice < 0.95:
						pattern = Patterns.RARE
					else:
						pattern = Patterns.ULTRA_RARE
					print ("New Pattern: ", (Patterns.keys()[pattern]).capitalize())
					set_pattern()
				2: # 4 : 3 : 3
					if rand_choice < 0.4:
						personality = Personalities.AFFECTIONATE
					elif rand_choice < 0.7:
						personality = Personalities.ENERGETIC
					else:
						personality = Personalities.SLEEPY
					print ("New Personality: ", (Personalities.keys()[personality]).capitalize())
				_:
					print ("No New Traits, Code: ", new_trait)
					print ("Current Traits: ",(Patterns.keys()[pattern]).capitalize(), 
					" & ", (Personalities.keys()[personality]).capitalize())
		3:
			# Reset pet and continue decision-making after 3 seconds
			ready_to_evolve = false
			sprite_material.set_shader_parameter("progress", 0.0) # reset just in case for future animations
			activity = Activities.IDLE
			set_sprite()
			$DecisionTimer.start(3.0)
			is_evolving = false


# Manages the animation and real_time process for the Pet's Evolution
func evolve():
	# The current progress of the shader between 0 and 1, 1 being complete with the pet invisible
	var shader_progress: float = sprite_material.get_shader_parameter("progress")
	match evolution_step:
		1: # First slowly increase shader progress to make pet disappear
			if shader_progress <= 1:
				shader_progress += 0.01
		2: # Them slowly decrease shader progress to make pet reappear after changes
			if shader_progress >= 0 :
				shader_progress -= 0.01
	
	# Check to start stage 2
	if shader_progress >= 1 and evolution_step == 1:
		evolution_step = 2
		evolution_manager()
	if shader_progress <= 0 and evolution_step == 2:
		evolution_step = 3
		evolution_manager()
	
	# Sets the shader to the correct progress for playing animation and prints information for testing
	sprite_material.set_shader_parameter("progress", shader_progress)

# Saves the game's progress when called
func save() -> void:
	# Don't save anything if enabled, usually left on for testing
	if saveGame == false:
		print("Game not saved")
		return
	
	# Creates the new config file 
	var config := ConfigFile.new()
	# Writes the Pet's data
	config.set_value("pet", "nickname", nickname)
	config.set_value("pet", "fullness", fullness)
	config.set_value("pet", "happiness", happiness)
	config.set_value("pet", "age", age)
	config.set_value("pet", "stage", stage)
	config.set_value("pet", "money", money)
	config.set_value("pet", "type", type)
	config.set_value("pet", "pattern", pattern)
	config.set_value("pet", "personality", personality)
	# Writes the Settings data
	config.set_value("settings", "silent", silent)
	config.set_value("settings", "main_screen", main_screen)
	config.set_value("settings", "shader_on", shader_on)
	config.set_value("settings", "large_hitbox", large_hitbox)
	config.set_value("settings", "save_game", saveGame)
	
	# Saves the data as a config file
	var error_code: = config.save("user://data.cfg")
	# Print just to know that saving is complete with no issues
	if error_code == OK:
		print("Saved at ", age/60, ":" , age % 60, ":", str(snapped(60 - $UpdateTimer.get_time_left(), 1)).pad_zeros(2))
	# Prints error code if there was an issue during saving
	else:
		print("Saving failed with Error: ", error_code)


# Exits the game after saving when called
func exit() -> void:
	print("Saving...")
	save()
	print("Exitting Game... See you next time!")
	get_tree().quit() # default behavior


# If the player attempts to close the app manually, this lets it use my exit function instead to save progress
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("Exit Request Recieved")
		exit()


# Checks if attention should be requested every 5 seconds
func request_attention() -> void:
	# Check if Pet should be quiet
	if silent or work_mode:
		# Put quieter attention request code here
		return
	# Request attention if pet is ready to evolve
	if ready_to_evolve:
		DisplayServer.window_request_attention()
