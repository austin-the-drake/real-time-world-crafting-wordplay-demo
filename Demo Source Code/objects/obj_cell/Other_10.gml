/// @description Cellular automata update
// This routine runs once for each live cell

// If there are too many live cells, randomly delete some
if instance_number(obj_cell) > 256 {
	if random(100) < 10 {
		instance_destroy();
	}
}

if (particle_flags & ca_type_powder) == ca_type_powder {
	
	var collider_down = collision_point(x + 8, y + 8 + 16, [obj_tile, obj_cell], true, true);
	
	var blocked = true;
	var swap = false;
	
	if collider_down == noone {
		blocked = false;
	} else if collider_down.object_index == obj_cell {
		
		var agg = aggregate_elemental_interaction(elements, collider_down.elements, global.elemental_data);
			if agg > 1 {
				var spawn_x = collider_down.x;
				var spawn_y = collider_down.y;
				instance_destroy(collider_down);
				if spreads {
					collider_down = instance_create_layer(spawn_x, spawn_y, layer, obj_cell, {particle_data: particle_data});
				}
			}
		if instance_exists(collider_down) {
			if ((collider_down.particle_flags & ca_type_liquid) == ca_type_liquid) or ((collider_down.particle_flags & ca_type_gas) == ca_type_gas) {
				blocked = false;
				swap = true;
			}
		}
	}
	
	if not blocked {
		// Free to fall down or swap down
		if swap {
			collider_down.y = y;
		}
		y += 16;
	} else {
		var dir = choose(-1, 1);
		var collider_diag = collision_point(x + 8 + (16 * dir), y + 8 + 16, [obj_tile, obj_cell], true, true);
		
		blocked = true;
		swap = false;
	
		if collider_diag == noone {
			blocked = false;
		} else if collider_diag.object_index == obj_cell {
			
			var agg = aggregate_elemental_interaction(elements, collider_diag.elements, global.elemental_data);
				if agg > 1 {
					var spawn_x = collider_diag.x;
					var spawn_y = collider_diag.y;
					instance_destroy(collider_diag);
					if spreads {
						collider_diag = instance_create_layer(spawn_x, spawn_y, layer, obj_cell, {particle_data: particle_data});
					}
				}
			if instance_exists(collider_diag) {
				if ((collider_diag.particle_flags & ca_type_liquid) == ca_type_liquid) or ((collider_diag.particle_flags & ca_type_gas) == ca_type_gas) {
					blocked = false;
					swap = true;
				}
			}
		}
		
		if not blocked {
			// Free to fall or swap diagonally
			if swap {
				collider_diag.x = x;
				collider_diag.y = y;
			}
			x += dir * 16;
			y += 16;
		}
	}
} else if (particle_flags & ca_type_liquid) == ca_type_liquid {
	
	var collider_down = collision_point(x + 8, y + 8 + 16, [obj_tile, obj_cell], true, true);
	
	var blocked = true;
	var swap = false;
	
	if collider_down == noone {
		blocked = false;
	} else if collider_down.object_index == obj_cell {
		
		var agg = aggregate_elemental_interaction(elements, collider_down.elements, global.elemental_data);
			if agg > 1 {
				var spawn_x = collider_down.x;
				var spawn_y = collider_down.y;
				instance_destroy(collider_down);
				if spreads {
					collider_down = instance_create_layer(spawn_x, spawn_y, layer, obj_cell, {particle_data: particle_data});
				}
			}
		if instance_exists(collider_down) {
			if ((collider_down.particle_flags & ca_type_gas) == ca_type_gas) {
				blocked = false;
				swap = true;
			} else if ((collider_down.particle_flags & ca_type_liquid) == ca_type_liquid) and (density > collider_down.density) {
				blocked = false;
				swap = true;
			}
		}
	}
	
	if not blocked {
		// Free to fall down or swap down
		if swap {
			collider_down.y = y;
		}
		y += 16;
	} else {
		var dir = choose(-1, 1);
		if viscous and random(100) < 67 {
			dir = 0;
		}
		var collider_side = collision_point(x + 8 + (16 * dir), y + 8, [obj_tile, obj_cell], true, true);
		
		blocked = true;
		swap = false;
	
		if collider_side == noone {
			blocked = false;
		} else if collider_side.object_index == obj_cell {
			
			var agg = aggregate_elemental_interaction(elements, collider_side.elements, global.elemental_data);
				if agg > 1 {
					var spawn_x = collider_side.x;
					var spawn_y = collider_side.y;
					instance_destroy(collider_side);
					if spreads {
						collider_side = instance_create_layer(spawn_x, spawn_y, layer, obj_cell, {particle_data: particle_data});
					}
				}
			if instance_exists(collider_side) {
				if ((collider_side.particle_flags & ca_type_gas) == ca_type_gas) {
					blocked = false;
					swap = true;
				} else if ((collider_side.particle_flags & ca_type_liquid) == ca_type_liquid) and (density > collider_side.density) {
					blocked = false;
					swap = true;
				}
			}
		}
		
		if not blocked {
			// Free to fall or swap to the side
			if swap {
				collider_side.x = x;
			}
			x += dir * 16;
		}
	}
} else if (particle_flags & ca_type_gas) == ca_type_gas {
	
	var dir_x = choose(-1, 0, 1);
	var dir_y = choose(-1, 0, 1);
	
	if density > 1 and random(100) < 15 {
		dir_y = 1;
	}
	
	if density < 1 and random(100) < 15 {
		dir_y = -1;
	}
	
	var collider_any = collision_point(x + 8 + 16 * dir_x, y + 8 + 16 * dir_y, [obj_tile, obj_cell], true, true);
	
	var blocked = true;
	var swap = false;
	 
	if collider_any == noone {
		blocked  = false;
	} else if collider_any.object_index == obj_cell {
		
		var agg = aggregate_elemental_interaction(elements, collider_any.elements, global.elemental_data);
			if agg > 1 {
				var spawn_x = collider_any.x;
				var spawn_y = collider_any.y;
				instance_destroy(collider_any);
				if spreads {
					collider_any = instance_create_layer(spawn_x, spawn_y, layer, obj_cell, {particle_data: particle_data});
				}
			}
		if instance_exists(collider_any) {
			if (collider_any.particle_flags & ca_type_gas) == ca_type_gas {
				// Allow gas to freely diffuse into each other
				blocked = false;
				swap = true;
			}
		}
	}
	
	if collider_any == noone {
		// Free to move in the chosen direction
		if swap {
			collider_any.x = x;
			collider_any.y = y;
		}
		
		x += 16 * dir_x;
		y += 16 * dir_y;
	}
}