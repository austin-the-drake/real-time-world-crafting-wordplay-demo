/// @description Delayed action

switch(action) {
	default: {
		show_debug_message("Undefined action");
	} break;
	case "quit": {
		game_end();
	} break;
	case "battle": {
		room_goto(rm_battle);
	} break;
	case "alchemy": {
		room_goto(rm_alchemy);
	} break;
}