 // Original shader bases by ericalfaro, enekoassets, and MikeFozzy98
// https://godotshaders.com/shader/pixel-melt/
// https://godotshaders.com/shader/random-displacement-animation-easy-ui-animation/
// https://godotshaders.com/shader/color-replacer/

// I modified the code to:
// - Make them all work together
// - Make the vector shader toggleable
// - Make Evolution only modify cutout, don't move pixels, as I think it looks better

// This shader is used for everything that isnt the pet or the menu, just to change line colour

shader_type canvas_item;

// Colour Changing
uniform bool change_line_color = false;
uniform vec4 line_color : source_color;
uniform vec4 line_replace_color : source_color;
uniform float color_threshold : hint_range(0.0, 1.0, 0.001);

void fragment() {
	// Recolour Code Below
	if (change_line_color){
	// Called for every pixel the material is visible on.
	vec4 tex_color = texture(TEXTURE, UV);
	
	// Changes specifically the line colour for special cases
	float line_distance = length(tex_color.rgb - line_color.rgb);
		
	if(line_distance < color_threshold){
		tex_color = line_replace_color;
	}
	
	
	COLOR = tex_color;
	}
}