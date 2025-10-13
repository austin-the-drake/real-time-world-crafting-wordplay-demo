

x = par.x + ((xstart-par.x) * par.scale_fade);
y = par.y + ((ystart-par.y) * par.scale_fade);

if image_xscale*par.scale_fade > 0.65 and image_yscale*par.scale_fade > 0.65 {
	draw_sprite_ext(sprite_index, image_index, x, y, image_xscale*par.scale_fade, image_yscale*par.scale_fade, 0, image_blend, 1);
	draw_set_font(fnt_default);
	draw_set_halign(fa_center);
	draw_set_valign(fa_center);
	draw_set_color(c_black);
	draw_text_transformed(x, y, text, (1 + highlighted * 0.1) * par.scale_fade, (1 + highlighted * 0.1) * par.scale_fade, 0);
	draw_set_color(c_white);
	draw_set_valign(fa_top);
	draw_set_halign(fa_left);

	if variable_instance_exists(self, "secondary_sprite") {
		var col = c_white;
		if variable_instance_exists(self, "secondary_color") {
			col = secondary_color;
		}
		draw_sprite_ext(secondary_sprite, image_index, x, y, image_xscale*par.scale_fade, image_yscale*par.scale_fade, 0, col, 1);
	}
}