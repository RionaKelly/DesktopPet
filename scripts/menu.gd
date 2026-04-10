extends Window

# get access to the OS Window (not just the game node)
@onready var window : Window = get_window()

# Variables
var menu_scale: float = 1.0 # scale for the pet to resized with in set_size()
var shader_on: bool = false # Whether the pet should use the distortion shade or not, changed in settings

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


#func _process(_delta):
	#pass





func _on_close_pressed():
	window.visible = false
