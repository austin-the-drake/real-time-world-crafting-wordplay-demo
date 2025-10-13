

color_surface = undefined;
scribble_surface = undefined;

if not surface_exists(color_surface) {
	color_surface = surface_create(array_length(global.elemental_data.elements), array_length(global.elemental_data.elements));
	surface_set_target(color_surface);
	
	
	for (var i=0; i<array_length(global.elemental_data.elements); i++) {
		for (var j=0; j<array_length(global.elemental_data.elements); j++) {
			var attacker = global.elemental_data.elements[i];
			var defender = global.elemental_data.elements[j];
			var value = variable_struct_get(variable_struct_get(global.elemental_data, defender), attacker);
			var color = make_color_rgb(236, 236, 236);
			if i == j {
				color = c_ltgray;
			} // No else, a player could make an element strong against itself
			if value > 0 {
				color = wonder_green;
			} else if value < 0 {
				color = happy_red;
			}
			draw_set_color(color);
			draw_point(i, j);
		}
	}
	draw_set_color(c_white);
	
	surface_reset_target();
}

if not surface_exists(scribble_surface) {
	scribble_surface = surface_create(array_length(global.elemental_data.elements)*32, array_length(global.elemental_data.elements)*32);
}