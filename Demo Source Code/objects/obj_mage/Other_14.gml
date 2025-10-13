/// @description Callback for elements

if my_turn {
	show_debug_message("recieved spell data, ready to cast");
	currently_typing = false;
	waiting_for_response = false;
	ready_to_cast = false;
	audio_play_sound(snd_magic_words, 1, false);
	
	
	/// @description Manifestation

	var snapped_x = floor(x / 16) * 16;
	var snapped_y = floor(y / 16) * 16;


	for (var i=snapped_x-(2*16);i<snapped_x+(2*16); i+=16) {
		for (var j=snapped_y-(2*16);j<snapped_y+(2*16); j+=16) {
			instance_create_layer(i, j, layer_get_id("Liquids"), obj_cell, {particle_data: {
				"class": "gas",
		        "color_rgb": [
		          255,
		          255,
		          255
		        ],
		        "blockpath": 0,
		        "density": 0.5,
		        "elements": [
		          "neutral"
		        ],
		        "lifespan": 1
			}});
		}
	}
	
	my_turn = false;
	with(obj_controller) {
		alarm_set(0, 3 * game_get_speed(gamespeed_fps));
	}
}