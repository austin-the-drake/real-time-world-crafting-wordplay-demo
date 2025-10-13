/// @description Callback for spell gen

if my_turn {
	show_debug_message("recieved spell data, ready to cast");
	currently_typing = false;
	waiting_for_response = false;
	ready_to_cast = true;
	spell_data = global.latest_spell_data;
	array_insert(global.spell_history, 0, spell_data);
	audio_play_sound(snd_spell_recieved, 1, false, 0.5);
}