/// @description Element scripting prompt
show_debug_message("Prompting LLM for new CA behavior...");
audio_play_sound(snd_make_request, 1, false, 0.5);
var _llm_interface = noone;

if (variable_instance_exists(self, "myLLM")) { _llm_interface = self.myLLM; }
else if (variable_global_exists("patron")) { _llm_interface = global.patron; }

// Get the natural language description from the user
var new_element_description = keyboard_string;
global.last_user_prompt = new_element_description;

// Build a JSON string describing the current set of element behaviors
var type_names = variable_struct_get_names(ca_types);
var existing_behaviors_struct = {};
for (var i = 0; i < array_length(type_names); i++) {
    var type_name = type_names[i];
    var type_data = ca_types[$ type_name];
    if (is_struct(type_data) && variable_struct_exists(type_data, "behavior") && array_length(type_data.behavior.actions) > 0) {
        existing_behaviors_struct[$ type_name] = type_data.behavior;
    }
}
global.existing_elements_json_string = json_stringify(existing_behaviors_struct);

// System instructions
var behavior_script_system_instructions =
"You are a game design assistant specializing in cellular automata. Your task is to generate a single, valid JSON object that defines a behavior script based on the user's description. " +
"The entire response MUST be a single, valid JSON object. Do NOT include any explanatory text, markdown formatting, or anything outside of this object. Adhere strictly to the node definitions provided.";
_llm_interface.set_instructions(behavior_script_system_instructions);


// Generation configuration
var behavior_script_gen_config_string = "";
if (global.api == "gemini") {
    behavior_script_gen_config_string = "{ \"response_mime_type\": \"application/json\" }";
} else if (global.api == "openai") {
    behavior_script_gen_config_string = "{ \"response_format\": {\"type\": \"json_object\"} }";
} else {
    show_debug_message("Warning: Unknown API for generation config. Sending empty config.");
}
_llm_interface.set_generation_config(behavior_script_gen_config_string);


// HTTP headers
var behavior_script_http_headers_map = ds_map_create();
ds_map_add(behavior_script_http_headers_map, "Content-Type", "application/json");

// Construct the prompt body
var behavior_script_user_prompt_text = @'
You are a game design assistant specializing in cellular automata.
Your task is to generate a single, valid JSON object that defines a behavior script based on the user description.
The output must be a single JSON object containing four root keys:
`"planning"` (a brief, 2-3 sentence paragraph that outlines the plan for which components to use),
`"name"` (a creative, one-word, lowercase string),
`"color_hex"` (a hex string like `"#RRGGBB"`),
and `"behavior"` (a struct containing the `"actions"` array).
The entire response MUST be a single, valid JSON object.
Do NOT include any explanatory text, markdown formatting, or anything outside of this object.
Adhere strictly to the node definitions provided.

**Important Notes:**
* The term "direction" in the documentation below is a placeholder for one of ["north", "northeast", "east", "southeast", "south", "southwest", "west", "northwest"].
"south" is down, and "north" is up. Use one or some of these keywords instead of "direction" in actual scripts.
Whenever possible, use the stochastic wrapper nodes instead of laboriously checking multiple directions. For example, if something moves anywhere, just use in_rand_rotation. If something falls down and left or right, use in_rand_mirror.
* "self" is a valid keyword for a particle`s own cell that it resides in currently.
* Actions are processed sequentially.
* The `do_swap` node is special: it moves the cell, then can immediately run a nested `actions` list from the cell`s *new* location.
If using directionality in these post-swap actions, make sure they are correct relative to the cell`s *new* position.
After a `do_swap` operation is complete, the cell`s turn ends for that step.
* If you are asked to update an existing cell type, do not alter its `name` field, or else it may break references.

--- Available Node Types (for the `actions` array inside the `behavior` struct) ---

**I. Wrapper / Modifier Nodes (These contain other nodes):**
* `{ "type": "in_rand_rotation", "actions": [ ... ] }`: Executes nested actions in one random of 8 directions.
* `{ "type": "in_rand_mirror", "actions": [ ... ] }`: 50% chance to mirror nested actions across the vertical axis (east becomes west, etc.).
* `{ "type": "in_rand_flip", "actions": [ ... ] }`: 50% chance to flip nested actions across the horizontal axis (north becomes south, etc.).

