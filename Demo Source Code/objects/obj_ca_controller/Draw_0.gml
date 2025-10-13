/// @description Draw world

// Begin by drawing the main color map to a surface with scribble artwork
// Using alpha to make air cells invisible
surface_set_target(world_surface);
gpu_set_tex_filter(false);
draw_clear_alpha(c_black, 0);
draw_sprite_tiled(spr_ca_squares, image_index, 0, 0);
gpu_set_blendmode_ext(bm_dest_color, bm_zero);
draw_surface_stretched(ca_surface, 0, 0, world_size * 32, world_size * 32);
gpu_set_blendmode(bm_normal);
gpu_set_tex_filter(true);
surface_reset_target();

// Draw the final surface and UI elements
draw_surface(world_surface, canvas_offset, canvas_offset);

draw_sprite_stretched(spr_gui_box, image_index, 0, 0, world_size*32+(canvas_offset*2), world_size*32+(canvas_offset*2));

draw_rectangle(world_size*32+(canvas_offset*2) + 88 , 8, 1912, 1070, false);
draw_sprite_stretched(spr_gui_box, image_index, world_size*32+(canvas_offset*2) + 80 , 0, 768, world_size*32+(canvas_offset*2));

// Draw the material info on the right
if array_contains(struct_get_names(ca_types), global.selected_element) {
	var col = variable_struct_get(ca_types, global.selected_element).color;
	var str = "Element Name: " + global.selected_element + "\n";
	str += "RGB Colour: [" + string(color_get_red(col)) + ", " + string(color_get_green(col)) + ", " + string(color_get_blue(col)) + "]\n";
	str += "Behaviour: \n\n";
	str += format_behavior_to_string(variable_struct_get(ca_types, global.selected_element).behavior);
	str += "\n\nDescribe new behaviour:\n\n" + keyboard_string;
	draw_set_color(c_black);
	draw_set_font(fnt_default);
	draw_text_ext(world_size*32+(canvas_offset*2) + 108, 24, str, 32, 700);
	
	draw_set_color(c_white);
}