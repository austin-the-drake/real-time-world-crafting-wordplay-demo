/// @description Permanent aspects of the GUI
if not global.paused {

var num_mages = array_length(global.round_team_fifo);

// Loop over all round mages and draw healthbars
for (var i=0; i<num_mages; i++) {
	if instance_exists(global.round_team_fifo[i]) {
		var bar_value = global.round_team_fifo[i].life;
	} else {
		var bar_value = 0;
	}
	
	draw_healthbar(
		global.gui_width * 0.02,
		(global.gui_height * 0.03 * i) + global.gui_height * 0.05,
		global.gui_width * 0.02 + global.gui_width * 0.1,
		(global.gui_height * 0.03 * i) + global.gui_height * 0.07,
		bar_value,
		c_gray, global.team_colors[0], global.team_colors[0], 0, true, true);
}

// Draw round team mana bar
draw_healthbar(
	global.gui_width * 0.02,
	(global.gui_height * 0.03 * num_mages) + global.gui_height * 0.05,
	global.gui_width * 0.02 + global.gui_width * 0.1,
	(global.gui_height * 0.03 * num_mages) + global.gui_height * 0.07,
	global.mana[0],
	c_gray, c_aqua, c_aqua, 0, true, true);
	
num_mages = array_length(global.square_team_fifo);

// Loop over all square mages and draw healthbars
for (var i=0; i<num_mages; i++) {
	
	if instance_exists(global.square_team_fifo[i]) {
		var bar_value = global.square_team_fifo[i].life;
	} else {
		var bar_value = 0;
	}
	
	draw_healthbar(
		global.gui_width * 0.98,
		(global.gui_height * 0.03 * i) + global.gui_height * 0.05,
		global.gui_width * 0.98 - global.gui_width * 0.1,
		(global.gui_height * 0.03 * i) + global.gui_height * 0.07,
		bar_value,
		c_gray, global.team_colors[1], global.team_colors[1], 0, true, true);
}

// Draw square team mana bar
draw_healthbar(
	global.gui_width * 0.98,
	(global.gui_height * 0.03 * num_mages) + global.gui_height * 0.05,
	global.gui_width * 0.98 - global.gui_width * 0.1,
	(global.gui_height * 0.03 * num_mages) + global.gui_height * 0.07,
	global.mana[1],
	c_gray, c_aqua, c_aqua, 0, true, true);

// Draw debug render FPS, simulation FPS, and countdown frames
draw_set_color(c_black);
draw_text(10, 10, string(fps) + " | " + string(round(fps_real)) + " | " + string(alarm_get(0)));
draw_set_color(c_white);

draw_set_font(global.countdown_font);
draw_set_halign(fa_center);
if alarm[3] > 0 {
	// Draw paused countdown timer in gray
	draw_text_ext_transformed_color(
		global.gui_width/2,
		global.gui_height * 0.05,
		string(round(alarm_get(0)/game_get_speed(gamespeed_fps))),
		0,
		global.gui_height * 0.1,
		global.gui_height/1080,
		global.gui_height/1080,
		0,
		c_ltgray, c_ltgray, c_gray, c_gray,
		1);
} else {
	// Draw colorful countdown timer in normal gameplay
	draw_text_ext_transformed_color(
		global.gui_width/2,
		global.gui_height * 0.05,
		string(round(alarm_get(0)/game_get_speed(gamespeed_fps))),
		0,
		global.gui_height * 0.1,
		global.gui_height/1080,
		global.gui_height/1080,
		0,
		c_white, c_white, global.team_colors[global.current_team], global.team_colors[global.current_team],
		1);
}
draw_set_font(fnt_default);
draw_set_halign(fa_left);
}