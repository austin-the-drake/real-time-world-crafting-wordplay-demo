/// @description Init

// Resize window as necessary
if os_browser == browser_not_a_browser {
	display_set_gui_size(window_get_width(), window_get_height());
	global.gui_width = display_get_gui_width();
	global.gui_height = display_get_gui_height();
	view_set_wport(0, global.gui_width);
	view_set_hport(0, global.gui_height);
	surface_resize(application_surface, global.gui_width, global.gui_height);
} else {
	display_set_gui_size(1280, 720);
	global.gui_width = 1280;
	global.gui_height = 720;
	view_set_wport(0, global.gui_width);
	view_set_hport(0, global.gui_height);
	surface_resize(application_surface, global.gui_width, global.gui_height);
}

// Global variables
fade = 1;
fade_target = 0;
canvas_offset = 24;
global.selected_element = noone;
global.newly_generated_behavior = undefined;
global.latest_element_name = "_5";
global.last_user_prompt = "";
global.existing_elements_json_string = "";

// Instantiate LLM
global.patron = new LLM(global.api, global.key);

// Play the background track and create a reference to it
my_music = audio_play_sound(snd_music_alchemy, 1, true, 0.33, 0);

// Set the random seed
randomize();

// Update rate - currently 24 FPS (like film)
update_fps = 24;
alarm_set(0, max(1, ceil(game_get_speed(gamespeed_fps) / update_fps)));

// Init the world
// rank 3 tensor of size 32 * 32 * 3
// Grid you see is 32 * 32, other dimension consists of type, alpha, and update flag
world_size = 32;
ca_grid = array_create(world_size);
for (var i=0; i<world_size;i++) {
	ca_grid[i] = array_create(world_size);
	for (var j=0; j<world_size; j++) {
		ca_grid[i][j] = ["air", 0, 0];
	}
}

#region Starter behaviors

// Wall and Air have no behavior; they are inert
var inert_behavior = {
    actions: []
};

// Sand
var sand_behavior = {
    actions: [
        // The random mirror handles the choice between falling left or right diagonally
        {
            type: "in_rand_mirror",
            actions: [
                // Try to fall straight down
                {
                    type: "if_neighbor_is",
                    direction: "south",
                    options: ["air", "gas", "water"],
                    actions: [
                        { type: "do_swap", direction: "south" }
                    ],
                    // If blocked, try to roll down one of the two diagonals
                    else_actions: [
                        {
                            type: "if_neighbor_is",
                            direction: "southeast",
                            options: ["air", "gas"],
                            actions: [
                                { type: "do_swap", direction: "southeast" }
                            ]
                        }
                    ]
                }
            ]
        }
    ]
};

// Water
var water_behavior = {
    actions: [
        {
            type: "in_rand_mirror",
            actions: [
                {
                    type: "if_neighbor_is",
                    direction: "south",
                    options: ["air", "gas"], 
                    actions: [ { type: "do_swap", direction: "south" } ],
                    else_actions: [
                        {
                            type: "if_neighbor_is",
                            direction: "southeast",
                            options: ["air", "gas"],
                            actions: [ { type: "do_swap", direction: "southeast" } ],
                            else_actions: [
                                {
                                    type: "if_neighbor_is",
                                    direction: "east",
                                    options: ["air", "gas"],
                                    actions: [ { type: "do_swap", direction: "east" } ]
                                }
                            ]
                        }
                    ]
                }
            ]
        }
    ]
};

// Gas
var gas_behavior = {
    actions: [
        // The rotation wrapper will pick one random direction and try that
        {
            type: "in_rand_rotation",
            actions: [
                // The single action to be attempted
                {
                    type: "if_neighbor_is",
                    direction: "north", // This base direction is just a starting point before rotation
                    options: ["air"],   // Can only move into air
                    actions: [
                        { type: "do_swap", direction: "north" }
                    ]
                }
            ]
        }
    ]
};

