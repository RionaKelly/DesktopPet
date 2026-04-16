## This code handles everything for the menu window, primarily inputs

extends Window

# get access to the OS Window (not just the game node)
@onready var window : Window = get_window()

# Variables
var menu_scale: float = 1.0 # scale for the pet to resized with in set_size()
var shader_on: bool = false # Whether the pet should use the distortion shade or not, changed in settings
var held: bool = false
var grab_offset: Vector2 = Vector2.ZERO
var system: String = OS.get_name()
var version: String = OS.get_version_alias()
var windows10: bool = false

#func _input(event):
	## Check for Left Mouse Button Press
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			##window.visible = false
		#
	#elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed == false:
			#pass


func _ready() -> void:
	# Set checkboxes to how they should look
	if Data.save_game:
		$Settings/Saving.button_pressed = true
	if Data.silent:
		$Settings/Silent.button_pressed = true
	if Data.large_hitbox:
		$Settings/Hitbox.button_pressed = true
	if Data.shader_on:
		$Settings/Shader.button_pressed = true
	if Data.open_menu:
		$Settings/Menu.button_pressed = true
	print(system, " version ", version)
	if system == "Windows" and version[1] == "0" :
		windows10 = true
		print("Windows 10 Dragging set up")
	


func _process(_delta):
	# Causes the window to follow the mouse cursor if the "handle" is held
	var new_pos: Vector2i
	if  held:
		# Check if the player is using Windows 10 to execute code differently as there were issues on that version
		if windows10:
				new_pos = Vector2i($"..".get_global_mouse_position()) + Vector2i($"..".window.position) - Vector2i(grab_offset)
				window.position = new_pos
				print("M: ", Vector2i($"..".get_global_mouse_position()), "W: ", Vector2i($"..".window.position), "G: ", grab_offset, "S: ", window.size.x)
				## look into window_start_drag()
		else: # Regular dragging setup for otherwise
				new_pos = Vector2(window.position) + $Default.get_global_mouse_position() - grab_offset
				print("M: ", Vector2i($Default.get_global_mouse_position()), "W: ", Vector2i(window.position), "G: ", grab_offset, "S: ", window.size.x)
		window.position = new_pos

# Hides the Window when the top left Close is pressed
func _on_close_pressed():
	window.hide()
	_on_back_pressed()


# Tells the main script to close the game when Exit is pressed
func _on_exit_pressed():
	$"..".exit()


# Hides the window when a player tries to close the window manually
func _on_close_requested():
	window.hide()


# Makes the window follow the user when they grab the "handle" at the top
func _on_handle_button_down() -> void:
	held = true
	grab_offset = $Default.get_global_mouse_position()
	# I have no idea why this offset needs to be multiplied by 2.16 but it is incorrect without it
	if windows10:
		grab_offset = grab_offset/2.16


# Stops the following when button is let go
func _on_handle_button_up() -> void:
	held = false

# Shows the info page and hides default
func _on_info_pressed() -> void:
	$Default.hide()
	$Info.show()
	$Back.show()


# Shows the settings page and hides default
func _on_settings_pressed():
	$Default.hide()
	$Settings.show()
	$Back.show()


# Brings you back to the default page
func _on_back_pressed() -> void:
	$Default.show()
	$Pet.hide()
	$Shop.hide()
	$Game.hide()
	$Info.hide()
	$Settings.hide()
	$Back.hide()


func _on_pet_pressed() -> void:
	# Update information about pet
	$"Pet/Pet Info".set_text(String("Name: " + $"..".nickname + 
	"\nAge: " + str($"..".age) + 
	"\nHappiness: " + str($"..".happiness) + "%" +
	"\nFullness: " + str($"..".fullness) + "%" +
	"\nMoney: " + str($"..".money) +
	"\nType: " + ($"..".Types.keys()[$"..".type]).capitalize() +
	"\nPattern: " + ($"..".Patterns.keys()[$"..".pattern]).capitalize() +
	"\nPersonality: " + ($"..".Personalities.keys()[$"..".personality]).capitalize()
	))
	
	$Default.hide()
	$Pet.show()
	$Back.show()


# Changes the pet's nickname when text is enterred
func _on_name_entry_text_submitted(new_name: String) -> void:
	$"..".nickname = new_name


# These four functions toggle settings in the main scene
func _on_saving_toggled(toggled_on):
	if toggled_on:
		$"..".saveGame = true
		print("Saving On")
	else:
		$"..".saveGame = false
		print("Saving Off")
func _on_silent_toggled(toggled_on):
	if toggled_on:
		$"..".silent = true
		print("Silent On")
	else:
		$"..".silent = false
		print("Silent Off")
func _on_hitbox_toggled(toggled_on):
	if toggled_on:
		$"..".large_hitbox = true
		print("Larger Hitbox On")
	else:
		$"..".large_hitbox = false
		print("Larger Hitbox Off")
func _on_shader_toggled(toggled_on):
	if toggled_on:
		$"..".shader_on = true
		$"..".sprite_material.set_shader_parameter("baba_shader_on", true)
		print("Shader On")
	else:
		$"..".shader_on = false
		$"..".sprite_material.set_shader_parameter("baba_shader_on", false)
		print("Shader Off")
func _on_menu_toggled(toggled_on: bool) -> void:
	if toggled_on:
		$"..".open_menu = true
		print("Open Menu On")
	else:
		$"..".open_menu = false
		print("Open Menu Off")


# Deletes the current data for the pet, saving must also be turned off if player wants to restart next boot
func _on_delete_pressed():
	var config := ConfigFile.new()
	if config.load("user://data.cfg") != OK: # Load file and check if it is loaded ok
		print("No data found to delete")
	config.clear()
	config.save("user://data.cfg")
	print("Save Data Deleted")
