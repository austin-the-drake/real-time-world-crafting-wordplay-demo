
if not instance_exists(obj_menu_panel) {
	obj_menu.action = action;
	audio_play_sound(snd_type_pop, 1, false, 1, 0., 0.25);
	with(obj_menu) {
		event_perform(ev_other, ev_user0);
	}
}