

var border_width = global.gui_height * 0.03;
var x1 = global.gui_width * 0.667;
var y1 = global.gui_height - (global.gui_width * 0.333);
draw_rectangle(x1+global.gui_width*0.003, y1+global.gui_width*0.003, x1+global.gui_width * 0.32, y1+global.gui_width * 0.32, false);
draw_sprite_stretched(spr_gui_box, image_index * 2, x1, y1, global.gui_width * 0.323, global.gui_width * 0.323);
//draw_surface_stretched()


surface_set_target(scribble_surface);
gpu_set_tex_filter(false);
draw_clear_alpha(c_black, 0);
draw_sprite_tiled(spr_ca_squares, image_index, 0, 0);
gpu_set_blendmode_ext(bm_dest_color, bm_zero);
draw_surface_stretched(color_surface, 0, 0, array_length(global.elemental_data.elements) * 32, array_length(global.elemental_data.elements) * 32);
gpu_set_blendmode(bm_normal);
gpu_set_tex_filter(true);
surface_reset_target();

draw_set_color(c_black);
draw_set_halign(fa_right);
var text_scale = global.gui_height / 1080;
var lil_text_scale = min(text_scale * (10 / array_length(global.elemental_data.elements)), 1);
var move_amt = text_scale * (500 / array_length(global.elemental_data.elements));

for (var i=0; i<array_length(global.elemental_data.elements); i++) {
	draw_text_transformed(x1 + (border_width*3) + ((i+0.5) * move_amt), y1 + (border_width*2.5), global.elemental_data.elements[i], lil_text_scale, lil_text_scale, -45);
	draw_text_transformed(x1 + (border_width*3), y1 + (border_width*3) + ((i+0.5) * move_amt), global.elemental_data.elements[i], lil_text_scale, lil_text_scale, -45);
}

draw_set_halign(fa_left);

draw_set_color(c_white);

draw_surface_stretched(scribble_surface, x1+(border_width*3), y1+(border_width*3), (global.gui_width * 0.323)-(border_width*4), (global.gui_width * 0.323)-(border_width*4));
//draw_surface(scribble_surface, 0, 0);