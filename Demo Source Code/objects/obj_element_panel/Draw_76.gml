
if not instance_exists(par) {
	instance_destroy();
	exit;
}
if par.turn_mode != 1 or par.currently_typing != true or global.current_team != par.my_team {
	instance_destroy();
}
if not surface_exists(color_surface) {
	color_surface = surface_create(array_length(global.elemental_data.elements), array_length(global.elemental_data.elements));
	surface_set_target(color_surface);
	draw_circle_color(4, 4, 9, c_blue, c_red, false);
	surface_reset_target();
}

if not surface_exists(scribble_surface) {
	scribble_surface = surface_create(array_length(global.elemental_data.elements)*32, array_length(global.elemental_data.elements)*32);
}