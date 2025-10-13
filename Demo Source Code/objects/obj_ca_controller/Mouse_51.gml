/// @description Remove cells


if mouse_x < world_size*32+(canvas_offset*2) and array_contains(struct_get_names(ca_types), "air") {
	if ca_grid[get_mouse_x(canvas_offset)][get_mouse_y(canvas_offset)][0] != "air" {
		set_cell(get_mouse_x(canvas_offset), get_mouse_y(canvas_offset), "air", 0);
		audio_play_sound(snd_type_pop, 1, false, 0.25, 0, random_range(0.5, 1));
	}
}