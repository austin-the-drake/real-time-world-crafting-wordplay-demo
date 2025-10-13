

if action == "api_settings" {
	
	
	if string_length(global.key) < 20 {
		
		blink+=10;
		var col = make_color_hsv(color_get_hue(dull_yellow), clamp(lengthdir_x(127, blink), 0, 255), 255);
		draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, 0, col, image_alpha);
		
		draw_set_color(c_black);
		draw_set_alpha(clamp(1 + lengthdir_x(-0.9, blink), 0, 1));
		draw_set_valign(fa_middle);
		draw_text(x + 64, y, "Warning: No API key provided");
		draw_set_alpha(1);
		draw_set_valign(fa_top);
		draw_set_color(c_white);
	} else {
		
		draw_self();
		
		draw_set_color(c_black);
		draw_set_valign(fa_middle);
		draw_text(x + 64, y, "Using " + global.api + " API with a provided key");
		draw_set_valign(fa_top);
		draw_set_color(c_white);
	}
	

} else {
	draw_self();
}
draw_set_font(fnt_default);
draw_set_halign(fa_center);
draw_set_valign(fa_center);
draw_set_color(c_black);
draw_text_transformed(x, y, text, 1 + highlighted * 0.1, 1 + highlighted * 0.1, 0);
draw_set_color(c_white);
draw_set_valign(fa_top);
draw_set_halign(fa_left);

if variable_instance_exists(self, "secondary_sprite") {
	var col = c_white;
	if variable_instance_exists(self, "secondary_color") {
		col = secondary_color;
	}
	draw_sprite_ext(secondary_sprite, image_index, x, y, image_xscale, image_yscale, 0, col, 1);
}