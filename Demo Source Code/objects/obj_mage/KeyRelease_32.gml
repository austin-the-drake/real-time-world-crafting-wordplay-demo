/// @description Cast
if currently_typing == false and my_turn and ready_to_cast and not global.paused {
	audio_sound_loop(aim_sound, false);
	audio_sound_gain(aim_sound, 0, 250);
	show_debug_message("attempting cast");
	var ang = 90 + (-90 * facing) + (aim_angle * facing);
	var num = safe_set_attribute(spell_data, "count", 1);
	for (var i=0;i<num;i++) {
		instance_create_layer(x, y, layer, obj_spell, {
			spell_data: spell_data,
			team: my_team,
			caster: id,
			direction: ang + random_range(-10*num, 10*num),
			aim_power: aim_power,
			take_camera_control: true
		});
	}
	cooldown = 10;
	ready_to_cast = false;
	my_turn = false;
	with(obj_controller) {
		alarm_set(0, 5 * game_get_speed(gamespeed_fps));
	}
}