// 9 slots for materials - air is permanent and not assigned a slot
ca_types = {
    wall: {
        color: #6A6A6A,
        behavior: inert_behavior
    },
    air: {
        color: #FFFFFF,
        behavior: inert_behavior
    },
    sand: {
        color: #D2B48C,
        behavior: sand_behavior
    },
    water: {
        color: #4169E1,
        behavior: water_behavior
    },
    gas: {
        color: #B2D8B2,
        behavior: gas_behavior
    },
    _5: {
        color: #FFFFFF,
        behavior: inert_behavior
    },
    _6: {
        color: #FFFFFF,
        behavior: inert_behavior
    },
    _7: {
        color: #FFFFFF,
        behavior: inert_behavior
    },
    _8: {
        color: #FFFFFF,
        behavior: inert_behavior
    },
    _9: {
        color: #FFFFFF,
        behavior: inert_behavior
    }
};

#endregion

// Create rendering surfaces
world_surface = surface_create(world_size * 32, world_size * 32);
ca_surface = surface_create(world_size, world_size);

// Helpers for getting the cell index under the mouse cursor
get_mouse_x = function(world_offset_x) {
	return clamp(floor((mouse_x - world_offset_x) / 32), 0, world_size-1);
}
get_mouse_y = function(world_offset_y) {
	return clamp(floor((mouse_y - world_offset_y) / 32), 0, world_size-1);
}

// Function to randomly alter colors a bit for some visual variety
augment_color = function(base, amount) {
	var red = clamp(color_get_red(base) + random_range(-amount, amount), 0, 255);
	var green = clamp(color_get_green(base) + random_range(-amount, amount), 0, 255);
	var blue = clamp(color_get_blue(base) + random_range(-amount, amount), 0, 255);
	return make_color_rgb(red, green, blue);
}

// Function to render a single cell
render_cell = function(ix, iy) {
	var do_tex_swap = bool(surface_get_target() != ca_surface);
	
	if do_tex_swap {
		//show_debug_message("texture swap (rand id: " + string(irandom_range(1000, 10000)) + ")");
		surface_set_target(ca_surface);
		gpu_set_blendenable(false);
	}
	
	draw_set_alpha(clamp(power(ca_grid[ix][iy][1] / 100, 1/2), 0, 1));
	//draw_set_alpha(0);
	draw_set_color(augment_color(variable_struct_get(ca_types, ca_grid[ix][iy][0]).color, 10));
	draw_point(ix, iy);
	
	if do_tex_swap {
		draw_set_color(c_white);
		draw_set_alpha(1);
		gpu_set_blendenable(true);
		surface_reset_target();
	}
}

// Function to set a single cell to a new type
set_cell = function(ix, iy, newtype, newalpha, do_render=true) {
	var to_set = newtype;
	if not array_contains(struct_get_names(ca_types), to_set) {
		newtype = "air";
	}
	if newtype == "air" {
		ca_grid[ix][iy] = [newtype, 0, 0];
	} else {
		ca_grid[ix][iy] = [newtype, newalpha, 0];
	}
	
	if do_render {
		render_cell(ix, iy);
	}
}

// Function to swap two cells with each other
swap_cells = function(source_x, source_y, dest_x, dest_y, do_render=true) {
	var source_data = ca_grid[source_x][source_y];
	var dest_data = ca_grid[dest_x][dest_y];
	set_cell(source_x, source_y, dest_data[0], dest_data[1], do_render);
	set_cell(dest_x, dest_y, source_data[0], source_data[1], do_render);
}

// Helpers to wrap or pad the world array
wrapped = function(coord) {
	return (coord + world_size) % world_size;
}
padded = function(coord) {
	return clamp(coord, 0, world_size - 1);
}

// Function to rotate a given direction in 45-degree steps
rotate = function(current_direction, steps) {
    static directions = [
        "east", "northeast", "north", "northwest",
        "west", "southwest", "south", "southeast"
    ];

	current_index = array_get_index(directions, current_direction);

	if current_index == -1 {
		return current_direction;
	} else {
		var new_index = (current_index + 8 + steps) % 8;
		return directions[new_index];
	}
}

// Function to horizontally mirror a given direction
mirror = function(current_direction) {
	static flip_map_mirror = {
        "north": "north",
        "northeast": "northwest",
        "east": "west",
        "southeast": "southwest",
        "south": "south",
        "southwest": "southeast",
        "west": "east",
        "northwest": "northeast"
    };
	return variable_struct_get(flip_map_mirror, current_direction);
}

