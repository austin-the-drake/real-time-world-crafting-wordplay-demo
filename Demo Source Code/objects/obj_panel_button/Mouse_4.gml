
par.action = action;
audio_play_sound(snd_type_pop, 1, false, 1, 0., 0.25);
with(par) {
	event_perform(ev_other, ev_user0);
}

if text == "Stats" {
	text = "Return";
} else if text == "Return" {
	text = "Stats";
}