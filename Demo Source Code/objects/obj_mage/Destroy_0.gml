/// @description Clear self from turn queue
if my_turn {
	with(obj_controller) {
		alarm_set(0, 3 * game_get_speed(gamespeed_fps)); 
	}
}

if my_team == 0 {
	if array_contains(global.round_team_fifo, id) {
		array_delete(global.round_team_fifo, array_get_index(global.round_team_fifo, id), 1);
	}
} else {
	if array_contains(global.square_team_fifo, id) {
		array_delete(global.square_team_fifo, array_get_index(global.square_team_fifo, id), 1);
	}
}