// Function to vertically flip a given direction
flip = function(current_direction) {
	static flip_map_flip = {
	    "north": "south",
	    "northeast": "southeast",
	    "east": "east",
	    "southeast": "northeast",
	    "south": "north",
	    "southwest": "northwest",
	    "west": "west",
	    "northwest": "southwest"
	};
	return variable_struct_get(flip_map_flip, current_direction);
}

// Function to get a 2d vector from a direction enum
vec_from_dir = function(dir_str) {
		static mapping = {
	    "north": [0, -1],
	    "northeast": [1, -1],
	    "east": [1, 0],
	    "southeast": [1, 1],
	    "south": [0, 1],
	    "southwest": [-1, 1],
	    "west": [-1, 0],
	    "northwest": [-1, -1]
	};
	return variable_struct_get(mapping, dir_str);
}

// Main recursive DSL interpreter
evaluate = function(ix, iy, act_list, context = undefined) {
    // If no context is provided (top-level call), create a default one.
    if (is_undefined(context)) {
        context = { rotation: 0, mirror: false, flip: false };
    }

    // Helper function to apply all transforms in a consistent order
    static apply_transforms = function(base_dir, ctx) {
        var dir = base_dir;
        if (ctx.mirror) { dir = mirror(dir); } // 1. Apply mirror
        if (ctx.flip)   { dir = flip(dir); }   // 2. Apply flip
        dir = rotate(dir, ctx.rotation);       // 3. Apply rotation
        return dir;
    }
	
	// Step through all actions in the current node
    for (var i = 0; i < array_length(act_list); i++) {
        var action = act_list[i];

        switch (action.type) {
            // WRAPPER / MODIFIER NODES
            case "in_rand_rotation": {
                var new_context = { rotation: context.rotation, mirror: context.mirror, flip: context.flip };
                new_context.rotation += irandom(7);
                if (evaluate(ix, iy, action.actions, new_context)) return true;
            } break;
                
            case "in_rand_mirror": {
                var new_context = { rotation: context.rotation, mirror: context.mirror, flip: context.flip };
                if (random(1) < 0.5) { new_context.mirror = !new_context.mirror; }
                if (evaluate(ix, iy, action.actions, new_context)) return true;
            } break;

            case "in_rand_flip": {
                var new_context = { rotation: context.rotation, mirror: context.mirror, flip: context.flip };
                if (random(1) < 0.5) { new_context.flip = !new_context.flip; }
                if (evaluate(ix, iy, action.actions, new_context)) return true;
            } break;

            // CONDITIONAL NODES
            case "if_neighbor_is":
            case "if_neighbor_is_not": {
                var check_direction = apply_transforms(action.direction, context);
                var vec = vec_from_dir(check_direction);
                var tx = wrapped(ix + vec[0]);
                var ty = wrapped(iy + vec[1]);
                var neighbor_type = ca_grid[tx][ty][0];

                var condition_met = array_contains(action.options, neighbor_type);
                if (action.type == "if_neighbor_is_not") {
                    condition_met = !condition_met;
                }

                if (condition_met) {
                    if (evaluate(ix, iy, action.actions, context)) return true;
                } else {
                    if (variable_struct_exists(action, "else_actions")) {
                        if (evaluate(ix, iy, action.else_actions, context)) return true;
                    }
                }
            } break;
            
            case "if_alpha":
                action.value_index = 1; // Fall-through alias
            case "if_value": {
                var tx = ix, ty = iy;
                if (action.target != "self") {
                    var check_direction = apply_transforms(action.target, context);
                    var vec = vec_from_dir(check_direction);
                    tx = wrapped(ix + vec[0]);
                    ty = wrapped(iy + vec[1]);
                }
                var target_value = ca_grid[tx][ty][action.value_index];
                var condition_met = false;
                
                switch (action.comparison) {
                    case "less_than":    condition_met = (target_value < action.is); break;
                    case "greater_than": condition_met = (target_value > action.is); break;
                    case "equal_to":     condition_met = (target_value == action.is); break;
                    case "not_equal_to": condition_met = (target_value != action.is); break;
                }

                if (condition_met) {
                    if (evaluate(ix, iy, action.actions, context)) return true;
                } else {
                    if (variable_struct_exists(action, "else_actions")) {
                        if (evaluate(ix, iy, action.else_actions, context)) return true;
                    }
                }
            } break;

			case "if_chance": {
				if ((random(100) < action.percent)) {
					if (evaluate(ix, iy, action.actions, context)) return true;
				} else {
					if (variable_struct_exists(action, "else_actions")) {
						if (evaluate(ix, iy, action.else_actions, context)) return true;
					}
				}
			} break;

			case "if_neighbor_count": {
				var neighbor_count = 0;
				for (var j = 0; j < array_length(action.direction_set); j++) {
					var base_direction = action.direction_set[j];
					var check_direction = apply_transforms(base_direction, context);
					var vec = vec_from_dir(check_direction);
					var tx = wrapped(ix + vec[0]);
					var ty = wrapped(iy + vec[1]);
					var neighbor_type = ca_grid[tx][ty][0];
					if (array_contains(action.options, neighbor_type)) {
						neighbor_count++;
					}
				}
				
				var condition_met = false;
				switch (action.comparison) {
					case "less_than":      condition_met = (neighbor_count < action.count); break;
					case "greater_than":   condition_met = (neighbor_count > action.count); break;
					case "equal_to":       condition_met = (neighbor_count == action.count); break;
					case "not_equal_to":   condition_met = (neighbor_count != action.count); break;
				}
				
				if (condition_met) {
					if (evaluate(ix, iy, action.actions, context)) return true;
				} else {
					if (variable_struct_exists(action, "else_actions")) {
						if (evaluate(ix, iy, action.else_actions, context)) return true;
					}
				}
			} break;

            // TERMINAL NODES

            case "do_swap": {
                // Calculate target coordinates
                var swap_direction = apply_transforms(action.direction, context);
                var vec = vec_from_dir(swap_direction);
                var tx = wrapped(ix + vec[0]);
                var ty = wrapped(iy + vec[1]);
                
                // Perform the swap
                swap_cells(ix, iy, tx, ty);
                
                // Check for and execute post-move actions at the NEW coordinates
                if (variable_struct_exists(action, "actions")) {
                    // This new evaluation is for the particle at its new home (tx, ty).
                    // We don't need to check its return value, as the original particle's
                    // turn is over regardless.
                    evaluate(tx, ty, action.actions, context);
                }
                
                // The swap is a terminating action for the original cell (ix, iy).
                return true; 
            } break;

            case "do_set_alpha":
                action.value_index = 1; // Fall-through alias
            case "do_set_value": {
                var tx = ix, ty = iy;
                if (action.target != "self") {
                    var set_direction = apply_transforms(action.target, context);
                    var vec = vec_from_dir(set_direction);
                    tx = wrapped(ix + vec[0]);
                    ty = wrapped(iy + vec[1]);
                }
                switch (action.operation) {
                    case "set":      ca_grid[tx][ty][action.value_index] = action.to; break;
                    case "add":      ca_grid[tx][ty][action.value_index] += action.to; break;
                    case "subtract": ca_grid[tx][ty][action.value_index] -= action.to; break;
                }
				render_cell(tx, ty);
                // NON-TERMINATING
            } break;
            
            case "do_set_type": {
                var tx = ix, ty = iy;
                if (action.target != "self") {
                    var set_direction = apply_transforms(action.target, context);
                    var vec = vec_from_dir(set_direction);
                    tx = wrapped(ix + vec[0]);
                    ty = wrapped(iy + vec[1]);
                }
				set_cell(tx, ty, action.to, 100);
                // NON-TERMINATING
            } break;
            
            case "do_spawn": {
                var spawn_direction = apply_transforms(action.direction, context);
                var vec = vec_from_dir(spawn_direction);
                var tx = wrapped(ix + vec[0]);
                var ty = wrapped(iy + vec[1]);
                var target_type = ca_grid[tx][ty][0];
                
                if (array_contains(action.into_options, target_type)) {
                    ca_grid[tx][ty][0] = action.set_type;
                    if (variable_struct_exists(action, "set_alpha")) {
                        ca_grid[tx][ty][1] = action.set_alpha;
                    } else {
						set_cell(tx, ty, action.set_type, 100);
					}
                    ca_grid[tx][ty][2] = ca_grid[ix][iy][2]; 
                }
				render_cell(tx, ty);
                // NON-TERMINATING
            } break;
            
            case "do_copy_alpha":
				action.dest_index = 1;
				action.source_index = 1; // Fall-through alias
            case "do_copy_value": {
                var source_x = ix, source_y = iy;
                if (action.source_direction != "self") {
                    var source_direction = apply_transforms(action.source_direction, context);
                    var vec = vec_from_dir(source_direction);
                    source_x = wrapped(ix + vec[0]);
                    source_y = wrapped(iy + vec[1]);
                }
                
                var dest_x = ix, dest_y = iy;
                if (action.dest_direction != "self") {
                    var dest_direction = apply_transforms(action.dest_direction, context);
                    var vec = vec_from_dir(dest_direction);
                    dest_x = wrapped(ix + vec[0]);
                    dest_y = wrapped(iy + vec[1]);
                }
                
                var value_to_copy = ca_grid[source_x][source_y][action.source_index];
                ca_grid[dest_x][dest_y][action.dest_index] = value_to_copy;
				render_cell(dest_x, dest_y);
                // NON-TERMINATING
            } break;

            default: {
                show_debug_message("Unknown action type \"" + string(action.type) + "\"");
            } break;
        }
    }
    // If the loop completes without a terminating action, return false.
    return false;
}

