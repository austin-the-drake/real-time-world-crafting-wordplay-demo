/// @description zoom out

if my_turn and not currently_typing {
	if global.camera_zoom < 1.5 {
		global.camera_zoom *= 1.1;
	}
}