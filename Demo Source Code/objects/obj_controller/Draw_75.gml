/// @description Fade in/out

// Draw a fullscreen rectangle to fade in and out
fade += (fade_target-fade) / 25;
draw_set_alpha(fade);
draw_rectangle(-5, -5, global.gui_width+5, global.gui_height+5, false);
draw_set_alpha(1);
