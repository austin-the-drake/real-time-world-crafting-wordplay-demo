// Enums
#macro ca_type_liquid 1
#macro ca_type_powder 2
#macro ca_type_gas 4
#macro ca_type_solid 8

#macro happy_red #FC5C65
#macro grumpy_blue #9179FF
#macro dull_yellow #FFB600
#macro wonder_green #37D98C

// Function to set an attribute only if it exists
function safe_set_attribute(_struct, _name, _default) {
	if variable_struct_exists(_struct, _name) {
		return variable_struct_get(_struct, _name);
	} else {
		return _default;
	}
}

// Function to determine interactions when more than two elements are involved by aggregating their effects
// I'm using a simple additive model. Future work could explore using the LLM to determine the outcomes of more complex elemental interactions
function aggregate_elemental_interaction(_attack_list, _defend_list, _data_source, resistances=[]) {
    var aggregate = 0;
    for (var i=0; i<array_length(_attack_list); i++) {
        for (var j=0; j<array_length(_defend_list); j++) {
            var attack_type = _attack_list[i];
            var defend_type = _defend_list[j];
            
            // Get the potential interaction value
            var interaction_value = variable_struct_get(variable_struct_get(_data_source, attack_type), defend_type);
            
            // Check if the current defending element type confers immunity
            var is_immune_to_defend_type = array_contains(resistances, defend_type);
            
            // Add the interaction if:
            // 1. The defender is not immune to this defending element type, or
            // 2. The defender is immune, but the interaction value is negative (favorable to defender)
            if (!is_immune_to_defend_type || (is_immune_to_defend_type && interaction_value < 0)) {
                aggregate += interaction_value;
            }
            // Implicitly, if 'is_immune_to_defend_type' is true AND 'interaction_value' is >= 0,
            // the immunity takes precedence, and the (non-negative) interaction is blocked
        }
    }
    return aggregate;
}

// Function to return a placeholder string if source is not a string
// Used mainly for safe debug printouts
function safe_string(val) {
    if (is_undefined(val)) return "undefined";
    if (is_string(val)) return val;
    return string(val);
}

// Recursive function to destroy nested data structures
// Less used in the final codebase, as I moved to garbage-collected data structures where possible
function deep_destroy_ds_structure(data_id) {
    if (!is_real(data_id)) {
        return; 
    }
    if (ds_exists(data_id, ds_type_map)) {
        var key = ds_map_find_first(data_id);
        while (!is_undefined(key)) {
            var val = ds_map_find_value(data_id, key);
            if (is_real(val)) { // Only check/recurse if val could be an ID
                if (ds_exists(val, ds_type_map) || ds_exists(val, ds_type_list)) {
                    deep_destroy_ds_structure(val); 
                }
            }
            key = ds_map_find_next(data_id, key);
        }
        ds_map_destroy(data_id);
    } else if (ds_exists(data_id, ds_type_list)) {
        for (var i = 0; i < ds_list_size(data_id); i++) {
            var val = ds_list_find_value(data_id, i);
            if (is_real(val)) { // Only check/recurse if val could be an ID
                if (ds_exists(val, ds_type_map) || ds_exists(val, ds_type_list)) {
                    deep_destroy_ds_structure(val);
                }
            }
        }
        ds_list_destroy(data_id);
    }
}

// Function to extract text from a response object (obsolete)
function extract_text_from_gemini_response(gemini_response_map_id) {
    if (!ds_exists(gemini_response_map_id, ds_type_map)) { return undefined; }
    var _candidates_list = ds_map_find_value(gemini_response_map_id, "candidates");
    if (ds_exists(_candidates_list, ds_type_list) && ds_list_size(_candidates_list) > 0) {
        var _first_candidate_map = ds_list_find_value(_candidates_list, 0);
        if (ds_exists(_first_candidate_map, ds_type_map)) {
            var _content_map = ds_map_find_value(_first_candidate_map, "content");
            if (ds_exists(_content_map, ds_type_map)) {
                var _parts_list = ds_map_find_value(_content_map, "parts");
                if (ds_exists(_parts_list, ds_type_list) && ds_list_size(_parts_list) > 0) {
                    var _first_part_map = ds_list_find_value(_parts_list, 0);
                    if (ds_exists(_first_part_map, ds_type_map)) {
                        var _text_content = ds_map_find_value(_first_part_map, "text");
                        if (is_string(_text_content)) { return _text_content; }
                    }
                }
            }
        }
    }
    return undefined;
}

