/// @description Collide
swimming = true;
if abs(vspeed < 1) {
	vspeed += 0.5-vspeed / 10;
}
alarm_set(0, 2);
