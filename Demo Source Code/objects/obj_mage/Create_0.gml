/// @description Init

// Player variables
spell_string = "";
cooldown = 10;
currently_typing = false;
life = 100;
spawning = true;
alarm_set(1, 180);
draw_stats = false;
startlife = 100;
aim_sound = noone;
status_color = c_white;
anim_bob = 0;
turn_mode = 0;
num_elemental_charges = 1;
status_effect_blink = 0;
swimming = false;
waiting_for_response = false;
facing = 1;
hat = irandom(5);
wep = irandom(5);
friction = 0.1;
ready_to_cast = false;
aim_angle = 0;
aim_power = 0;
walk_anim_influence = 0;
jump_anim_influence = 0;
history_scroll = 0;
armor_elements = [global.elemental_data.elements[irandom(8)]];
passive_damage_this_turn = {};

// Default fallback spell
spell_data = {
	components: [
	{componentType: "projectile", radius: 10, speed: 15, gravity: 0.25},
	{componentType: "element", element: "wind"},
	{componentType: "controllable", mana_cost: 0.25},
	{componentType: "color", rgb: [255, 255, 255]},
	{componentType: "impactTrigger", replace: true, reps: 999, secs: 0.1, loop: true, payload_components: [
		{componentType: "manifestation", radius: 3, material_properties: {
			class: "powder",
			color_rgb: [255, 224, 180],
			solid: 1,
			density: 1
			}}
		]}
	]
}

if my_team == 0 {
	switch(global.team_colors[my_team]) {
	
		default: show_debug_message("Invalid team+color combo"); break;
	
		case happy_red: {sprite_index = spr_mage_round_red; hand_spr = spr_hand_red;} break;
		case grumpy_blue: {sprite_index = spr_mage_round_blue; hand_spr = spr_hand_blue;} break;
		case dull_yellow: {sprite_index = spr_mage_round_yellow; hand_spr = spr_hand_yellow;} break;
		case wonder_green: {sprite_index = spr_mage_round_green; hand_spr = spr_hand_green;} break;
	}
} else {
	switch(global.team_colors[my_team]) {
	
		default: show_debug_message("Invalid team+color combo"); break;
	
		case happy_red: {sprite_index = spr_mage_square_red; hand_spr = spr_hand_red;} break;
		case grumpy_blue: {sprite_index = spr_mage_square_blue; hand_spr = spr_hand_blue;} break;
		case dull_yellow: {sprite_index = spr_mage_square_yellow; hand_spr = spr_hand_yellow;} break;
		case wonder_green: {sprite_index = spr_mage_square_green; hand_spr = spr_hand_green;} break;
	}
}
mask_index = spr_mage_hitbox;