/// @description parallax

var cam = view_get_camera(0);
xstart -= 2 / parallax_depth;
if xstart < -room_width {
	xstart += room_width * 3;
	image_index = choose(0, 1);
	if room == rm_alchemy {
		ystart = random(room_height);
	}
	//parallax_depth = random_range(2, 5);
}
x = xstart + ((camera_get_view_x(cam)+camera_get_view_width(cam)-xstart) / parallax_depth);
y = ystart + ((camera_get_view_y(cam)+camera_get_view_height(cam)-ystart) / parallax_depth);