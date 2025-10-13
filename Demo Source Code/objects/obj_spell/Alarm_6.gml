/// @description Launch sound
if spell_class == "projectile" or spell_class == "wallCrawl" {
	if array_length(elements) > 0 {
		var sound_lib = variable_struct_get(global.elemental_data, elements[0]).SOUND_LIB;
		var snd;
		switch(sound_lib) {
			default:
			case "energetic": snd = snd_cast_energetic; break;
			case "flaming": snd = snd_cast_flaming; break;
			case "blowing": snd = snd_cast_blowing; break;
			case "crackling": snd = snd_cast_crackling; break;
		}
		audio_play_sound(snd, 1, false);
	}
} else if spell_class == "aoe" {

	if array_length(elements) > 0 {
		var sound_lib = variable_struct_get(global.elemental_data, elements[0]).SOUND_LIB;
		var snd;
		switch(sound_lib) {
			default:
			case "energetic": snd = snd_activate_energetic; break;
			case "flaming": snd = snd_activate_flaming; break;
			case "blowing": snd = snd_activate_blowing; break;
			case "crackling": snd = snd_activate_crackling; break;
		}
		audio_play_sound(snd, 1, false);
	}
}