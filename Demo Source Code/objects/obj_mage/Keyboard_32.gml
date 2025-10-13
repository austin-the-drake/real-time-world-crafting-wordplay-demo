/// @description Aiming

if ready_to_cast and not global.paused {
	aim_angle += keyboard_check(vk_up) - keyboard_check(vk_down);
	aim_angle = clamp(aim_angle, -90, 90);
	aim_power = 1 - lengthdir_x(0.5, anim_bob);
}