/// @description Manifestation

if array_length(elements) > 0 {
	var sound_lib = variable_struct_get(global.elemental_data, safe_set_attribute(manifestation_data,"elements", ["neutral"])[0]).SOUND_LIB;
	var snd;
	switch(sound_lib) {
		default:
		case "energetic": snd = snd_manifest_energetic; break;
		case "flaming": snd = snd_manifest_flaming; break;
		case "blowing": snd = snd_manifest_blowing; break;
		case "crackling": snd = snd_manifest_crackling; break;
	}
	audio_play_sound(snd, 1, false);
}


var snapped_x = floor(x / 16) * 16;
var snapped_y = floor(y / 16) * 16;

switch(manifestation_data.class) {
	default: {
		show_debug_message("Unknown particle class!");
		exit;
	} break;
	
	case "powder": {
		var layer_name = "Solids";
	} break;

	case "liquid": {
		var layer_name = "Liquids";
	} break;
	
	case "gas": {
		var layer_name = "Liquids";
	} break;
	
	case "solid": {
		var layer_name = "Solids";
	} break;
}

for (var i=snapped_x-(manifestation_radius*16);i<snapped_x+(manifestation_radius*16); i+=16) {
	for (var j=snapped_y-(manifestation_radius*16);j<snapped_y+(manifestation_radius*16); j+=16) {
		instance_create_layer(i, j, layer_get_id(layer_name), obj_cell, {particle_data: manifestation_data});
	}
}

instance_destroy();