/// @description Interaction

if spell_class == "projectile" {
	
	// Two situations in which we need to evaluate the interaction
	// 1) If other is an enemy's shield
	// 2) If other is anyone's aoe
	if (other.spell_class == "shield" and other.team != team) or (other.spell_class == "aoe") {
		// Ensure the two spells have at least one element each
		if array_length(other.elements) > 0 and array_length(elements) > 0 {
			
			var aggregate_interaction = aggregate_elemental_interaction(elements, other.elements, global.elemental_data);
				
			if aggregate_interaction > 0 {
				instance_destroy(other);
				audio_play_sound(snd_debug, 1, false);
			} else if aggregate_interaction < 0 {
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
				audio_play_sound(snd_debug, 1, false);
				instance_destroy(self);
			}
				
		}
	}
}
