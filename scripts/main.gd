#Followed tutorial by Godot Dev Checkpoint to learn about making the Windows function for this game
extends Node2D

var move_speed = 8
var direction = Vector2(1, 0) # Moving Right

func _ready() -> void:
	#get access to the OS Window (not just the game node)
	var window = get_window()
	
	# We enable transparency for both the Godot Viewport and OS Window
	get_viewport().transparent_bg = true
	window.transparent = true

	# We remove the borders so it looks like the character is floating
	window.borderless = true
	
	# Keep them above everything
	window.always_on_top = true
	
	# Force Windows to let us be borderless
	window.unresizable = false
	
	# Find the floor
	# 1. Get the safe area of screen
	var usable_rect = DisplayServer.screen_get_usable_rect()
	# 2. Calculate the floor position
	# end.y is pixel coordinate where the taskbar starts
	var target_y = usable_rect.end.y - window.size.y
	# 3. Move the sprite there
	# x = 0 (left edge), y = target_y (the floor)
	window.position = Vector2i(0, target_y)
	
func _process(_delta):
	var window = get_window()
	
	# Vector2i used to tell Windows to move to an exact pixel coordinate (integer) 
	#Calculate the move
	var move_vector = Vector2i(direction * move_speed)
	# Apply to OS Window
	window.position += move_vector
	
	# The Safe Area
	# screen_get_usable_rect() returns screen area minus taskbar/docks
	var usable_rect = DisplayServer.screen_get_usable_rect()
	
	# Check right edge to flip
	if window.position.x + window.size.x > usable_rect.end.x:
		direction.x = -1 # Walk left instead
		$AnimatedSprite2D.flip_h = true # Flip sprite
	
	# Check right edge to flip
	elif window.position.x < usable_rect.position.x:
		direction.x = 1 # Walk right instead
		$AnimatedSprite2D.flip_h = false # Unflip sprite
