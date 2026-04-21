 // Original shader bases by ericalfaro, enekoassets, and MikeFozzy98
// https://godotshaders.com/shader/pixel-melt/
// https://godotshaders.com/shader/random-displacement-animation-easy-ui-animation/
// https://godotshaders.com/shader/color-replacer/

// I modified the code to:
// - Make them all work together
// - Make the vector shader toggleable
// - Make Evolution only modify cutout, don't move pixels, as I think it looks better

// This shader is used for the menu and only changes colours

shader_type canvas_item;

// Colour Changing
uniform bool change_color = false;
uniform bool change_line_color = false;
uniform bool make_transparent = false;
uniform vec4 primary_color : source_color;
uniform vec4 primary_replace_color : source_color;
uniform vec4 secondary_color : source_color;
uniform vec4 secondary_replace_color : source_color;
uniform vec4 line_color : source_color;
uniform vec4 line_replace_color : source_color;
uniform vec4 transparent_color : source_color;
uniform vec4 transparent_replace_color : source_color;
uniform float color_threshold : hint_range(0.0, 1.0, 0.001);

void fragment() {
	// Recolour Code Below
	if (change_color || make_transparent || change_line_color){
	// Called for every pixel the material is visible on.
	vec4 tex_color = texture(TEXTURE, UV);
	
	// Make white pixels transparent to hide pixels used for better hitboxes
	if(make_transparent){
		float transparent_distance = length(tex_color.rgb - transparent_color.rgb);
		
		if(transparent_distance < color_threshold){
			tex_color = transparent_replace_color;
		}
	}
	
	// Changes set colours to given colours
	if (change_color){	
		float primary_distance = length(tex_color.rgb - primary_color.rgb);
		float secondary_distance = length(tex_color.rgb - secondary_color.rgb);
		
		if(primary_distance < color_threshold){
			tex_color = primary_replace_color;
		}else if(secondary_distance < color_threshold){
			tex_color = secondary_replace_color;
		}
	}
	
	// Changes specifically the line colour for special cases
	if(change_line_color){
		float line_distance = length(tex_color.rgb - line_color.rgb);
		
		if(line_distance < color_threshold){
			tex_color = line_replace_color;
		}
	}
	
	COLOR = tex_color;
	}
}