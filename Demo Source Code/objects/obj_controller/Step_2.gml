/// @description Camera behavior

// Gravitational mechanics for a screen shake effect
gravity = clamp(point_distance(x, y, 0, 0), -2, 2);
friction = 0.3;
gravity_direction = point_direction(x, y, 0, 0);

// Pause menu camera control
if global.paused {
	global.camera_focus_x = room_width/2;
	global.camera_focus_y = room_height/2;
	global.camera_zoom = 1;
	alarm[3] = 5;
	alarm[0]++;
}

// Smoothly move the camera every frame
global.camera_focus_x = clamp(global.camera_focus_x, 0, room_width);
global.camera_focus_y = clamp(global.camera_focus_y, -room_height, room_height);
var cam = view_get_camera(0);
camera_set_view_size(cam, 1920*global.camera_zoom, 1080*global.camera_zoom);
camera_set_view_pos(cam, global.camera_focus_x-(960*global.camera_zoom)+x, global.camera_focus_y-(540*global.camera_zoom)+y);

//camera_apply(0);