// Helper function to produce human-readable text explaining the behavior coded by a script
format_behavior_to_string = function(behavior_struct) {
    if (!is_struct(behavior_struct) || !variable_struct_exists(behavior_struct, "actions")) {
        return "Invalid or empty behavior struct.";
    }

    var result_string = "";
    var stack = [];

    var root_actions = behavior_struct.actions;
    for (var i = array_length(root_actions) - 1; i >= 0; i--) {
        array_push(stack, { node: root_actions[i], indent: 0 });
    }

    static format_options = function(arr) {
        var str = "";
        for (var j = 0; j < array_length(arr); j++) {
            str += string(arr[j]) + (j == array_length(arr) - 1 ? "" : ", ");
        }
        return str;
    }

    while (array_length(stack) > 0) {
        var job = array_pop(stack);
        var action = job.node;
        var indent_level = job.indent;
        var indent = string_repeat("  ", indent_level);

        var line = indent;
        switch (action.type) {
            case "in_rand_rotation": line += "In a random rotation:"; break;
            case "in_rand_mirror":   line += "With a 50% chance of mirroring:"; break;
            case "in_rand_flip":     line += "With a 50% chance of flipping:"; break;
            case "if_chance":        line += "If " + string(action.percent) + "% chance succeeds:"; break;
            case "if_neighbor_is":   line += "If neighbor to the " + action.direction + " is one of [" + format_options(action.options) + "]:"; break;
            case "if_neighbor_is_not": line += "If neighbor to the " + action.direction + " is NOT one of [" + format_options(action.options) + "]:"; break;
            case "if_neighbor_count":
                var op = "";
                switch (action.comparison) { case "equal_to":op="==";break; case "not_equal_to":op="!=";break; case "greater_than":op=">";break; case "less_than":op="<";break; }
                line += "If count of neighbors [" + format_options(action.options) + "] is " + op + " " + string(action.count) + ":";
                break;
            case "if_alpha":
                var op = "";
                switch (action.comparison) { case "equal_to":op="==";break; case "not_equal_to":op="!=";break; case "greater_than":op=">";break; case "less_than":op="<";break; }
                line += "If " + action.target + "'s alpha is " + op + " " + string(action.is) + ":";
                break;
            case "do_set_alpha":
                line += "- " + string_upper(action.operation) + " " + action.target + "'s alpha by " + string(action.to);
                break;
            case "do_copy_alpha":
                line += "- Copy alpha from " + action.source_direction + " to " + action.dest_direction;
                break;
            case "if_value":
                var op = "";
                switch (action.comparison) { case "equal_to":op="==";break; case "not_equal_to":op="!=";break; case "greater_than":op=">";break; case "less_than":op="<";break; }
                line += "If " + action.target + "'s value at index " + string(action.value_index) + " is " + op + " " + string(action.is) + ":";
                break;
            case "do_swap":       line += "- Swap with neighbor to the " + action.direction; break;
            case "do_set_type":   line += "- Set " + action.target + "'s type to '" + action.to + "'"; break;
            case "do_set_value":
                line += "- " + string_upper(action.operation) + " " + action.target + "'s value at index " + string(action.value_index) + " by " + string(action.to);
                break;
            case "do_spawn":      line += "- Spawn '" + action.set_type + "' in direction " + action.direction; break;
            case "do_copy_value":
                line += "- Copy value at index " + string(action.source_index) + " from " + action.source_direction + " to index " + string(action.dest_index) + " at " + action.dest_direction;
                break;
            
            case "__ELSE_MARKER__":
                line += "Else:";
                break;
                
            default: line += "Unknown Action Type: " + action.type; break;
        }
        
        // Don't print a line for the internal marker type
        if (action.type != "__ELSE_MARKER__") {
            result_string += line + "\n";
        } else {
            // But if it IS the marker, just add its formatted line
            result_string += line + "\n";
        }
        
        
        // Recurse by pushing nested actions onto the stack
        // We push children in reverse order of execution
        
        if (variable_struct_exists(action, "else_actions")) {
            var else_job_list = action.else_actions;
            
            // Push the children onto the stack first
            for (var j = array_length(else_job_list) - 1; j >= 0; j--) {
                array_push(stack, { node: else_job_list[j], indent: indent_level + 1 });
            }
            // Thebn push the marker
            array_push(stack, { node: { type: "__ELSE_MARKER__" }, indent: indent_level });
        }
        
        if (variable_struct_exists(action, "actions")) {
            var action_job_list = action.actions;
            for (var j = array_length(action_job_list) - 1; j >= 0; j--) {
                array_push(stack, { node: action_job_list[j], indent: indent_level + 1 });
            }
        }
    }
    
    return result_string;
}

