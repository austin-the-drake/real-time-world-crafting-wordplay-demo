
//audio_play_sound(snd_fanfare, 1, false);
audio_sound_gain(global.music_ref, 0.2, 1000);
//alarm_set(1, 420);

elements = [
	instance_create_depth(x-128, y+72, -101, obj_panel_button, {
		par: id,
		action: "main",
		text: "Main Menu",
		image_yscale: 0.6875,
		image_xscale: 1.25
	}),
	instance_create_depth(x+128, y+72, -101, obj_panel_button, {
		par: id,
		action: "resume",
		text: "Resume",
		image_yscale: 0.6875,
		image_xscale: 1.25
	})
];

image_xscale = 4;
image_yscale = 3;


text = "Paused"
event_inherited();

