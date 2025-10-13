/// @description Render

draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, image_angle, blend, image_alpha);
draw_set_font(fnt_default);
draw_set_color(c_black);

draw_text(x + 12, y + 8, string_copy(name, 0, min(string_length(name), 5)));

if array_contains(variable_struct_get_names(obj_ca_controller.ca_types), name) {
	draw_sprite_part_ext(spr_ca_squares, image_index / 2, 0, 0, 32, 32, x + 36, y + 36, 1, 1, variable_struct_get(obj_ca_controller.ca_types, name).color, 1);
}

draw_set_color(c_white);