**II. Conditional Nodes (These check a condition and then run nested actions):**
* `{ "type": "if_neighbor_is", "direction": "...", "options": ["type1", "type2"], "actions": [ ... ], "else_actions": [ ... ] }`: Checks if a neighbor is one of the types in `options`.
* `{ "type": "if_neighbor_is_not", "direction": "...", "options": ["type1"], "actions": [ ... ] }`: The inverse of the above.
* `{ "type": "if_alpha", "target": "self|direction", "comparison": "...", "is": number, "actions": [ ... ] }`: Checks a cell`s alpha value. `comparison` options: `"less_than"`, `"greater_than"`, `"equal_to"`, `"not_equal_to"`.
* `{ "type": "if_neighbor_count", "direction_set": ["dir1", ...], "options": ["type1"], "comparison": "...", "count": number, "actions": [ ... ] }`: Counts neighbors of a certain type in the given directions and compares the total.
* `{ "type": "if_chance", "percent": number (0-100), "actions": [ ... ] }`: Succeeds based on a percentage chance.

**III. Executor / Action Nodes (These perform an action and are usually the innermost nodes):**
* `{ "type": "do_swap", "direction": "...", "actions": [ ... ] (optional) }`: Swaps position with a neighbor, then can immediately run a nested `actions` list from the cell`s new location. This entire operation ends the cell`s turn.
* `{ "type": "do_set_type", "target": "self|direction", "to": "new_type" }`: Changes a cell`s type.
* `{ "type": "do_set_alpha", "target": "self|direction", "operation": "...", "to": number }`: Modifies a cell`s alpha value. `operation` options: `"set"`, `"add"`, `"subtract"`.
* `{ "type": "do_spawn", "direction": "...", "into_options": ["air"], "set_type": "...", "set_alpha": number (optional) }`: Creates a new particle in an adjacent cell if it`s a valid type.
* `{ "type": "do_copy_alpha", "source_direction": "...", "dest_direction": "..." }`: Copies the alpha value from one cell to another.
---
--- Below are a series of examples to help you understand the task---

Example Input: "A gas that moves randomly, fades over time, and disappears."
Example Output JSON:
{"planning":"I will represent the random diffusion of gas with an in_rand_rotation wrapper and swap node.
I will use the alpha value as a lifespan counter, decrementing it every tick and changing the mist into air when it reaches zero.",
"name":"mist",
"color_hex":"#AADDCC",
"behavior":{"actions":[{"type":"in_rand_rotation","actions":[{"type":"if_neighbor_is","direction":"north","options":["air"],"actions":[{"type":"do_swap","direction":"north","actions":[{"type":"do_set_alpha","target":"self","operation":"subtract","to":10},{"type":"if_alpha","target":"self","comparison":"less_than","is":1,"actions":[{"type":"do_set_type","target":"self","to":"air"}]}]}]}]}]}}

