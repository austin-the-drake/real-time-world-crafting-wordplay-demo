
if os_browser == browser_not_a_browser {
	display_set_gui_size(window_get_width(), window_get_height());
	global.gui_width = display_get_gui_width();
	global.gui_height = display_get_gui_height();
	view_set_wport(0, global.gui_width);
	view_set_hport(0, global.gui_height);
	surface_resize(application_surface, global.gui_width, global.gui_height);
} else {
	display_set_gui_size(1280, 720);
	global.gui_width = 1280;
	global.gui_height = 720;
	view_set_wport(0, global.gui_width);
	view_set_hport(0, global.gui_height);
	surface_resize(application_surface, global.gui_width, global.gui_height);
}
randomize();
my_music = audio_play_sound(snd_menu_music, 1, true, 1, 1);
fade = 1;
fade_target = 0;
if not variable_global_exists("doing_log") {
	global.doing_log = false;
}
action = "";

for (i=0; i<16; i++) {
	instance_create_layer(random_range(-room_width, room_width*2), random_range(0, room_height / 2), layer_get_id("BackgroundObjects"), obj_cloud);
}
