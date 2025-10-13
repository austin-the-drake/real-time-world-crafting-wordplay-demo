/// @description buttonTrigger

var data_for_child = {components: button_payload};

for (var i=0; i<min(button_reps * button_count, button_count); i++) {
	instance_create_layer(x, y, layer, obj_spell, {
		spell_data: data_for_child,
		direction: direction + (random_range(-button_count, button_count) * 5),
		team: team,
		caster: caster
	});
	button_reps--;
}

if button_replace {
	instance_destroy();
}