// Function to clean up any dereferenced behavior scripts when the player overwrites a material
garbage_collect_ca_types = function() {
    show_debug_message("--- Running CA Type Garbage Collection ---");

    // Build a list of all types to keep
    var keepers = ["air", "wall"]; 
    
    // Loop through all button instances
    var button_count = instance_number(obj_ca_button);
    for (var i = 0; i < button_count; i++) {
        var button_instance = instance_find(obj_ca_button, i);
        if instance_exists(button_instance) {
			if (!array_contains(keepers, button_instance.name)) and (!array_contains(["pause", "play", "clear", "set /\nenter", "exit"], button_instance.name)){
				array_push(keepers, button_instance.name);
			}
		}
    }

    show_debug_message("Keeper types: " + string(keepers));
    
    
    // Get a list of all types that currently exist
    var all_current_types = variable_struct_get_names(ca_types);
    

    // Compare the lists to find which types to delete
    var types_to_delete = [];
    
    for (var i = 0; i < array_length(all_current_types); i++) {
        var current_type = all_current_types[i];
        
        // If a type in our main list is not in the keepers list, it's garbage
        if (!array_contains(keepers, current_type)) {
            array_push(types_to_delete, current_type);
        }
    }
    
    
    // Delete the garbage
    if (array_length(types_to_delete) == 0) {
        show_debug_message("No unused types to collect.");
        return;
    }

    for (var i = 0; i < array_length(types_to_delete); i++) {
        var name_to_delete = types_to_delete[i];
        variable_struct_remove(ca_types, name_to_delete);
        show_debug_message("Garbage collected unused element: '" + name_to_delete + "'");
    }
    
    show_debug_message("Garbage collection complete");
}

