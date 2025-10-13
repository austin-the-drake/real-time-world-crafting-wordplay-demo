
switch(action) {
	default: {
		show_debug_message("undefined action");
	} break;
	case "resume":
	case "close": {
		scale_target = 0;
		alarm_set(0, 30);
	} break;
	case "main": {
		scale_target = 0;
		alarm_set(0, 30);
		with(obj_controller) {
			fade_target = 1;
			alarm_set(1, 120);
			audio_sound_gain(global.music_ref, 0, 2000);
		}
	} break;
	case "restart": {
		scale_target = 0;
		alarm_set(0, 30);
		with(obj_controller) {
			fade_target = 1;
			alarm_set(2, 120);
			audio_sound_gain(global.music_ref, 0, 2000);
		}
	} break;
	case "stats": {
		if stats_on {
			stats_on = false;
			text = "The " + global.winner + " team wins!\n\n" + string(array_length(global.spell_history)) + " spells were constructed.\nThis space contained a total of "  + string(array_length(global.elemental_data.elements)) + " magical elements.";
		} else {
			stats_on = true;
			text = "The " + global.winner + " team wins!\n\n" + "<detailed stats to go here>";
		}
	} break;
	case "api_left": {
		switch(global.api) {
			default:
			case "gemini": {
				global.api = "openai";
				global.key = global.openai_cred;
				secondary_sprite = spr_openai;
			} break;
			case "openai": {
				secondary_sprite = spr_claude;
				global.key = global.anthropic_cred;
				global.api = "anthropic";
			} break;
			case "anthropic": {
				secondary_sprite = spr_gemini;
				global.key = global.gemini_cred;
				global.api = "gemini";
			} break;
		}
		text = prelude_text + "\n\n\n\n\n\n\nCurrent Provider:\n" + global.api + "\n\nAPI key:\n" + string_copy(global.key, 1, min(16, string_length(global.key))) + " . . .";
	} break;
	case "api_right": {
		switch(global.api) {
			default:
			case "gemini": {
				global.api = "anthropic";
				global.key = global.anthropic_cred;
				secondary_sprite = spr_claude;
			} break;
			case "openai": {
				secondary_sprite = spr_gemini;
				global.key = global.gemini_cred;
				global.api = "gemini";
			} break;
			case "anthropic": {
				global.api = "openai";
				global.key = global.openai_cred;
				secondary_sprite = spr_openai;
			} break;
		}
		text = prelude_text + "\n\n\n\n\n\n\nCurrent Provider:\n" + global.api + "\n\nAPI key:\n" + string_copy(global.key, 1, min(16, string_length(global.key))) + " . . .";
	} break;
	case "api_paste": {
		if clipboard_has_text() {
			var clip = clipboard_get_text();
			if string_length(clip) > 25 {
				switch(global.api) {
					default:
					case "gemini": {
						global.gemini_cred = string_trim(clip);
						global.key = global.gemini_cred;
					} break;
					case "openai": {
						global.openai_cred = string_trim(clip);
						global.key = global.openai_cred;
					} break;
					case "anthropic": {
						global.anthropic_cred = string_trim(clip);
						global.key = global.anthropic_cred;
					} break;
				}
				text = prelude_text + "\n\n\n\n\n\n\nCurrent Provider:\n" + global.api + "\n\nAPI key:\n" + string_copy(global.key, 1, min(16, string_length(global.key))) + " . . .";
			}
		}
	} break;
}

