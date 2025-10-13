/// @description Render

if (particle_flags & ca_type_liquid) == ca_type_liquid {
	// Apply easing for liquid to disguise the cellular automata grid steps
	ease_x += (x-ease_x) / 10;
	ease_y += (y-ease_y) / 10;
	draw_sprite_ext(sprite_index, image_index, ease_x, ease_y, image_xscale, image_yscale, image_angle, image_blend, image_alpha);
} else if (particle_flags & ca_type_gas) == ca_type_gas {
	if random(100) < 10 {
		// Use gas particles instead of sprites if gaseous
		part_particles_create_color(global.partsys, x + 8, y + 8, global.part_gas, image_blend, 1);
	}
} else {
	draw_self();
}