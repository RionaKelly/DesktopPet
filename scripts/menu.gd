## This code handles everything for the menu window, primarily inputs

extends Window

# get access to the OS Window (not just the game node)
@onready var window : Window = get_window()

# Variables
var menu_scale: float = 1.0 # scale for the pet to resized with in set_size()
var shader_on: bool = false # Whether the pet should use the distortion shade or not, changed in settings
var held: bool = false
var grab_offset: Vector2 = Vector2.ZERO

#func _input(event):
	## Check for Left Mouse Button Press
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			##window.visible = false
		#
	#elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed == false:
			#pass


#func _ready() -> void:
	#window.visible = false
	### Window settings are set here as well as in the project just in case
	## We enable transparency for both the Godot Viewport and OS Window
	#window.transparent_bg = true
	#window.transparent = true
	## We remove the borders so it looks like the character is floating
	#window.borderless = true
	## Keep them above everything
	#window.always_on_top = true
	## Force borderless
	#window.unresizable = true

func _process(_delta):
	# Causes the window to follow the mouse cursor if the "handle" is held
	if held:
		var mouse_pos = $Default.get_global_mouse_position()
		window.position = Vector2(window.position) + mouse_pos - grab_offset
		## look into window_start_drag()


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


# Stops the following when button is let go
func _on_handle_button_up() -> void:
	held = false

# Shows the info page and hides default
func _on_info_pressed() -> void:
	$Default.hide()
	$Info.show()
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
