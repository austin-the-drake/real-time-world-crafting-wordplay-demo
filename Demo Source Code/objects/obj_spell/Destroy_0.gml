/// @description deathTrigger


if spell_class == "projectile" or spell_class == "wallCrawl" {
	with(obj_controller) {
		event_perform(ev_other, ev_user0);
	}
}

part_particles_create_color(global.partsys, x, y, global.part_pop, color, 5);

if variable_instance_exists(self, "death_payload") {

	var data_for_child = {components: death_payload};

	for (var i=0; i<death_count; i++) {
		instance_create_layer(x, y, layer, obj_spell, {
			spell_data: data_for_child,
			direction: direction + (random_range(-death_count, death_count) * 5),
			team: team,
			caster: caster
		});
	}
}