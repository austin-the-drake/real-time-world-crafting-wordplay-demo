/// @description Asked for action

switch(action) {
	default: {
		show_debug_message("Undefined action");
	} break;
	case "quit": {
		alarm_set(0, 120);
		audio_sound_gain(my_music, 0, 2000);
		audio_play_sound(snd_make_request, 1, false, 0.5, 0., 1);
		fade_target = 1;
	} break;
	case "battle": {
		if string_length(global.key) < 20 {
			instance_create_layer(960, 540, layer_get_id("Panels"), obj_menu_panel_api);
		} else {
			alarm_set(0, 180);
			audio_sound_gain(my_music, 0, 2000);
			audio_play_sound(snd_make_request, 1, false, 0.5, 0., 1);
			fade_target = 1;
		}
	} break;
	case "about": {
		instance_create_layer(960, 540, layer_get_id("Panels"), obj_menu_panel_about);
	} break;
	case "alchemy": {
		if string_length(global.key) < 20 {
			instance_create_layer(960, 540, layer_get_id("Panels"), obj_menu_panel_api);
		} else {
			alarm_set(0, 180);
			audio_sound_gain(my_music, 0, 2000);
			audio_play_sound(snd_make_request, 1, false, 0.5, 0., 1);
			fade_target = 1;
		}
	} break;
	case "settings": {
		instance_create_layer(960, 540, layer_get_id("Panels"), obj_menu_panel_comingsoon);
	} break;
	case "api_settings": {
		instance_create_layer(960, 540, layer_get_id("Panels"), obj_menu_panel_api);
	} break;
}