// Function to extract text from a response object using garage-collected data structures
function extract_text_from_gemini_response_struct(gemini_response_struct) {
    if (!is_struct(gemini_response_struct)) {
        show_debug_message("extract_text: Input was not a struct.");
        return undefined;
    }

    if (variable_struct_exists(gemini_response_struct, "candidates") &&
        is_array(gemini_response_struct.candidates) &&
        array_length(gemini_response_struct.candidates) > 0) {

        var _first_candidate_struct = gemini_response_struct.candidates[0];
        if (is_struct(_first_candidate_struct) && variable_struct_exists(_first_candidate_struct, "content")) {
            var _content_struct = _first_candidate_struct.content;
            if (is_struct(_content_struct) && variable_struct_exists(_content_struct, "parts")) {
                var _parts_array = _content_struct.parts;
                if (is_array(_parts_array) && array_length(_parts_array) > 0) {
                    var _first_part_struct = _parts_array[0];
                    if (is_struct(_first_part_struct) && variable_struct_exists(_first_part_struct, "text")) {
                        var _text_content = _first_part_struct.text;
                        if (is_string(_text_content)) {
                            return _text_content;
                        } else {
                            show_debug_message("extract_text: parts[0].text was not a string.");
                        }
                    } else { show_debug_message("extract_text: parts[0] was not a struct or missing 'text'."); }
                } else { show_debug_message("extract_text: content.parts was not an array or empty."); }
            } else { show_debug_message("extract_text: candidate.content was not a struct or missing."); }
        } else { show_debug_message("extract_text: candidates[0] was not a struct or missing."); }
    } else { show_debug_message("extract_text: response.candidates was not an array or empty."); }
    
    return undefined;
}

// Same function for OpenAI
function extract_text_from_openai_response_struct(openai_response_struct) {
    if (!is_struct(openai_response_struct)) {
        show_debug_message("extract_text_openai: Input was not a struct.");
        return undefined;
    }

    // Check for the "choices" array
    if (variable_struct_exists(openai_response_struct, "choices") &&
        is_array(openai_response_struct.choices) &&
        array_length(openai_response_struct.choices) > 0) {

        // Get the first choice object
        var _first_choice_struct = openai_response_struct.choices[0];
        if (is_struct(_first_choice_struct) && variable_struct_exists(_first_choice_struct, "message")) {
            
            // Get the message object
            var _message_struct = _first_choice_struct.message;
            if (is_struct(_message_struct) && variable_struct_exists(_message_struct, "content")) {
                
                // Get the content string
                var _text_content = _message_struct.content;
                if (is_string(_text_content)) {
                    return _text_content; // Success!
                } else {
                    show_debug_message("extract_text_openai: choices[0].message.content was not a string. Value: " + string(_text_content));
                }
            } else {
                show_debug_message("extract_text_openai: choices[0].message was not a struct or missing 'content'.");
            }
        } else {
            show_debug_message("extract_text_openai: choices[0] was not a struct or missing 'message'.");
        }
    } else {
        show_debug_message("extract_text_openai: response.choices was not an array, was empty, or did not exist.");
    }
    
    return undefined;
}

// And for Anthropic
function extract_text_from_anthropic_response_struct(anthropic_response_struct) {
    if (!is_struct(anthropic_response_struct)) {
        show_debug_message("extract_text_anthropic: Input was not a struct.");
        return undefined;
    }

    if (variable_struct_exists(anthropic_response_struct, "content") &&
        is_array(anthropic_response_struct.content) &&
        array_length(anthropic_response_struct.content) > 0) {

        var _first_content_struct = anthropic_response_struct.content[0];
        if (is_struct(_first_content_struct) && variable_struct_exists(_first_content_struct, "text")) {
            var _text_content = _first_content_struct.text;
            if (is_string(_text_content)) {
                return _text_content; // Success!
            } else {
                show_debug_message("extract_text_anthropic: content[0].text was not a string.");
            }
        } else {
            show_debug_message("extract_text_anthropic: content[0] was not a struct or missing 'text'.");
        }
    } else {
        show_debug_message("extract_text_anthropic: response.content was not an array, was empty, or did not exist.");
    }
    
    return undefined;
}

