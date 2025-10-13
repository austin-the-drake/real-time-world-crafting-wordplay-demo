/// @description Typing sound
if currently_typing and my_turn and not global.paused {
	audio_play_sound(snd_type_pop, 1, false, 1, 0., 0.25);
}