/// @description timerTrigger
if spell_class == "aoe" or spell_class == "shield" {
	alarm_loop = false;
	alarm_reps = 1;
}
var data_for_child = {components: alarm_payload};

for (var i=0; i<min(alarm_count, alarm_reps*alarm_count); i++) {
	instance_create_layer(x, y, layer, obj_spell, {
		spell_data: data_for_child,
		direction: direction + (random_range(-alarm_count, alarm_count) * 5),
		team: team,
		caster: caster
	});
	alarm_reps--;
}

if alarm_loop {
	alarm_set(0, alarm_duration);
}

if alarm_replace {
	instance_destroy();
}