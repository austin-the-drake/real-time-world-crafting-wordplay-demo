/// @description Collide

if vspeed > 0 {
	if not audio_is_playing(snd_landing) {
		audio_play_sound(snd_landing, 1, false);
		part_particles_create_color(global.partsys, x, y+32, global.part_gas, c_ltgray, 3);
	}
}

if abs(speed) <0.1 {
	y -= 1;
	yprevious -= 1;
}

if not swimming {
	move_contact_solid(direction, 8);
}
var vspeed_pre_bounce = vspeed;
move_bounce_solid(true);
if not swimming {
	if vspeed_pre_bounce > 0 {
		vspeed = 0;
	}
	//vspeed = min(0, vspeed);
} else {
	vspeed = clamp(vspeed, -1, 1);
}