/// @description Swap teams

// Return music to full volume if silenced during a turn
audio_sound_gain(global.music_ref, 1.0, 3000);

// Swap teams
global.current_team = not global.current_team;

// Replenish mana for all teams
global.mana[global.current_team] = min(100, global.mana[global.current_team] + 25);

with(obj_spell) {
	// Stop any spells from exerting control over the camera during a turn change
	if variable_instance_exists(self, "take_camera_control") {
		take_camera_control = false;
	}
	// Remove player control of any controllable spells after a turn ends
	if variable_instance_exists(self, "controllable") {
		controllable = false;
	}
	// Increment turn counters where applicable
	if spell_class == "aoe" or spell_class == "shield" {
		event_perform(ev_other, ev_user1);
	}
}

// Ensure no mages think it's their turn, and ask them to apply any accumulated damage now
with(obj_mage) {
	my_turn = false;
	event_perform(ev_other, ev_user2);
}

// Check which team we're turning to
if global.current_team == 0 {
	
	// Attempt to find live mages on this team, end game if unsuccessful
	while(true) {
		if array_length(global.round_team_fifo) == 0 {
			show_debug_message("No players remain on the round team!");
			global.winner = "square";
			global.camera_focus_x = room_width / 2;
			global.camera_focus_y = room_height / 2;
			global.camera_zoom = 1;
			instance_create_depth(room_width/2, room_height/2, -100, obj_menu_panel_endofgame);
			exit;
		}
		
		// Turn to next mage in line
		up_next = array_pop(global.round_team_fifo);
		
		if instance_exists(up_next) {
			break;
		}
	}
	
	// Tell the mage to begin their turn
	array_insert(global.round_team_fifo, 0, up_next);
	up_next.my_turn = true;
	
} else if global.current_team == 1 {
	
	// Attempt to find live mages on this team, end game if unsuccessful
	while(true) {
		if array_length(global.square_team_fifo) == 0 {
			show_debug_message("No players remain on the square team!");
			global.winner = "round";
			global.camera_focus_x = room_width / 2;
			global.camera_focus_y = room_height / 2;
			global.camera_zoom = 1;
			instance_create_depth(room_width/2, room_height/2, -100, obj_menu_panel_endofgame);
			exit;
		}
		
		// Turn to next mage in line
		up_next = array_pop(global.square_team_fifo);
		
		if instance_exists(up_next) {
			break;
		}
	}
	
	// Tell the mage to begin their turn
	array_insert(global.square_team_fifo, 0, up_next);
	up_next.my_turn = true;
}

// Reset countdown timer, or hold steady if the game is over
if not instance_exists(obj_menu_panel_endofgame) {
	if array_length(global.square_team_fifo) == 0 or array_length(global.round_team_fifo) == 0 {
		alarm_set(0, 1);
	} else {
		alarm_set(0, 99 * game_get_speed(gamespeed_fps));
	}
} else {
	alarm_set(0, -1);
}