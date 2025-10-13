/// @description Collide

if other.solid {
	if abs(speed) > 0 {
		move_contact_solid(direction, min(abs(speed), 2));
	} else {
		y -= 1;
		yprevious -= 1;
	}
	var vspeed_pre_bounce = vspeed;
	move_bounce_solid(true);
	if vspeed_pre_bounce > 0 {
		vspeed = min(0, vspeed);
	}
}

if (other.particle_flags & ca_type_liquid) == ca_type_liquid and other.y < y {
	swimming = true;
	alarm_set(0, 2);
}

var agg = aggregate_elemental_interaction(other.elements, armor_elements, global.elemental_data);
var preexisting_damage = safe_set_attribute(passive_damage_this_turn, other.elements[0], 0);
var dmg = max(other.harmful * 25, agg * 25, preexisting_damage);
variable_struct_set(passive_damage_this_turn, other.elements[0], dmg);
if dmg > 1 {
	var col = variable_struct_get(global.elemental_data, other.elements[0]).RGB_COLOR;
	status_color = make_color_rgb(col[0], col[1], col[2]);
}