/// @description Collision
if spell_class == "projectile" {
	
	
	if array_length(elements) > 0 {
		var sound_lib = variable_struct_get(global.elemental_data, elements[0]).SOUND_LIB;
		var snd;
		switch(sound_lib) {
			default:
			case "energetic": snd = snd_impact_energetic; break;
			case "flaming": snd = snd_impact_flaming; break;
			case "blowing": snd = snd_impact_blowing; break;
			case "crackling": snd = snd_impact_crackling; break;
		}
		audio_play_sound(snd, 1, false);
	}
	
	
	
	if bounces > 0 {
		//var incident = direction;
		move_bounce_solid(true);
		//var reflection = direction;
		//if variable_instance_exists(self, "wall_crawl") {
			//wall_crawl = other.id;
			//gravity_direction = incident + angle_difference(reflection + 180, incident) / 2;
			//direction = (-sign(angle_difference(reflection + 180, incident)) * 91) + incident + angle_difference(reflection + 180, incident) / 2;
			//gravity = 0;
		//}
		bounces --;
	}
	
	if variable_instance_exists(self, "impact_payload") {
		var data_for_child = {components: impact_payload};

		for (var i=0; i<max(impact_count, impact_reps*impact_count); i++) {
			instance_create_layer(x, y, layer, obj_spell, {
			spell_data: data_for_child,
			direction: direction + (random_range(-impact_count, impact_count) * 5),
			team: team,
			caster: caster
			});
			impact_reps--;
		}
		
		if impact_replace {
			instance_destroy();
		}
	}
	
	if bounces <= 0 {
		instance_destroy();
	}
} else if spell_class == "wallCrawl" {
	
		if variable_instance_exists(self, "controllable") {
			controllable = false;
		}
		var incident = direction;
		move_bounce_solid(true);
		var reflection = direction;
		var to_wall = incident + angle_difference(reflection + 180, incident) / 2;
		if orientation == 0 {
		gravity = 0;
		if angle_difference(incident, to_wall) > 0 {
			orientation = -1;
		} else {
			orientation = 1;
		}
		
	}
	direction = to_wall - 90 * orientation;
	x += lengthdir_x(1, to_wall + 180);
	y += lengthdir_y(1, to_wall + 180);
	
}

