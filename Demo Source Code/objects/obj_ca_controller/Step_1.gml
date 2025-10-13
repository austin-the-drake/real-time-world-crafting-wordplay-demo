/// @description Handle context loss

// If the window is resized, or another window gets focus, we need to reallocate video memory
if not surface_exists(world_surface) {
	world_surface = surface_create(world_size * 32, world_size * 32);
}
if not surface_exists(ca_surface) {
	ca_surface = surface_create(world_size, world_size);
	surface_set_target(ca_surface);
	draw_clear_alpha(c_black, 0);
	surface_reset_target();
}

fade += (fade_target - fade) / 25;