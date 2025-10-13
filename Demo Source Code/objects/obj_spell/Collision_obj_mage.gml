/// @description Interaction

if (spell_class == "projectile" or spell_class == "wallCrawl") and (other.my_team != team) {
	
	var aggregate_interaction = aggregate_elemental_interaction(elements, other.armor_elements, global.elemental_data);
	
	other.life -= max(10, (1 + aggregate_interaction) * 35);
				
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
		
		instance_destroy();
	} else {
		instance_destroy();
	}
				
}