// Wrapper function to use regardless of LLM provider
function extract_text_from_llm_response(api_name, parsed_api_response_struct) {
    if (!is_string(api_name)) {
        show_debug_message("extract_text_from_llm_response: Error: api_name must be a string. Got: " + string(api_name));
        return undefined;
    }
    if (!is_struct(parsed_api_response_struct)) {
        show_debug_message("extract_text_from_llm_response: Error: parsed_api_response_struct must be a struct. Got: " + string(parsed_api_response_struct));
        return undefined;
    }

    var _extracted_text = undefined;

    switch (string_lower(api_name)) {
        case "anthropic":
            _extracted_text = extract_text_from_anthropic_response_struct(parsed_api_response_struct);
            break;

        case "gemini":
                _extracted_text = extract_text_from_gemini_response_struct(parsed_api_response_struct);
            break;

        case "openai":
                _extracted_text = extract_text_from_openai_response_struct(parsed_api_response_struct);
            break;

        default:
            show_debug_message("extract_text_from_llm_response: Error - Unsupported API name: " + api_name);
            break;
    }

    if (is_undefined(_extracted_text)) {
        show_debug_message("extract_text_from_llm_response: Failed to extract text for API '" + api_name + "'.");
        return undefined; // Exit early if no text was found
    }

    // Models sometimes wrap JSON in markdown code blocks
    _extracted_text = string_trim(_extracted_text);
    
    // Check if the string begins with a markdown fence
    if (string_pos("```", _extracted_text) == 1) {
        // Find the first newline character. The actual content starts after this
        var _start_pos = string_pos("\n", _extracted_text);
        if (_start_pos > 0) {
            // Find the last markdown fence. The content ends before this
            var _end_pos = string_last_pos("```", _extracted_text);
            if (_end_pos > _start_pos) {
                // Copy the substring between the start and end positions
                var _length = _end_pos - (_start_pos + 1);
                var _clean_text = string_copy(_extracted_text, _start_pos + 1, _length);
                
                // Trim the result and assign it back
                _extracted_text = string_trim(_clean_text);
            }
        }
    }

    return _extracted_text;
}

// Function to add input-reponse pairs to the log file
function add_to_log(task_name, user_input, current_context, response_content) {
	if (!global.doing_log) {
		return false;
	}

	// Create a unique section name with a timestamp
	var datetime = date_current_datetime();
	var timestamp = string(date_get_year(datetime)) + "-" + 
					string(date_get_month(datetime)) + "-" + 
					string(date_get_day(datetime)) + "-" +
					string(date_get_hour(datetime)) + "-" + 
					string(date_get_minute(datetime)) + "-" + 
					string(date_get_second(datetime));
	var section_name = task_name + "-" + timestamp;

	// This key-value format used to be .ini, but it didn't work as well for longer game sessions
	array_push(global.log_data, "[" + section_name + "]");
	array_push(global.log_data, "input::" + user_input);
	array_push(global.log_data, "context::" + current_context);
	array_push(global.log_data, "response::" + response_content);
	array_push(global.log_data, "[end]"); 

	return true;
}

// Function to save the current log data to disk
function save_log() {
	if (!global.doing_log) {
		return false;
	}

	// Get a filename for the log
	var datetime = date_current_datetime();
	var timestamp = string(date_get_year(datetime)) + "-" + 
					string(date_get_month(datetime)) + "-" + 
					string(date_get_day(datetime)) + "-" +
					string(date_get_hour(datetime)) + "-" + 
					string(date_get_minute(datetime)) + "-" + 
					string(date_get_second(datetime));
	
	var log_filename = get_save_filename_ext("Log File|*.txt", "LatentSpaceLog-" + timestamp + ".txt", working_directory, "Set debug log dump path");

	if (log_filename == "") {
		// User cancelled the save dialog
		return false;
	}

	// Write the log data to the file
	var file = file_text_open_write(log_filename);
	if (file < 0) {
		// Could not open file
		return false;
	}

	for (var i = 0; i < array_length(global.log_data); i++) {
		file_text_write_string(file, global.log_data[i]);
		file_text_writeln(file);
	}
	file_text_close(file);
	
	// Clear the log data after saving
	global.log_data = []; 
	
	return true;
}

// Default fizzle spell definition
global.failure_spell = {
  "friendlyName": "Incomprehensible Spell",
  "components": [
    {
      "componentType": "manifestation",
      "radius": 2,
      "material_properties": {
        "class": "gas",
        "color_rgb": [
          128,
          128,
          128
        ],
        "blockpath": 0,
        "density": 0.5,
        "elements": [
          "neutral"
        ],
        "lifespan": 0.5
      }
    },
    {
      "componentType": "manaCost",
      "cost": 5
    }
  ]
}