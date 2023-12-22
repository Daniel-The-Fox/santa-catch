/*
 * This shader is based on code from AThousandShips at https://github.com/godotengine/godot-proposals/issues/6870
 * and the tutorial from Yep at https://www.youtube.com/watch?v=4qzi5fEJs4s
 *
 * Further insights got triggered while reading Godot Engine docs on comparing floats in Godot's shader language:
 * https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shading_language.html#flow-control
 *
 * Background info:
 * - Colors are vectors of floats in Godot (Red, Green, Blue, Alpha)!
 * - Depenging on your image, your screen and the compatibility mode you're using Godot in, 
 *   colors will differ in their floating point number representation, 
 *   even if you're seeing (or think you're seeing) the exact same color!
 *   For instance, see https://stackoverflow.com/q/75702333
 * - The basic idea is to have an image with up to 3 dummy colors to be replaced by pickable colors
 * - The max. 3 dummy colors should be either a
 *     o "full" red (R: 1.0, G: 0.0, B: 0.0) or
 *     o "full" green (R: 0.0, G: 1.0, B: 0.0) or
 *     o "full" blue (R: 0.0, G: 0.0, B: 1.0)
 * - Some image editors will not display values as 0.0 - 1.0, but as 0 - 255.
 *   In this case, use 0 for 0.0 and 255 for 1.0
 * - This makes color (vector) comparison much easier as floating point number errors don't come into effect as much
 * - Don't change the shader parameters "Color 1 Old" and "Color 2 Old" if not necessary!
 *   They're being displayed as pickable as a reference when picking "Color 1 New" and "Color 2 New"
 * - You probably shoudn't have to, but you can use EPSILON to tweak the tolerance for comparing colors, 
 *   if you really need to 
 * - Don't forget to set "Texture" -> "Filter" to "Nearest" in the Inspector when working with pixel art, 
 *   in order to prevent unwanted anti-aliasing
 * - Don't forget to enable "Local to Scene" in the shader's properties in the Inspector, 
 *   if you're planning to use multiple instances of the same shader with different color replacements
 * - You can use this shader in GDScript to set a different replacement color via something like: 
 *     var new_color = Color(
 *             randf_range(0.0, 1.0),
 *             randf_range(0.0, 1.0),
 *             randf_range(0.0, 1.0),
 *             1.0
 *     )
 *     sprite.material.set_shader_parameter("color_1_new", new_color)
 * - For details, see https://docs.godotengine.org/en/stable/classes/class_color.html
 */

shader_type canvas_item;


// Constants
const float EPSILON = 0.0001;


// Shader parameters
uniform vec4 color_1_old: source_color = vec4(0.0, 1.0, 0.0, 1.0);		// "full" green
uniform vec4 color_1_new: source_color = vec4(0.14, 0.36, 0.25, 1.0);		// 245c40 (dark green)

uniform vec4 color_2_old: source_color = vec4(1.0, 0.0, 0.0, 1.0);		// "full" red
uniform vec4 color_2_new: source_color = vec4(0.89, 0.23, 0.26, 1.0);		// e43b44 (not so intensive red)


bool is_zero_approx_float(float p_arg) {
	return (
			(p_arg >= -EPSILON) &&
			(p_arg <= EPSILON)
	);
}


bool is_zero_approx_vec4(vec4 p_vec) {
	return (
			is_zero_approx_float(p_vec.x) &&
			is_zero_approx_float(p_vec.y) &&
			is_zero_approx_float(p_vec.z) &&
			is_zero_approx_float(p_vec.w)
	);
}


// This function is called on every pixel.
// See https://docs.godotengine.org/en/stable/tutorials/shaders/introduction_to_shaders.html
void fragment() {

	vec4 current_pixel_color = texture(TEXTURE, UV);
	vec4 new_pixel_color = current_pixel_color;

	// Don't change transparent pixels
	if (current_pixel_color.a > 0.0) {
 
		if (is_zero_approx_vec4(current_pixel_color - color_1_old)) {
			new_pixel_color = color_1_new;
		}
		
		if (is_zero_approx_vec4(current_pixel_color - color_2_old)) {
			new_pixel_color = color_2_new;
		}

		// Finally, update color of current pixel
		COLOR = new_pixel_color;
	}

}