Example Input: "An element called sand that behaves like a powder, but stiffens under water"
Example Output JSON:
{"planning":"I`ll model the powder behavior by first checking if the sand can fall straight down into air or water.
If it can`t, I`ll check the diagonal directions (southeast/southwest) to simulate it settling into a pile.
An in_rand_mirror node will be used to prevent a bias towards falling in one particular diagonal direction.
I`ll only move diagonally into air, to address the stiffening under water stipulation.",
"name":"sand",
"color_hex":"#EDCE97",
"behavior":{"actions":[{"type":"in_rand_mirror","actions":[{"type":"if_neighbor_is","direction":"south","options":["air","water"],"actions":[{"type":"do_swap","direction":"south"}],"else_actions":[{"type":"if_neighbor_is","direction":"southeast","options":["air"],"actions":[{"type":"do_swap","direction":"east"}],"else_actions":[]}]}]}]}}

Example Input: "An element called plant that grows downward with a random chance. It grows in the presence of water, and is flammable."
Example Output JSON:
{"planning":"I`ll use the alpha value to represent the plant`s maturity.
The plant will grow downwards by spawning a new plant cell below it, provided the space is available and the parent plant is mature enough.
I will also implement its flammability by having it check for fire or lava in its immediate vicinity.
If found, the plant will turn into fire.",
"name":"plant",
"color_hex":"#00AA00",
"behavior":{"actions":[{"type":"if_alpha","target":"self","comparison":"greater_than","is":99,"actions":[{"type":"if_chance","percent":50,"actions":[{"type":"do_set_alpha","target":"self","operation":"set","to":32}]}]},{"type":"if_alpha","target":"self","comparison":"greater_than","is":33,"actions":[{"type":"if_neighbor_is","direction":"south","options":["air","water"],"actions":[{"type":"do_spawn","direction":"south","into_options":["air","water"],"set_type":"plant"},{"type":"do_copy_alpha","source_direction":"self","dest_direction":"south"},{"type":"do_set_alpha","target":"south","operation":"subtract","to":10}]}]},{"type":"if_neighbor_count","direction_set":["north","northeast","east","southeast","south","southwest","west","northwest"],"options":["water"],"comparison":"greater_than","count":0,"actions":[{"type":"in_rand_rotation","actions":[{"type":"do_set_type","target":"east","to":"plant"},{"type":"do_set_type","target":"south","to":"air"}]}],"else_actions":[{"type":"if_neighbor_count","direction_set":["north","northeast","east","southeast","south","southwest","west","northwest"],"options":["fire","lava"],"comparison":"greater_than","count":0,"actions":[{"type":"do_set_type","target":"self","to":"fire"}]}]}]}}

Example Input: "An element called fire that behaves like a gas, with a short lifespan. It combusts other materials."
Example Output JSON:
{"planning":"I will use the alpha value to manage the fire`s lifespan; it will decrease each turn, and the fire will turn to air when it burns out.
To simulate its gas-like nature, I`ll make it move randomly, with a tendency to rise.
Its primary behavior will be to check adjacent cells for flammable materials like wood or plant and set them alight, transforming them into fire.",
"name":"fire",
"color_hex":"#FF9933",
"behavior":{"actions":[{"type":"do_set_alpha","target":"self","operation":"add","to":-10},{"type":"if_alpha","target":"self","comparison":"less_than","is":1,"actions":[{"type":"do_set_type","target":"self","to":"air"}],"else_actions":[{"type":"if_chance","percent":50,"actions":[{"type":"in_rand_rotation","actions":[{"type":"if_neighbor_is","direction":"south","options":["air"],"actions":[{"type":"do_swap","direction":"south"}],"else_actions":[{"type":"if_neighbor_is","direction":"south","options":["gas","air","wood","plant","seed"],"actions":[{"type":"do_set_type","target":"south","to":"fire"},{"type":"do_set_alpha","target":"self","operation":"set","to":50}]}]}]}]},{"type":"if_neighbor_is","direction":"north","options":["air"],"actions":[{"type":"do_swap","direction":"north"}]}]}]}}

Example Input: "A viscous element called lava that flows slowly. It catches things on fire, and turns to stone in contact with water."
Example Output JSON:
{"planning":"To simulate slow, viscous movement, I will use if_chance nodes to govern its flow.
The lava will prioritize moving downwards, but will also be able to spread sideways at a slower rate.
Its interaction rules are key: it will turn into stone upon contact with water, and it will set any adjacent flammable materials on fire.",
"name":"lava",
"color_hex":"#FF8000",
"behavior":{"actions":[{"type":"if_chance","percent":4.76,"actions":[{"type":"do_set_alpha","target":"self","operation":"set","to":100}]},{"type":"in_rand_rotation","actions":[{"type":"if_neighbor_is","direction":"south","options":["gas","plant","wood","seed"],"actions":[{"type":"do_set_type","target":"south","to":"fire"}],"else_actions":[{"type":"if_neighbor_is","direction":"south","options":["water"],"actions":[{"type":"do_set_type","target":"self","to":"stone"}]}]}]},{"type":"if_neighbor_is","direction":"south","options":["air"],"actions":[{"type":"do_swap","direction":"south"}],"else_actions":[{"type":"if_chance","percent":10,"actions":[{"type":"in_rand_mirror","actions":[{"type":"if_neighbor_is","direction":"east","options":["air"],"actions":[{"type":"do_swap","direction":"east"}]}]}]},{"type":"if_chance","percent":1,"actions":[{"type":"if_neighbor_is","direction":"north","options":["air"],"actions":[{"type":"do_set_type","target":"north","to":"fire"},{"type":"do_set_alpha","target":"north","operation":"set","to":30}]}]}]}]}}

--- Your Task ---
Be creative and thorough. If creating a new element, invent a `name` and `color_hex` for it. If updating an existing element, keep them unaltered unless asked to. Pay very close attention to how the element should interact with existing elements when defining its `behavior`.
Now, generate the complete JSON object for the following element. You will be provided with a user input (a request for an update, or a description of a new element), and a list of all the existing materials and their respective behaviors.
'
+ "--- Existing Element Behaviors (JSON format) ---\n"
+ "Consider how a new element should interact with these existing elements:\n"
+ "```json\n"
+ global.existing_elements_json_string + "\n"
+ "```\n\n"
+ "--- New Element Description ---\n"
+ "\"" + new_element_description + "\"";

// Define the callback function
global.newly_generated_behavior = undefined;

var behavior_script_callback = function(response_from_llm_lib) {
    show_debug_message("CA Behavior Callback Triggered.");
    
    // Error checking
    var _error_msg = ds_map_find_value(response_from_llm_lib, "error");
    if (_error_msg != undefined && string_length(string(_error_msg)) > 0) {
        show_debug_message("LLM Error: " + string(_error_msg));
        var _msg_details = ds_map_find_value(response_from_llm_lib, "message");
        if (_msg_details != undefined) { show_debug_message("Details: " + string(_msg_details)); }
        return;
    }

    // Two-Step response parsing
    var _raw_api_response_string = ds_map_find_value(response_from_llm_lib, "result");
    var _parsed_api_response_struct = undefined;
    var _llm_generated_content_string = undefined;

    if (is_string(_raw_api_response_string)) {
        _parsed_api_response_struct = json_parse(_raw_api_response_string);
        
        if (is_struct(_parsed_api_response_struct)) {
            _llm_generated_content_string = extract_text_from_llm_response(global.api, _parsed_api_response_struct);
        } else {
            show_debug_message("Error: Could not parse main API response string into a struct. Raw: " + _raw_api_response_string);
        }
    } else {
        show_debug_message("Error: LLM 'result' was not a string.");
    }
    
	if global.doing_log {
		add_to_log("automataScripting", global.last_user_prompt, global.existing_elements_json_string, _llm_generated_content_string);
	}
	
    // Final validation and assignment
    if (is_string(_llm_generated_content_string)) {
        var _cleaned_json_string = _llm_generated_content_string;
        var _json_start_pos = string_pos("{", _cleaned_json_string);
        var _json_end_pos = string_last_pos("}", _cleaned_json_string);
    
        if (_json_start_pos > 0 && _json_end_pos > 0) {
            _cleaned_json_string = string_copy(_cleaned_json_string, _json_start_pos, _json_end_pos - _json_start_pos + 1);
        }
        
        show_debug_message("Cleaned JSON content from LLM: " + _cleaned_json_string);
        
		try {
			var _parsed_struct = json_parse(_cleaned_json_string);
		} catch(_exception) {
			show_debug_message("Malformed JSON in response");
			exit;
		}
        
        // Validate the script
        if (is_struct(_parsed_struct) 
            && variable_struct_exists(_parsed_struct, "name")
            && variable_struct_exists(_parsed_struct, "color_hex")
            && variable_struct_exists(_parsed_struct, "behavior")) {
            
            show_debug_message("Successfully parsed new element from LLM!");
            
            // Extract the data
            var new_name = _parsed_struct.name;
			if array_contains(["pause", "play", "clear", "set /\nenter", "exit"], new_name) {
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
            
            global.newly_generated_behavior = _parsed_struct; 
            
            // Create the final struct
            var new_element_data = {
                color: new_gml_color,
                behavior: new_behavior
            };
            
            // Add the new element to the main ca_types struct
            obj_ca_controller.ca_types[$ new_name] = new_element_data;
			global.latest_element_name = new_name;
			with(obj_ca_button) {
				if name == global.selected_element {
					name = global.latest_element_name;
				}
			}
			global.selected_element = new_name;
			audio_play_sound(snd_spell_recieved, 1, false, 0.5);
            show_debug_message("Added new element '" + new_name + "' to ca_types.");
            
        } else {
            show_debug_message("Error: Failed to parse a valid element struct (name, color_hex, behavior) from the extracted content.");
            global.newly_generated_behavior = undefined;
        }
    } else {
        show_debug_message("Error: No text content extracted from LLM response.");
		audio_play_sound(snd_magic_words, 1, false, 1);
    }
};

// Make request
show_debug_message("Sending CA behavior prompt to LLM for: \"" + new_element_description + "\"");
_llm_interface.prompt(behavior_script_http_headers_map, behavior_script_user_prompt_text, behavior_script_callback);

// Clean up data structures
ds_map_destroy(behavior_script_http_headers_map);

keyboard_string = "";