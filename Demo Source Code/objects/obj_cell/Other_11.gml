/// @description Render

if (particle_flags & ca_type_powder) == ca_type_powder {
	
	draw_sprite_ext(spr_ground, 0, x+8, y+8, 0.2, 0.2, 0, image_blend, 1);
	
} else if (particle_flags & ca_type_liquid) == ca_type_liquid {
	
	draw_sprite_ext(spr_ground, 0, x+8, y+8, 0.2, 0.2, 0, image_blend, 1);
	
} else {
	
}