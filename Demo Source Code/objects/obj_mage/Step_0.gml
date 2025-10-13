/// @description Movement

anim_bob += 5;

if not keyboard_check(vk_space) and not keyboard_check_released(vk_space) {
	aim_angle += -aim_angle / 20;
}

if my_turn and not global.paused {
	if not currently_typing {
		if vspeed == 0 {
			hspeed += (keyboard_check(vk_right) - keyboard_check(vk_left)) * 0.5;
			hspeed = clamp(hspeed, -2.5, 2.5);
		} else {
			hspeed += (keyboard_check(vk_right) - keyboard_check(vk_left)) * 0.1;
			hspeed = clamp(hspeed, -2.5, 2.5);
		}
	
		if keyboard_check_released(vk_enter) {
			currently_typing = true;
			turn_mode = 0;
			ready_to_cast = false;
			history_scroll = 0;
			keyboard_string = "";
		}
	} else {
		
		if mouse_wheel_up() history_scroll--;
		if mouse_wheel_down() history_scroll++;
		
		if keyboard_check_released(vk_enter) and not waiting_for_response {
			if keyboard_string == "" {
				currently_typing = false;
			} else {
				waiting_for_response = true;
				audio_play_sound(snd_make_request, 1, false, 0.5);
				if turn_mode == 0 {
					event_perform(ev_other, ev_user0);
				} else {
					event_perform(ev_other, ev_user3);
				}
				keyboard_string = "";
			}
		}
		if keyboard_check_pressed(ord("V")) and keyboard_check(vk_control) and not waiting_for_response and clipboard_has_text() {
			currently_typing = false;
			ready_to_cast = true;
			audio_play_sound(snd_spell_recieved, 1, false, 0.5);
			spell_data = json_parse(clipboard_get_text());
			keyboard_string = "";
		}
	}
	
	global.camera_focus_x += ((x + (facing * 64))-global.camera_focus_x) / 20;
	global.camera_focus_y += ((y)-global.camera_focus_y) / 50;
	
}

if place_free(x, y + 1) {
	gravity = 0.25;
	friction = 0;
	walk_anim_influence += (-walk_anim_influence) / 10;
	if (keyboard_check_pressed(vk_up) or keyboard_check_pressed(vk_shift)) and (not currently_typing) and my_turn and (not keyboard_check(vk_space)) and swimming {
		audio_play_sound(snd_jump, 1, false, 0.5);
		vspeed = -8;
	}
} else {
	gravity = 0;
	vspeed = 0;
	walk_anim_influence += (1-walk_anim_influence) / 10;
	friction = 0.1;
	if (keyboard_check_pressed(vk_up) or keyboard_check_pressed(vk_shift)) and (not currently_typing) and my_turn and (not keyboard_check(vk_space)) {
		audio_play_sound(snd_jump, 1, false, 0.5);
		vspeed = -8;
	}
}

if swimming {
	if place_free(x, y - 1) {
		y -= 1;
	}
	vspeed -= gravity * 1.5;
	friction = 0.1;
}

if hspeed > 0.1 and keyboard_check(vk_right) facing = 1;
if hspeed < -0.1 and keyboard_check(vk_left) facing = -1;

if spawning {
	x = xstart;
	hspeed = 0;
}

vspeed = clamp(vspeed, -15, 15);

if y > room_height {
	if spawning {
		alarm_set(1, 180);
		y = 0;
		randomize();
		xstart = random(room_width);
		x = xstart;
	} else {
		instance_destroy();
	}
}

if my_turn and waiting_for_response and not global.paused {
	obj_controller.alarm[0]++;
	obj_controller.alarm[3] = 2;
}