// Function to check the clipboard for a valid element JSON string and add it to ca_types.
import_element_from_clipboard = function() {
    show_debug_message("Attempting to import element from clipboard...");

    // Check if the clipboard contains any text
    if (!clipboard_has_text()) {
        show_debug_message("Clipboard is empty. Nothing to import.");
        return;
    }

    var clipboard_string = clipboard_get_text();
    
    // Clean the raw string to extract the JSON object
    var _cleaned_json_string = clipboard_string;
    var _json_start_pos = string_pos("{", _cleaned_json_string);
    var _json_end_pos = string_last_pos("}", _cleaned_json_string);
    
    if (_json_start_pos > 0 && _json_end_pos > 0) {
        _cleaned_json_string = string_copy(_cleaned_json_string, _json_start_pos, _json_end_pos - _json_start_pos + 1);
    }
    
    show_debug_message("Cleaned JSON content from clipboard: " + _cleaned_json_string);
    
    // Attempt to parse the JSON string
    var _parsed_struct = undefined;
    try {
        _parsed_struct = json_parse(_cleaned_json_string);
    } catch(_exception) {
        show_debug_message("Malformed JSON on clipboard: " + string(_exception));
        return; // Exit the function if parsing fails
    }
    
    // Validate the parsed struct and add the new element
    if (is_struct(_parsed_struct) 
        && variable_struct_exists(_parsed_struct, "name")
        && variable_struct_exists(_parsed_struct, "color_hex")
        && variable_struct_exists(_parsed_struct, "behavior")) {
        
        show_debug_message("Successfully parsed new element from clipboard!");
        
        // Extract the data
        var new_name = _parsed_struct.name;
        // Check the name against reserved words
        if (array_contains(["pause", "play", "clear", "set /\nenter", "exit"], new_name)) {
            new_name += "_";
        }
        var new_color_hex = _parsed_struct.color_hex;
        var new_behavior = _parsed_struct.behavior;
        
        // Helper to convert hex string "#RRGGBB" to a GML color
        static color_from_hex = function(hex) {
            hex = string_replace(hex, "#", "");
            var r = "0x" + string_copy(hex, 1, 2);
            var g = "0x" + string_copy(hex, 3, 2);
            var b = "0x" + string_copy(hex, 5, 2);
            return make_color_rgb(real(r), real(g), real(b));
        }
        
        var new_gml_color = color_from_hex(new_color_hex);
        
        // Create the final struct
        var new_element_data = {
            color: new_gml_color,
            behavior: new_behavior
        };
        
        // Add the new element to the main ca_types struct
        obj_ca_controller.ca_types[$ new_name] = new_element_data;
        global.latest_element_name = new_name;

        // Update the selected UI button to reflect the newly added element
        with(obj_ca_button) {
            if (name == global.selected_element) {
                name = global.latest_element_name;
            }
        }
        global.selected_element = new_name;
        audio_play_sound(snd_spell_recieved, 1, false, 0.5);
        show_debug_message("Added new element '" + new_name + "' from clipboard to ca_types.");
        
    } else {
        show_debug_message("Error: Clipboard JSON is valid, but does not contain the required 'name', 'color_hex', and 'behavior' keys.");
    }
}




