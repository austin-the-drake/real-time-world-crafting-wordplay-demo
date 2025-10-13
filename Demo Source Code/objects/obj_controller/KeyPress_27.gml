/// @description Pause the game

// Ensure that we are not attempting to pause during a critical moment
var something_in_progress = false;
for (var i=0; i<instance_number(obj_mage); i++) {
	var inst = instance_find(obj_mage, i);
	if inst.waiting_for_response or (inst.ready_to_cast and keyboard_check(vk_space)) {
		something_in_progress = true;
	}
}

// Create a pause menu panel, and toggle the global pause flag
if not global.paused and not something_in_progress {
	instance_create_depth(room_width/2, room_height/2, -100, obj_menu_panel_pause);
	global.paused = true;
}