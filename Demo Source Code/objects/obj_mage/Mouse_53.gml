/// @description Change turn mode
if my_turn and currently_typing and not waiting_for_response {
	var text_scale = global.gui_height / 1080;
	if point_distance(window_mouse_get_x(), window_mouse_get_y(), global.gui_width * 0.13, global.gui_height * 0.67) < 64 * text_scale {
		turn_mode = 1;
		keyboard_string = "";
		if num_elemental_charges == 0 {
			turn_mode = 0;
		}
	} else 	if point_distance(window_mouse_get_x(), window_mouse_get_y(), global.gui_width * 0.052, global.gui_height * 0.67) < 64 * text_scale {
		turn_mode = 0;
		keyboard_string = "";
		if num_elemental_charges == 0 {
			turn_mode = 0;
		}
	}
}