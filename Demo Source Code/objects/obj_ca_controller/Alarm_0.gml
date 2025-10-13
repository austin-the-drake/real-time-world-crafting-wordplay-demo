/// @description Main update
alarm_set(0, max(1, ceil(game_get_speed(gamespeed_fps) / update_fps)));
surface_set_target(ca_surface);
//draw_clear_alpha(c_black, 1);
gpu_set_blendenable(false);

//swap_cells(4, 4, 8, 8);

// Loop over all cells in the world
for (var j=world_size-1; j>=0; j--) {
	for (var i=0; i<world_size; i++) {
		var source_data = ca_grid[i][j];
		
		if not array_contains(struct_get_names(ca_types), source_data[0]) {
			set_cell(i, j, "air", 0);
			source_data = ca_grid[i][j];
		}
		
		// Only evaluating a given cell once per step, even if it moved into the path of a later update
		if source_data[2] > 0 {
			
			var actions = variable_struct_get(ca_types, source_data[0]).behavior.actions;
			
			evaluate(i, j, actions);
			
		}
		ca_grid[i][j][2]++;
	}
}


//draw_set_alpha(random(1));
//draw_set_color(make_color_rgb(random(256), random(256), random(256)));
//draw_point(get_mouse_x(0), get_mouse_y(0));


draw_set_color(c_white);
draw_set_alpha(1);
gpu_set_blendenable(true);
surface_reset_target();