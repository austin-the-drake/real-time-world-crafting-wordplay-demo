/// @description Init

// Choose a random image for variety
image_index = irandom(image_number);

// Ease the visual particle towards the simulated one for smoothness
ease_x = x;
ease_y = y;

// property flags as a binary string
particle_flags = 0;
switch(particle_data.class) {
	default: {
		show_debug_message("Unknown particle class!");
		instance_destroy();
		exit;
	} break;
	
	case "powder": {
		particle_flags = particle_flags | ca_type_powder;
	} break;

	case "liquid": {
		particle_flags = particle_flags | ca_type_liquid;
		sprite_index = spr_ca_liquid;
	} break;
	
	case "gas": {
		particle_flags = particle_flags | ca_type_gas;
	} break;
	
	case "solid": {
		particle_flags = particle_flags | ca_type_solid;
	} break;
}

// Read particle data from the spell script used to instantiate us
solid = safe_set_attribute(particle_data, "blockpath", false);
var c = safe_set_attribute(particle_data, "color_rgb", [255, 0, 255]);
image_blend = make_color_rgb(clamp(c[0] + random_range(-8, 8), 0, 255), clamp(c[1] + random_range(-8, 8), 0, 255), clamp(c[2] + random_range(-8, 8), 0, 255));
density = safe_set_attribute(particle_data, "density", 1);
elements = safe_set_attribute(particle_data, "elements", ["neutral"]);
viscous = safe_set_attribute(particle_data, "viscous", false);
lifespan = safe_set_attribute(particle_data, "lifespan", 999);
spreads = safe_set_attribute(particle_data, "zombie", false);
harmful = safe_set_attribute(particle_data, "harmful", false);

if array_contains(elements, "healing") {
	// Unintuitive, but healing must deal damage to be applied
	harmful = true;
}

// Set a physics solid flag when necessary
if (particle_flags & ca_type_powder) == ca_type_powder {
	solid = true;
}

// Gas has a maximum lifespan
if (particle_flags & ca_type_gas) == ca_type_gas {
	lifespan = min(lifespan, 15);
}

// Set the lifespan timer
alarm_set(0, ceil(lifespan * game_get_speed(gamespeed_fps) + random(game_get_speed(gamespeed_fps))));

// Check for a collision at the spawn point
var collider = collision_point(x + 8, y + 8, [obj_tile, obj_cell], true, true);

if collider == noone {
	exit;
}

// Destroy self if spawned inside of a wall
if collider.object_index == obj_tile {
	instance_destroy();
}

// Destroy any other particles we spawned into
if collider.object_index == obj_cell {
	instance_destroy(collider);
}
	