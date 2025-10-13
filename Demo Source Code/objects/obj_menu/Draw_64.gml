

if global.doing_log {
	draw_set_color(c_black);
	draw_set_halign(fa_right);
	draw_set_valign(fa_bottom);
	
	draw_text(global.gui_width*0.98, global.gui_height*0.98, "Data collection enabled");
	
	draw_set_valign(fa_top);
	draw_set_halign(fa_left);
	draw_set_color(c_white);
}

draw_set_alpha(fade);
draw_rectangle(-5, -5, global.gui_width+5, global.gui_height+5, false);
draw_set_alpha(1);