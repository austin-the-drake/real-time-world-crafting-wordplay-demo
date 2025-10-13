/// @description Change turn mode
if not waiting_for_response {
	turn_mode = not turn_mode;
	keyboard_string = "";
	if turn_mode == 1 {
		instance_create_layer(0, 0, layer, obj_element_panel, {par:id});
	}
	if num_elemental_charges == 0 {
		turn_mode = 0;
	}
}