/// @description Physics systems

// Destroy if outside bounds
if x<-room_width or x>room_width*2 or y<-room_height or y>room_height*2 {
	instance_destroy();
}

// Homing behavior system
if variable_instance_exists(self, "homing") {
	if instance_exists(obj_mage_square) and team == 0 {
		var target = instance_nearest(x, y, obj_mage_square);
		var dir = point_direction(x, y, target.x, target.y);
		motion_add(dir, homing);
	} else 	if instance_exists(obj_mage_round) and team == 1 {
		var target = instance_nearest(x, y, obj_mage_round);
		var dir = point_direction(x, y, target.x, target.y);
		motion_add(dir, homing);
	}
}

// Boomerange behavior system
if variable_instance_exists(self, "boomerang") {
	if instance_exists(caster) {
		var dir = point_direction(x, y, caster.x, caster.y);
		motion_add(dir, boomerang);
	}
}

// Wall-crawling behavior system
if spell_class == "wallCrawl" {
	if orientation != 0 {
		if place_free(x + lengthdir_x(speed, direction + 90 * orientation), y + lengthdir_y(speed, direction + 90 * orientation)) {
			direction += orientation * 2 * speed;
		}
	}
}

// Controllable behavior system
if variable_instance_exists(self, "controllable") {
	if global.mana[team] - control_cost > 0 and controllable == true {
		var dist = point_distance(0, 0, keyboard_check(vk_right) - keyboard_check(vk_left), keyboard_check(vk_down) - keyboard_check(vk_up));
		if dist > 0 {
			var dir = point_direction(0, 0, keyboard_check(vk_right) - keyboard_check(vk_left), keyboard_check(vk_down) - keyboard_check(vk_up));
			var spd = max(0.1, speed / 10);
			motion_add(dir, spd);
			speed = min(max_speed, speed);
			xprevious=x+lengthdir_x(max(spd*10, max_speed), dir);
			yprevious=y+lengthdir_y(max(spd*10, max_speed), dir);
			x = xprevious;
			y = yprevious;
			
			
			global.mana[team] -= control_cost;
		}
	}
}

// Button press behavior system
if keyboard_check_pressed(vk_space) and team = global.current_team {
	if variable_instance_exists(self, "button_payload") {
		event_perform(ev_other, ev_user0);
	}
}

// Make the camera follow
if variable_instance_exists(self, "take_camera_control") {
	if spell_class != "aoe" and spell_class != "shield" {
		global.camera_focus_x += ((x)-global.camera_focus_x) / 30;
		global.camera_focus_y += ((y)-global.camera_focus_y) / 30;
	}
}