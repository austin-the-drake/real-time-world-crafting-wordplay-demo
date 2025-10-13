/// @description Render
var draw_color;
if variable_instance_exists(self, "color") {
	draw_color = color;
} else {
	draw_color = make_color_rgb(random(256), random(256), random(256));
}

switch(spell_class) {
	default: {
		draw_text(x, y, "* Unknown Spell Class");
	} break;
	
	case "projectile": {
		//draw_set_color(draw_color);
		//draw_circle(x, y, projectile_radius, false);
		//draw_set_color(c_white);
		//draw_line(x, y, x+lengthdir_x(10, gravity_direction), y+lengthdir_y(10, gravity_direction));
		part_particles_create_color(global.partsys, x, y, global.part_proj, draw_color, 1);
	} break;
	
	case "wallCrawl": {
		//draw_set_color(draw_color);
		//draw_circle(x, y, projectile_radius, false);
		//draw_set_color(c_white);
		//draw_line(x, y, x+lengthdir_x(10, gravity_direction), y+lengthdir_y(10, gravity_direction));
		part_particles_create_color(global.partsys, x, y, global.part_proj, draw_color, 1);
	} break;
	
	case "teleportCaster": {} break;
	
	case "buffCaster": {} break;
	
	case "manifestation": {} break;
	
	case "aoe": {
		//draw_set_color(draw_color);
		//draw_set_alpha(0.25);
		//draw_circle(x, y, aoe_radius, false);
		//draw_set_alpha(1);
		//draw_set_color(c_white);
		if random(100) < 5 {
			part_particles_create_color(global.partsys, x, y, global.part_aoe, draw_color, 1);
		}
	} break;
	
	case "shield": {
		//draw_set_color(draw_color);
		//draw_set_alpha(0.25);
		//draw_circle(x, y, shield_radius, false);
		//draw_set_alpha(1);
		//draw_set_color(c_white);
		if random(100) < 10 {
			part_particles_create_color(global.partsys, x, y, global.part_shield, draw_color, 1);
		}
	} break;
	
	case "explosion": {
		//draw_set_color(draw_color);
		//draw_circle(x, y, explosion_radius, false);
		//draw_set_color(c_white);
	} break;
}