/// @description Spell parser
// This is a recursive routine, called once for each sub-spell

// Keep variables for assigned magical elements and main spell class
elements = [];
spell_class = noone;
if not variable_instance_exists(self, "aim_power") {
	aim_power = 1;
}

// Read every component at the current nesting level
for (var i=0; i<array_length(spell_data.components); i++) {
	var component = spell_data.components[i]
	switch (component.componentType) {
		default: {show_debug_message("unknown component type encountered: " + string(component.componentType))} break;
		
		case "manaCost": {
			if global.mana[team] - component.cost >= 0 {
				global.mana[team] -= component.cost;
			} else {
				instance_destroy(self, false);
			}
			
		} break;
		
		case "teleportCaster": {
			spell_class = "teleportCaster";
			// Have to wait for potential cancellation if mana too low
			alarm_set(2, 1);
		} break;
		
		case "buffCaster": {
			spell_class = "buffCaster";
			// Have to wait for potential cancellation if mana too low
			heal_amount = safe_set_attribute(component, "heal", 0);
			resist_to = safe_set_attribute(component, "resist", noone);
			alarm_set(5, 1);
		} break;
		
		case "manifestation": {
			spell_class = "manifestation";
			// Have to wait for potential cancellation if mana too low
			manifestation_data = component.material_properties;
			manifestation_radius = component.radius;
			alarm_set(3, 1);
		} break;
		
		case "projectile": {
			spell_class = "projectile";
			projectile_radius = safe_set_attribute(component, "radius", 10);
			image_xscale = (projectile_radius / 16) * 2;
			image_yscale = (projectile_radius / 16) * 2;
			bounces = safe_set_attribute(component, "bounces", 0);
			speed = safe_set_attribute(component, "speed", 10) * aim_power;
			gravity = safe_set_attribute(component, "gravity", 0.25);
			if variable_instance_exists(self, "take_camera_control") {
				alarm_set(6, 1);
			}
		} break;
		
		case "aoe": {
			spell_class = "aoe";
			aoe_radius = safe_set_attribute(component, "radius", 64);
			image_xscale = (aoe_radius / 16) * 2;
			image_yscale = (aoe_radius / 16) * 2;
			friction = 0.1;
			//alarm_set(1, max(safe_set_attribute(component, "secs", 5) * game_get_speed(gamespeed_fps), 1));
			turns_left = max(safe_set_attribute(component, "turns", 1), 1);
			alarm_set(6, 1);
		} break;
		
		case "shield": {
			spell_class = "shield";
			shield_radius = safe_set_attribute(component, "radius", 64);
			image_xscale = (shield_radius / 16) * 2;
			image_yscale = (shield_radius / 16) * 2;
			friction = 0.1;
			//alarm_set(1, max(safe_set_attribute(component, "secs", 5) * game_get_speed(gamespeed_fps), 1));
			audio_play_sound(snd_shield_up, 1, false);
			turns_left = max(safe_set_attribute(component, "turns", 1), 1);
		} break;
		
		case "explosion": {
			spell_class = "explosion";
			explosion_radius = safe_set_attribute(component, "radius", 64);
			image_xscale = (explosion_radius / 16) * 2;
			image_yscale = (explosion_radius / 16) * 2;
			with(obj_controller) {
				event_perform(ev_other, ev_user0);
			}
			alarm_set(1, 0.1 * game_get_speed(gamespeed_fps));
		} break;
		
		case "wallCrawl": {
			spell_class = "wallCrawl";
			projectile_radius = safe_set_attribute(component, "radius", 10);
			image_xscale = (projectile_radius / 16) * 2;
			image_yscale = (projectile_radius / 16) * 2;
			speed = safe_set_attribute(component, "speed", 10) * aim_power;
			gravity = safe_set_attribute(component, "gravity", 0.25);
			orientation = 0;
			if variable_instance_exists(self, "take_camera_control") {
				alarm_set(6, 1);
			}
		} break;
		
		case "element": {
			array_push(elements, safe_set_attribute(component, "element", "neutral"));
		} break;
		
		case "color": {
			var col = safe_set_attribute(component, "rgb", [255, 255, 255]);
			color = make_color_rgb(col[0], col[1], col[2]);
		} break;
		
		case "homing": {
			homing = safe_set_attribute(component, "strength", 0.1);
		} break;
		
		case "controllable": {
			controllable = true;
			control_cost = safe_set_attribute(component, "mana_cost", 0.25);
		} break;
		
		case "boomerang": {
			boomerang = safe_set_attribute(component, "strength", 0.1);
		} break;
		
		case "spawnAngle": {
			direction = component.angle;
		} break;
		
		case "spawnRandAngle": {
			direction = random(360);
		} break;
		
		case "timerTrigger": {
			alarm_duration = safe_set_attribute(component, "secs", 1) * game_get_speed(gamespeed_fps);
			alarm_set(0, alarm_duration);
			alarm_replace = safe_set_attribute(component, "replace", false);
			alarm_count = safe_set_attribute(component, "count", 1);
			alarm_payload = component.payload_components;
			alarm_loop = safe_set_attribute(component, "loop", false);
			if alarm_loop {
				alarm_replace = false;
			}
			alarm_reps = safe_set_attribute(component, "reps", 999);
			if alarm_reps != 999 {
				replace = false;
			}
		} break;
		
		case "impactTrigger": {
			impact_replace = safe_set_attribute(component, "replace", false);
			impact_count = safe_set_attribute(component, "count", 1);
			impact_payload = component.payload_components;
			impact_reps = safe_set_attribute(component, "reps", 1);
		} break;
		
		case "deathTrigger": {
			death_count = safe_set_attribute(component, "count", 1);
			death_payload = component.payload_components;
		} break;
		
		case "buttonTrigger": {
			button_replace = safe_set_attribute(component, "replace", false);
			button_count = safe_set_attribute(component, "count", 1);
			button_payload = component.payload_components;
			button_reps = safe_set_attribute(component, "reps", 1);
		} break;
	}
}

if array_length(elements) == 0 {
	array_push(elements, "neutral");
}

if (random(100) < 50) or (not variable_instance_exists(self, "color")) {
	color = make_color_rgb(
		variable_struct_get(global.elemental_data, elements[0]).RGB_COLOR[0],
		variable_struct_get(global.elemental_data, elements[0]).RGB_COLOR[1],
		variable_struct_get(global.elemental_data, elements[0]).RGB_COLOR[2]);
}

max_speed = max(speed, 10);
// max lifespan
if (spell_class != "aoe") and (spell_class != "shield") {
	alarm_set(4, 10 * game_get_speed(gamespeed_fps));
}