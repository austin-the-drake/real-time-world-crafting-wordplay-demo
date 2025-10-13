/// @description Draw self

cooldown -= 1;

status_effect_blink = max(0, lengthdir_x(3, anim_bob / 2) - 2);
image_blend = make_color_rgb(
	lerp(255, color_get_red(status_color), status_effect_blink),
	lerp(255, color_get_green(status_color), status_effect_blink),
	lerp(255, color_get_blue(status_color), status_effect_blink)
)

var idle_y = lengthdir_y(1, anim_bob + xstart);
var idle_x = lengthdir_x(1, anim_bob + xstart);

var swing_x = lengthdir_x(speed * 2.5 * walk_anim_influence, anim_bob * 2 + xstart);
var swing_y = lengthdir_y(speed * 2.5 * walk_anim_influence, anim_bob * 4 + xstart);

var bob_y = lengthdir_y(speed * walk_anim_influence, anim_bob * 4 + xstart);

var ang = 90 + (-90 * facing) + (aim_angle * facing);
if ready_to_cast {
	for (var i = round(aim_power*4); i>0;i--) {
		draw_set_color(make_color_hsv(43-(i*5), 255, 255));
		draw_circle(x + lengthdir_x(i * 25, ang+lengthdir_x(5, anim_bob*5+i*120)), y + lengthdir_y(i * 25, ang+lengthdir_y(5, anim_bob*5+i*120)), 10 + i * 10, false);
	}
	draw_set_color(c_white);
}

draw_sprite_ext(spr_weapons, wep, x + (32 * facing) + idle_x + swing_x, y + 8 - idle_y - swing_y, 0.5, 0.5, facing * -20 + idle_y * 5 + (min(0, vspeed * (1-walk_anim_influence)) * 5 * facing), c_white, 1);
draw_sprite_ext(hand_spr, image_index, x + (32 * facing) + idle_x + swing_x, y + 8 - idle_y - swing_y, 0.5, 0.5, 0, image_blend, 1);
draw_sprite_ext(sprite_index, image_index, x, y - bob_y - (speed), 0.5 * facing, 0.5, facing * aim_angle / 3, image_blend, 1);
draw_sprite_ext(hand_spr, image_index, x - (32 * facing) - idle_y - swing_x, y + 8 + idle_x - swing_y, 0.5, 0.5, 0, image_blend, 1);
if my_team == 0 {
	draw_sprite_ext(spr_helmets_round, hat, x, y - bob_y - (speed), 0.5 * facing, 0.5, idle_x * 2 + (facing*aim_angle/3), c_white, 1);
} else {
	draw_sprite_ext(spr_helmets_square, hat, x, y - bob_y - (speed), 0.5 * facing, 0.5, idle_x * 2 + (facing*aim_angle/3), c_white, 1);
}


if draw_stats {
	draw_set_color(c_black);
	draw_set_halign(fa_center);
	draw_set_valign(fa_bottom);
	var str = "Health: " + string(round(life)) + "/100\n";
	for (var j=0;j<array_length(armor_elements);j++) {
		str += armor_elements[j] + " armor\n";
	}
	draw_text(x, y-64, str);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_color(c_white);
}