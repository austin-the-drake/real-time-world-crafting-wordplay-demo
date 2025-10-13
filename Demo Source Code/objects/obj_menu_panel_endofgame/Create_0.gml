
audio_play_sound(snd_fanfare, 1, false);
audio_sound_gain(global.music_ref, 0.001, 1000);
alarm_set(1, 420);

elements = [
	instance_create_depth(x-224, y+256, -101, obj_panel_button, {
		par: id,
		action: "main",
		text: "Main Menu",
		image_yscale: 0.6875,
		image_xscale: 1.25
	}),
	instance_create_depth(x, y+256, -101, obj_panel_button, {
		par: id,
		action: "restart",
		text: "Play Again",
		image_yscale: 0.6875,
		image_xscale: 1.25
	}),
	instance_create_depth(x+224, y+256, -101, obj_panel_button, {
		par: id,
		action: "stats",
		text: "Stats",
		image_yscale: 0.6875,
		image_xscale: 1.25
	})
];

image_xscale = 6;
image_yscale = 6;

stats_on = 0;

text = "The " + global.winner + " team wins!\n\n" + string(array_length(global.spell_history)) + " spells were constructed.\nThis space contained a total of "  + string(array_length(global.elemental_data.elements)) + " magical elements.";
event_inherited();

