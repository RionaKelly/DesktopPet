## Handles things for the thoughts window

extends Window

@onready var window : Window = get_window()

# Creates area of the window that can be clicked through
func _update_click_polygon():
	# 1. Creates the bitmap from hitbox image and resizes it to fit
	var image = Image.load_from_file("res://sprites/thoughts/thought_hitbox.png")
	var bitmap = BitMap.new()
	bitmap.create_from_image_alpha(image, 0.0)
	bitmap.resize(window.size)
	
	# 2. Create the Polygons (shape), 0.1 means ignore fully transparent pixels
	var polys = bitmap.opaque_to_polygons(Rect2(Vector2.ZERO, bitmap.get_size()), 1.0)
	var click_polygon = PackedVector2Array()
	for vec_i in range(polys.size()):		
		click_polygon.append_array(polys.get(vec_i))
	
	# 3. We set the PackedVector2Array as the passthrough area
	window.mouse_passthrough_polygon = click_polygon
