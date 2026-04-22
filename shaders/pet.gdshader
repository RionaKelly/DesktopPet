 // Original shader bases by ericalfaro, enekoassets, and MikeFozzy98
// https://godotshaders.com/shader/pixel-melt/
// https://godotshaders.com/shader/random-displacement-animation-easy-ui-animation/
// https://godotshaders.com/shader/color-replacer/

// I modified the code to:
// - Make them all work together
// - Make the vector shader toggleable
// - Make Evolution only modify cutout, don't move pixels, as I think it looks better

// This shader is used for the pet and manages colour changing, the evolution animation, and vector wobbling

shader_type canvas_item;

// Animate from 0 to 1
uniform float progress: hint_range(0.0, 1.0) = 0.0;

// How jagged each band of melting pixels are
uniform float meltiness: hint_range(0.0, 16.0) = 1.0;

// Colour Changing
uniform bool change_color = false;
uniform bool change_line_color = false;
uniform bool make_transparent = true;
uniform vec4 primary_color : source_color;
uniform vec4 primary_replace_color : source_color;
uniform vec4 secondary_color : source_color;
uniform vec4 secondary_replace_color : source_color;
uniform vec4 line_color : source_color;
uniform vec4 line_replace_color : source_color;
uniform vec4 transparent_color : source_color;
uniform vec4 transparent_replace_color : source_color;
uniform float color_threshold : hint_range(0.0, 1.0, 0.001);

float psuedo_rand(float x) {
	return mod(x * 2048103.0 + cos(x * 1912.0), 1.0);
}

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
	
	// Melt Animation Code Below
	vec2 uv = UV;
	
	// Move pixels near the top faster
	uv.y -= progress / UV.y;
	
	// Created jagged edges for each pixel on the x-axis 
	uv.y -= progress * meltiness * psuedo_rand(UV.x - mod(UV.x, TEXTURE_PIXEL_SIZE.x));
	
	//COLOR = texture(TEXTURE, uv);
	
	// "delete" pixels out of range
	if (uv.y <= 0.0) {
		COLOR.a = 0.0;
	}
}

uniform bool baba_shader_on = false; // Whether we should use this shader or not
uniform float interval = 1.0; // the displacement will happen every [interval] seconds
uniform float timeDelay = 0.0; // use it if you don't want all the sprites to move at the same time
uniform float intensityX = 0.5; // X axis force of movement
uniform float intensityY = 0.1; // Y axis force of movement
uniform float seed = 42.0; // seed to randomize movement

void vertex() {
	if (baba_shader_on) {
	float chunk = floor((TIME + timeDelay) / interval);
	float seedNum = VERTEX.x + VERTEX.y + chunk + seed;
	float offsetX = sin(seedNum * 12.9898) * 43758.5453;
	float offsetY = sin(seedNum * 32.9472) * 94726.0482;
	offsetX = fract(offsetX);
	offsetX = offsetX * 2.0 - 1.0;
	offsetY = fract(offsetY);
	offsetY = offsetY * 2.0 - 1.0;
	VERTEX += vec2(offsetX * intensityX, offsetY * intensityY);
	}
}
