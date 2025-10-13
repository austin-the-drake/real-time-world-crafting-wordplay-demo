

draw_set_alpha(scale_fade * 0.5);
draw_set_color(c_black);
draw_rectangle(-5, -5, 9999, 9999, false);
draw_set_color(c_white);
draw_set_alpha(1);

if image_xscale*scale_fade > 0.7 and image_yscale*scale_fade > 0.7 {
	draw_sprite_ext(sprite_index, image_index, x, y, image_xscale*scale_fade, image_yscale*scale_fade, image_angle, image_blend, 1);
	
	draw_set_font(fnt_default);
	draw_set_halign(fa_center);
	draw_set_valign(fa_top);
	draw_set_color(c_black);
	draw_text_ext_transformed(x, y - image_yscale*48*scale_fade, text, 32, image_xscale * 120, scale_fade, scale_fade, 0);
	draw_set_color(c_white);
	draw_set_valign(fa_top);
	draw_set_halign(fa_left);
}

if variable_instance_exists(self, "secondary_sprite") {
	var col = c_white;
	if variable_instance_exists(self, "secondary_color") {
		col = secondary_color;
	}
	draw_sprite_ext(secondary_sprite, image_index, x, y, 1*scale_fade, 1*scale_fade, 0, col, 1);
}