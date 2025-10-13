/// @description Elemental prompt
if global.current_team == my_team and my_turn {

if (keyboard_string == "") {
    show_debug_message("No text entered for elemental matrix update.");
    exit;
}
var user_natural_language_request = keyboard_string;
global.last_user_prompt = user_natural_language_request;
keyboard_string = "";

show_debug_message("Enter Pressed: Processing request: '" + user_natural_language_request + "'.");

var _llm_interface = noone;
if (variable_instance_exists(self, "myLLM")) { _llm_interface = self.myLLM; }
else if (variable_global_exists("patron")) { _llm_interface = global.patron; }
else if (variable_global_exists("myLLM")) { _llm_interface = global.myLLM; }

// Get current elemental data as JSON string for context
var _current_elemental_data_json_string = json_stringify(global.elemental_data);
if (_current_elemental_data_json_string == "" || is_undefined(_current_elemental_data_json_string)) {
    show_debug_message("Error: Failed to stringify global.elemental_data for LLM context.");
    exit;
}

// System instructions
var matrix_update_system_instructions =
"You are an AI assistant that manages a game's elemental interaction matrix. " +
"The elemental data is a JSON object with a specific structure: " +
"1. It has an 'elements' key: an array of all element name strings. " +
"2. For EACH element name in the 'elements' array, there is also a top-level key in the main JSON object identical to that element's name. " +
"3. The value for each of these top-level element keys is another JSON object (an 'element detail map'). " +
"4. This 'element detail map' MUST contain an 'RGB_COLOR' key, with a value that is an array of three integers [R, G, B] (each 0-255) representing a thematic color. " +
"5. This 'element detail map' MUST ALSO contain a 'SOUND_LIB' key, with a string value chosen from the allowed options: \"flaming\", \"blowing\", \"crackling\", \"energetic\". " +
"6. This 'element detail map' also contains keys for ALL other elements (including the element itself) representing its interactions as an attacker. " +
"7. The values for these interaction keys are integers: 1 (STRONG against defender), -1 (WEAK against), or 0 (NEUTRAL). " +
"Example structure snippet for one element: { \"elements\": [\"fire\", ...], \"fire\": {\"RGB_COLOR\": [255,0,0], \"SOUND_LIB\": \"flaming\", \"fire\": 0, \"water\": -1, ...}, ... }. " +
"ALL interactions MUST be bidirectional. Self-interaction is always 0. " +
"Your task is to process a user's natural language request to either add a new element or modify existing relationships. " +
"If adding a new element: " +
"  - Add its name to the 'elements' array. " +
"  - Create a new top-level key for it, and its 'element detail map'. This map must include a thematic 'RGB_COLOR' array, a thematic 'SOUND_LIB' string (from options), and interaction values. " +
"  - Add the new element as a defender key to ALL other existing elements' 'element detail maps'. " +
"  - When inferring relationships for a new element, aim for an approximate balance: roughly 1/3 strong (1), 1/3 weak (-1), and 1/3 neutral (0) against OTHER elements, always maintaining bidirectionality. " +
"If modifying relationships (e.g., 'make X strong against Y'): " +
"  - Update X's interaction map: X attacking Y becomes 1. " +
"  - Update Y's interaction map: Y attacking X becomes -1. " +
"  - Preserve existing RGB_COLOR and SOUND_LIB values unless the request implies a change. Do not change other relationships unless specified. " +
"Your output MUST be the complete, updated elemental data JSON object, adhering strictly to this structure. Output ONLY the JSON object, with no other text, explanations, or markdown." ;
_llm_interface.set_instructions(matrix_update_system_instructions);

// Generation configuration
var spell_script_gen_config_string = "";
if (global.api == "gemini") {
    spell_script_gen_config_string = "{ \"response_mime_type\": \"application/json\" }";
} else if (global.api == "openai") {
    // For OpenAI, to try and force JSON output mode
    spell_script_gen_config_string = "{ \"response_format\": {\"type\": \"json_object\"} }";
} else {
    show_debug_message("Warning: Unknown API for generation config. Sending empty config.");
}
_llm_interface.set_generation_config(spell_script_gen_config_string);

// HTTP headers
var matrix_update_http_headers_map = ds_map_create();
ds_map_add(matrix_update_http_headers_map, "Content-Type", "application/json");

// Construct prompt body
var matrix_update_user_prompt_text =
"Here is the current elemental data structure:\n" +
"```json\n" +
_current_elemental_data_json_string + "\n" +
"```\n\n" +
"Here is the user's request: \"" + user_natural_language_request + "\"\n\n" +
"Please process this request according to the system instructions. Update the provided elemental data structure to reflect the changes. " +
"Ensure each element's detail map includes an 'RGB_COLOR' key (array of three integers [R, G, B]) and a 'SOUND_LIB' key (string, chosen from \"flaming\", \"blowing\", \"crackling\", \"energetic\"), in addition to its interaction values. " +
"If adding a new element, ensure it's added to the 'elements' list, a new 'element detail map' (including 'RGB_COLOR', 'SOUND_LIB', and interactions) is created for it, and all other elements' interaction maps are updated to include the new element, maintaining bidirectionality and aiming for balance for the new element's relationships. " +
"If modifying relationships, ensure bidirectionality and preserve existing 'RGB_COLOR' and 'SOUND_LIB' values unless specified. " +
"Return ONLY the complete, updated JSON object representing the entire elemental data structure.";

// Define the callback function
var matrix_update_callback = function(response_from_llm_lib) {
    show_debug_message("Elemental update callback triggered.");

    var _error_msg = ds_map_find_value(response_from_llm_lib, "error");
    var _msg_details = ds_map_find_value(response_from_llm_lib, "message");

    if (_error_msg != undefined && string_length(string(_error_msg)) > 0) {
        show_debug_message("LLM Error (Matrix Update): " + string(_error_msg));
        if (_msg_details != undefined) { show_debug_message("Details: " + string(_msg_details)); }
        var _raw_body_if_error = ds_map_find_value(response_from_llm_lib, "response_body_string");
        if (_raw_body_if_error != undefined) { show_debug_message("Raw error response body: " + string(_raw_body_if_error));}
        return;
    }

    var _gemini_response_json_string = ds_map_find_value(response_from_llm_lib, "result");
    var _parsed_gemini_response_struct = undefined;
    var _llm_generated_elemental_data_json_text = undefined;

    if (is_string(_gemini_response_json_string)) {
        _parsed_gemini_response_struct = json_parse(_gemini_response_json_string);
        if (is_struct(_parsed_gemini_response_struct)) {
             if (true) {
                 _llm_generated_elemental_data_json_text = extract_text_from_llm_response(global.api, _parsed_gemini_response_struct);
            } else { 
                show_debug_message("Not reachable now");
            }
        } else {
            show_debug_message("Error: Could not parse main response string into a struct. Raw: " + _gemini_response_json_string);
        }
    } else {
        show_debug_message("Error: LLM 'result' was not a string for matrix update response.");
    }
    
    if (is_string(_llm_generated_elemental_data_json_text)) {
        show_debug_message("LLM generated elemental data JSON");
        show_debug_message(_llm_generated_elemental_data_json_text);
        
        var _new_elemental_data_struct_from_llm = json_parse(_llm_generated_elemental_data_json_text);
        
        if (is_struct(_new_elemental_data_struct_from_llm) &&
            variable_struct_exists(_new_elemental_data_struct_from_llm, "elements") &&
            is_array(_new_elemental_data_struct_from_llm.elements)) {
            
            show_debug_message("(Successfully parsed the LLM's elemental data JSON into a struct)");

            var _is_valid_structure = true;
            var _elements_in_response = _new_elemental_data_struct_from_llm.elements;
            var _allowed_sound_libraries = ["flaming", "blowing", "crackling", "energetic"];

            for (var i = 0; i < array_length(_elements_in_response); i++) {
                var _el_name = _elements_in_response[i];
                if (!variable_struct_exists(_new_elemental_data_struct_from_llm, _el_name) ||
                    !is_struct(_new_elemental_data_struct_from_llm[$ _el_name])) {
                    show_debug_message("Validation Error: Element '" + _el_name + "' listed in 'elements' array is missing its detail map or is not a struct.");
                    _is_valid_structure = false;
                    break;
                }
                var _el_detail_map = _new_elemental_data_struct_from_llm[$ _el_name];
                // Validate RGB_COLOR
                if (!variable_struct_exists(_el_detail_map, "RGB_COLOR") ||
                    !is_array(_el_detail_map.RGB_COLOR) ||
                    array_length(_el_detail_map.RGB_COLOR) != 3) {
                    show_debug_message("Validation Error: Element '" + _el_name + "' is missing 'RGB_COLOR', or it's not an array of 3 values.");
                    _is_valid_structure = false; break;
                }
                for (var c = 0; c < 3; c++) {
                    if (!is_real(_el_detail_map.RGB_COLOR[c])) {
                         show_debug_message("Validation Error: Element '" + _el_name + "' RGB_COLOR["+string(c)+"] is not a number.");
                        _is_valid_structure = false; break;
                    }
                }
                if (!_is_valid_structure) break;

                // Validate SOUND_LIB
                if (!variable_struct_exists(_el_detail_map, "SOUND_LIB") ||
                    !is_string(_el_detail_map.SOUND_LIB)) {
                     show_debug_message("Validation Error: Element '" + _el_name + "' is missing 'SOUND_LIB', it's not a string, or value is not one of " + json_stringify(_allowed_sound_libraries) + ". Value: " + string(_el_detail_map.SOUND_LIB));
                    _is_valid_structure = false; break;
                }
            }

            if (_is_valid_structure) {
                var _temp_json_for_copy = json_stringify(_new_elemental_data_struct_from_llm);
                var _independent_copy_struct = json_parse(_temp_json_for_copy);

                if (is_struct(_independent_copy_struct)) {
					if global.doing_log {
						add_to_log("elementEditing", global.last_user_prompt, json_stringify(global.elemental_data), _temp_json_for_copy);
					}
					global.elemental_data = _independent_copy_struct;
                    //global.elemental_data_display_dirty = true; 
                    show_debug_message("SUCCESS: global.elemental_data has been updated by LLM.");
                } else {
                    show_debug_message("Error: Failed to deep copy the new elemental data struct.");
                }
            } else {
                 show_debug_message("Error: LLM output for elemental data failed structural validation. Not applying changes.");
            }
            
        } else {
            show_debug_message("ERROR: Could not parse the LLM's generated elemental data JSON into a valid struct or basic structure is wrong. Raw text: " + _llm_generated_elemental_data_json_text);
        }
        show_debug_message("----------------------------------------------------");
    } else {
        show_debug_message("Error: No elemental data JSON text extracted from LLM response.");
    }
	with(obj_mage) {
		event_perform(ev_other, ev_user4);
	}
};

// Make request
show_debug_message("Sending elemental matrix update prompt (with Sound Library) to LLM...");
_llm_interface.prompt(matrix_update_http_headers_map, matrix_update_user_prompt_text, matrix_update_callback);

// Clean up data structures
ds_map_destroy(matrix_update_http_headers_map);

}