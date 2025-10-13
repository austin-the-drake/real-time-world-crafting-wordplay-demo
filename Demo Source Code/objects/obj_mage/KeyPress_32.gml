/// @description Silence music

if my_turn and ready_to_cast and not global.paused {
	audio_sound_gain(global.music_ref, 0.25, 3000);
	audio_sound_loop_start(snd_aim_spell, 2);
	audio_sound_loop_end(snd_aim_spell, 4);
	aim_sound = audio_play_sound(snd_aim_spell, 1, true);  // Play the sound looped
	audio_sound_gain(aim_sound, 1, 1);
}