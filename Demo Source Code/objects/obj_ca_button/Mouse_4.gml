/// @description Action

switch(name) {
	default: {
		if array_contains(struct_get_names(obj_ca_controller.ca_types), name) {
			global.selected_element = name;
			audio_play_sound(snd_type_pop, 1, false, 1, 0., 0.25);
		} break;
	} break;
	case "exit": {
		with(obj_ca_controller) {
			fade_target = 1;
			alarm_set(1, 120);
			audio_play_sound(snd_make_request, 1, false, 0.5);
			audio_sound_gain(obj_ca_controller.my_music, 0, 1000);
		}
	} break;
	case "clear": {
		with(obj_ca_controller) {
			event_perform(ev_other, ev_user0);
		}
		audio_play_sound(snd_shield_up, 1, false);
	} break;
	case "pause": {
		name = "play";
		with(obj_ca_controller) {
			alarm_set(0, -1);
		}
		audio_play_sound(snd_type_pop, 1, false, 1, 0., 0.25);
	} break;
	case "play": {
		name = "pause";
		with(obj_ca_controller) {
			alarm_set(0, 1);
		}
		audio_play_sound(snd_type_pop, 1, false, 1, 0., 0.25);
	} break;
	case "set /\nenter": {
		with(obj_ca_controller) {
			event_perform(ev_other, ev_user1);
		}
	}
}