example_text = "Example Input: \"A gas that moves randomly, fades over time, and disappears.\"\n" +
"Example Output JSON:\n" +
"```json\n" +
"{\n" +
"\"name\": \"mist\",\n" +
"\"color_hex\": \"#AADDCC\",\n" +
"\"behavior\": {\n" +
"\"actions\": [\n" +
"{\n" +
"\"type\": \"in_rand_rotation\",\n" +
"\"actions\": [\n" +
"{\n" +
"\"type\": \"if_neighbor_is\",\n" +
"\"direction\": \"north\",\n" +
"\"options\": [\"air\"],\n" +
"\"actions\": [\n" +
"{\n" +
"\"type\": \"do_swap\",\n" +
"\"direction\": \"north\",\n" +
"\"actions\": [\n" +
"{\n" +
"\"type\": \"do_set_alpha\",\n" +
"\"target\": \"self\",\n" +
"\"operation\": \"subtract\",\n" +
"\"to\": 10\n" +
"},\n" +
"{\n" +
"\"type\": \"if_alpha\",\n" +
"\"target\": \"self\",\n" +
"\"comparison\": \"less_than\",\n" +
"\"is\": 1,\n" +
"\"actions\": [\n" +
"{\n" +
"\"type\": \"do_set_type\",\n" +
"\"target\": \"self\",\n" +
"\"to\": \"air\"\n" +
"}\n" +
"]\n" +
"}\n" +
"]\n" +
"}\n" +
"]\n" +
"}\n" +
"]\n" +
"}\n" +
"]\n" +
"}\n" +
"}\n" +
"```";



for (i=0; i<10; i++) {
	instance_create_layer(random_range(-room_width, room_width*2), random_range(0, room_height), layer_get_id("BackgroundObjects"), obj_cloud);
}

alarm_set(2, 1);