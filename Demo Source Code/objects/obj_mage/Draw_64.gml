/// @description Spell UI

if currently_typing and not global.paused {
	if waiting_for_response {
		keyboard_string = "";
	}
	var text_scale = global.gui_height / 1080;
	
	if turn_mode == 0 {
		draw_set_font(fnt_default);
	
		draw_sprite_ext(spr_gui_circle, image_index,
		global.gui_width * 0.052,
		global.gui_height * 0.67,
		text_scale, text_scale, 0, c_white, 1);
		
		draw_sprite_ext(spr_icons, 0,
		global.gui_width * 0.052,
		global.gui_height * 0.67,
		text_scale * 0.5, text_scale * 0.5, 0, c_white, 1);
		
		if num_elemental_charges == 0 {
			draw_sprite_ext(spr_gui_bubble_small, image_index,
			global.gui_width * 0.13,
			global.gui_height * 0.67,
			text_scale, text_scale, 0, c_white, 1);
		} else {
			draw_sprite_ext(spr_gui_bubble_large, image_index,
			global.gui_width * 0.13,
			global.gui_height * 0.67,
			text_scale, text_scale, 0, c_white, 1);
			
			draw_sprite_ext(spr_icons, 3,
			global.gui_width * 0.13,
			global.gui_height * 0.67,
			text_scale * 0.5, text_scale * 0.5, 0, c_white, 1);
		}
	
		draw_rectangle(
		global.gui_width * 0.02 + 10,
		global.gui_height * 0.75 + 10,
		global.gui_width * 0.98 - 10,
		global.gui_height * 0.98 - 10,
		false);
		
		draw_sprite_stretched(spr_gui_box, image_index,
				global.gui_width * 0.02,
				global.gui_height * 0.75,
				global.gui_width * 0.96,
				global.gui_height * 0.23);
		
		if waiting_for_response {
			draw_set_color(c_gray);
	
			draw_text_ext_transformed(
				global.gui_width * 0.04,
				global.gui_height * 0.78,
				"Waiting for a response from your patron...",
				global.gui_height * 0.03,
				global.gui_width * 0.7 / text_scale,
				text_scale, text_scale, 0);
			draw_set_color(c_white);
		} else {
	
			if keyboard_string == "" {
				draw_set_color(c_gray);
	
				draw_text_ext_transformed(
				global.gui_width * 0.04,
				global.gui_height * 0.78,
				"Describe your spell...",
				global.gui_height * 0.03,
				global.gui_width * 0.7 / text_scale,
				text_scale, text_scale, 0);
			} else {
				draw_set_color(c_black);
	
				draw_text_ext_transformed(
				global.gui_width * 0.04,
				global.gui_height * 0.78,
				keyboard_string,
				global.gui_height * 0.03,
				global.gui_width * 0.7 / text_scale,
				text_scale, text_scale, 0);
			}
			var num_lines = 5;
			history_scroll = clamp(history_scroll, 0, max(0, array_length(global.spell_history) - num_lines));
			var top_range = min(history_scroll + num_lines, array_length(global.spell_history));
			var str = "Previous spells:\n";
			for (var i=history_scroll; i<top_range; i++) {
				str += global.spell_history[i].friendlyName + "\n";
				var alph = 1;
				if window_mouse_get_x() > global.gui_width * 0.74 and window_mouse_get_x() < global.gui_width * 0.96 {
					if window_mouse_get_y() > (global.gui_height * 0.778 + ((i-history_scroll+1) * (text_scale * 32))) and window_mouse_get_y() < (global.gui_height * 0.778 + ((i-history_scroll+2) * (text_scale * 32))) {
						alph = 0.25;
						if mouse_check_button_pressed(mb_left) {
							currently_typing = false;
							ready_to_cast = true;
							audio_play_sound(snd_spell_recieved, 1, false, 0.5);
							spell_data = global.spell_history[i];
						}
					}
				}
				draw_sprite_stretched_ext(spr_gui_button, 0,
					global.gui_width * 0.74,
					global.gui_height * 0.778 + ((i-history_scroll+1) * (text_scale * 32)),
					global.gui_width * 0.22,
					text_scale * 32, c_white, alph);
			}
			draw_set_color(c_black);
			draw_text_ext_transformed(
				global.gui_width * 0.75,
				global.gui_height * 0.78,
				str,
				global.gui_height * 0.03 / text_scale,
				global.gui_width * 0.22 / text_scale,
				text_scale, text_scale, 0);
	
			draw_set_color(c_white);
		}
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	} else if turn_mode == 1 {
		draw_set_font(fnt_default);
	
		draw_sprite_ext(spr_gui_bubble_large, image_index,
		global.gui_width * 0.052,
		global.gui_height * 0.67,
		text_scale, text_scale, 0, c_white, 1);
		
		draw_sprite_ext(spr_icons, 2,
		global.gui_width * 0.052,
		global.gui_height * 0.67,
		text_scale * 0.5, text_scale * 0.5, 0, c_white, 1);
		
		if num_elemental_charges == 0 {
			draw_sprite_ext(spr_gui_bubble_small, image_index,
			global.gui_width * 0.13,
			global.gui_height * 0.67,
			text_scale, text_scale, 0, c_white, 1);
		} else {
			draw_sprite_ext(spr_gui_circle, image_index,
			global.gui_width * 0.13,
			global.gui_height * 0.67,
			text_scale, text_scale, 0, c_white, 1);
			
			draw_sprite_ext(spr_icons, 1,
			global.gui_width * 0.13,
			global.gui_height * 0.67,
			text_scale * 0.5, text_scale * 0.5, 0, c_white, 1);
		}
		/*
		draw_rectangle(
		global.gui_width * 0.02 + 10,
		global.gui_height * 0.75 + 10,
		global.gui_width * 0.98 - 10,
		global.gui_height * 0.98 - 10,
		false);
	
		draw_sprite_stretched(spr_gui_box, image_index,
			global.gui_width * 0.02,
			global.gui_height * 0.75,
			global.gui_width * 0.96,
			global.gui_height * 0.23);
		*/
		draw_rectangle(
			global.gui_width * 0.02 + 10,
			global.gui_height * 0.75 + 10,
			global.gui_width * 0.66 - 10,
			global.gui_height * 0.98 - 10,
			false);
	
		draw_sprite_stretched(spr_gui_box, image_index,
			global.gui_width * 0.02,
			global.gui_height * 0.75,
			global.gui_width * 0.64,
			global.gui_height * 0.23);
			
		if waiting_for_response {
			draw_set_color(c_gray);
	
			draw_text_ext_transformed(
				global.gui_width * 0.04,
				global.gui_height * 0.78,
				"Waiting for a response from your patron...",
				global.gui_height * 0.03,
				global.gui_width * 0.7 / text_scale,
				text_scale, text_scale, 0);
			draw_set_color(c_white);
		} else {
			if keyboard_string == "" {
				draw_set_color(c_gray);
	
				draw_text_ext_transformed(
				global.gui_width * 0.04,
				global.gui_height * 0.78,
				"Describe your new element or change the rules...",
				global.gui_height * 0.03,
				global.gui_width * 0.7 / text_scale,
				text_scale, text_scale, 0);
			} else {
				draw_set_color(c_black);
	
				draw_text_ext_transformed(
				global.gui_width * 0.04,
				global.gui_height * 0.78,
				keyboard_string,
				global.gui_height * 0.03,
				global.gui_width * 0.7 / text_scale,
				text_scale, text_scale, 0);
			}
			/*
			var num_lines = 5;
			history_scroll = clamp(history_scroll, 0, max(0, array_length(global.elemental_data.elements) - num_lines));
			var top_range = min(history_scroll + num_lines, array_length(global.elemental_data.elements));
			var str = "Elements in this space:\n";
			for (var i=history_scroll; i<top_range; i++) {
				str += global.elemental_data.elements[i] + "\n";
				var alph = 0.25;
				var draw_col = variable_struct_get(global.elemental_data, global.elemental_data.elements[i]).RGB_COLOR;
				draw_sprite_stretched_ext(spr_gui_button, 0,
					global.gui_width * 0.74,
					global.gui_height * 0.778 + ((i-history_scroll+1) * (text_scale * 32)),
					global.gui_width * 0.22,
					text_scale * 32, make_color_rgb(draw_col[0], draw_col[1], draw_col[2]), alph);
			}
			draw_set_color(c_black);
			draw_text_ext_transformed(
				global.gui_width * 0.75,
				global.gui_height * 0.78,
				str,
				global.gui_height * 0.03 / text_scale,
				global.gui_width * 0.22 / text_scale,
				text_scale, text_scale, 0);
	
			*/
	
	
	
			draw_set_color(c_white);
		}
	}
	
	
	var stri;
	if turn_mode == 0 {
		stri = "<Mouse> Select Previous Spell\n<Tab> Switch Action Type\n<Enter> Submit / Close";
	} else {
		stri = "<Tab> Switch Action Type\n<Enter> Submit / Close";
	}
	
	draw_set_color(c_black);
	draw_set_valign(fa_bottom);
	
	draw_text_ext_transformed(
		global.gui_width * 0.021,
		global.gui_height * 0.591,
		stri,
		32*text_scale,
		512,
		text_scale, text_scale, 0);
	draw_set_color(global.team_colors[global.current_team]);
	draw_text_ext_transformed(
		global.gui_width * 0.02,
		global.gui_height * 0.59,
		stri,
		32*text_scale,
		512,
		text_scale, text_scale, 0);
	draw_set_valign(fa_top);
	draw_set_color(c_white);
	
	
}

if my_turn and not currently_typing and not global.paused {
	
	var scale = global.gui_height / 1080;
	
	var str;
	if keyboard_check(vk_space) {
		str = "<Arrow Keys> Adjust Aim\n<Space> (Release) Cast Spell";
	} else {
		str = "<Arrow Keys> Move\n<Shift> Jump\n<Enter> Open Toolbox\n<Space> (Hold) Start Casting";
	}
	
	draw_set_color(c_black);
	draw_set_valign(fa_bottom);
	
	draw_text_ext_transformed(
		global.gui_width * 0.021,
		global.gui_height * 0.981,
		str,
		32*scale,
		512,
		scale, scale, 0);
	draw_set_color(global.team_colors[global.current_team]);
	draw_text_ext_transformed(
		global.gui_width * 0.02,
		global.gui_height * 0.98,
		str,
		32*scale,
		512,
		scale, scale, 0);
	draw_set_valign(fa_top);
	draw_set_color(c_white);
	
}