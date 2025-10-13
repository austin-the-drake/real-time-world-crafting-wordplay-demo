/// @description Explosion or aoe damage

if other.spell_class == "explosion" {
	if array_length(other.elements) > 0 {
		var agg = aggregate_elemental_interaction(other.elements, armor_elements, global.elemental_data);
		var preexisting_damage = safe_set_attribute(passive_damage_this_turn, other.elements[0], 0);
		var dmg = max((1 + agg) * 50, preexisting_damage);
		variable_struct_set(passive_damage_this_turn, other.elements[0], dmg);
		if dmg > 1 {
			var col = variable_struct_get(global.elemental_data, other.elements[0]).RGB_COLOR;
			status_color = make_color_rgb(col[0], col[1], col[2]);
		}
	}
	motion_set(point_direction(other.x, max(other.y, y), x, min(other.y, y)), 10); 
}

if other.spell_class == "aoe" {
	if array_length(other.elements) > 0 {
		var agg = aggregate_elemental_interaction(other.elements, armor_elements, global.elemental_data);
		var preexisting_damage = safe_set_attribute(passive_damage_this_turn, other.elements[0], 0);
		var dmg = max((1 + agg) * 25, preexisting_damage);
		variable_struct_set(passive_damage_this_turn, other.elements[0], dmg);
		if dmg > 1 {
			var col = variable_struct_get(global.elemental_data, other.elements[0]).RGB_COLOR;
			status_color = make_color_rgb(col[0], col[1], col[2]);
		}
	}
}
