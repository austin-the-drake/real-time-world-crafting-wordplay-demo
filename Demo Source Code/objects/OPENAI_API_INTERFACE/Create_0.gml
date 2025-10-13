
// API key
if (not variable_instance_exists(self, "api_key") || self.api_key == "") {
    show_debug_message("ERROR (OPENAI_API_INTERFACE): OpenAI API key not provided or empty! Requests will fail.");
    api_key = "INVALID_KEY_PLACEHOLDER";
} else {
    show_debug_message("OPENAI_API_INTERFACE: API Key loaded.");
}

// Endpoint for OpenAI chat completions
endpoint = "https://api.openai.com/v1/chat/completions";

// Model name
model_name = "gpt-4.1";

// Check for custom endpoint using the OpenAI API platform
if file_exists("Custom Endpoints.ini") {
	show_debug_message("found custom endpoints file");
	ini_open("Custom Endpoints.ini");
	var custom_url = ini_read_string("custom_openai_endpoint", "base_url", "");
	var custom_model = ini_read_string("custom_openai_endpoint", "model_name", "");
	var custom_key = ini_read_string("custom_openai_endpoint", "api_key", "");
	var custom_do = ini_read_real("custom_openai_endpoint", "do_custom_endpoint", 0);
	ini_close();
	
	if custom_do > 0 {
		show_debug_message("Using custom endpoint!");
		endpoint = custom_url;
		model_name = custom_model;
		api_key = custom_key;
	}
}

// Internal state variables
waiting = false;
request_id = -1;
http_callback = noone;
timeout_handle = noone;
timeout_duration = 30;

// System instructions and generation parameters
instructions = "";
generation_params_struct = {};

// Method to set system instructions
set_instructions = function(instr_text) {
    self.instructions = string(instr_text);
    show_debug_message("OPENAI_API_INTERFACE: System instructions set.");
};

// Method to set generation configuration parameters
set_generation_config = function(gen_config_json_string) {
    if (is_string(gen_config_json_string) && gen_config_json_string != "") {
        var _parsed_config = json_parse(gen_config_json_string); // Use json_parse
        if (is_struct(_parsed_config)) {
            self.generation_params_struct = _parsed_config;
            show_debug_message("OPENAI_API_INTERFACE: Generation config parsed and set: " + json_stringify(self.generation_params_struct));

        } else {
            show_debug_message("OPENAI_API_INTERFACE Warning: Could not parse gen_config_json_string into a struct. Using empty params. Input: " + gen_config_json_string);
            self.generation_params_struct = {};
        }
    } else {
        show_debug_message("OPENAI_API_INTERFACE: Cleared generation config (empty or invalid input).");
        self.generation_params_struct = {};
    }
};

// Method to set the model name
set_model_name = function(new_model_name) {
    if (is_string(new_model_name) && new_model_name != "") {
        self.model_name = new_model_name;
        show_debug_message("OPENAI_API_INTERFACE: Model name set to: " + self.model_name);
    } else {
        show_debug_message("OPENAI_API_INTERFACE Warning: Invalid model name provided. Retaining current: " + self.model_name);
    }
};


// Method to send an HTTP request
send_request = function(_user_provided_headers_ds_map, _user_prompt_text, _callback_func) {
    if (self.waiting) {
        show_debug_message("OPENAI_API_INTERFACE Info: A request is already in progress. Please wait.");
        if (is_callable(_callback_func)) {
            var _error_response_map = ds_map_create();
            ds_map_add(_error_response_map, "error", "busy");
            ds_map_add(_error_response_map, "message", "OpenAI interface is already waiting for a response.");
            _callback_func(_error_response_map);
            ds_map_destroy(_error_response_map);
        }
        return;
    }
    
    self.waiting = true;
    self.http_callback = _callback_func;
    
    var _url = self.endpoint;
    
    // Prepare headers
    var _final_headers_ds_map = ds_map_create();
    if (ds_exists(_user_provided_headers_ds_map, ds_type_map)) {
        ds_map_copy(_final_headers_ds_map, _user_provided_headers_ds_map);
    } else {
        ds_map_add(_final_headers_ds_map, "Content-Type", "application/json");
    }
    ds_map_add(_final_headers_ds_map, "Authorization", "Bearer " + self.api_key);
    
    // Build the payload
    var _payload_root_struct = {};
    _payload_root_struct.model = self.model_name;
    
    // Construct the messages array
    var _messages_array = [];
    if (self.instructions != "") {
        array_push(_messages_array, { role: "system", content: self.instructions });
    }
    array_push(_messages_array, { role: "user", content: _user_prompt_text });

    _payload_root_struct.messages = _messages_array;
    
    // Add other generation parameters
    if (is_struct(self.generation_params_struct)) {
        var _param_keys = variable_struct_get_names(self.generation_params_struct);
        for (var i = 0; i < array_length(_param_keys); i++) {
            var _key = _param_keys[i];
            _payload_root_struct[$ _key] = self.generation_params_struct[$ _key];
        }
    }
    
    // Encode the entire payload struct to a JSON string
    var _final_json_payload_string = json_stringify(_payload_root_struct);
    show_debug_message("OPENAI_API_INTERFACE Payload: " + _final_json_payload_string);

    // Make the HTTP request
    self.request_id = http_request(_url, "POST", _final_headers_ds_map, _final_json_payload_string);
    
    ds_map_destroy(_final_headers_ds_map);

    // Timeout logic
    if (self.timeout_handle != noone && !is_undefined(self.timeout_handle)) {
         call_cancel(self.timeout_handle);
    }
    self.timeout_handle = call_later(self.timeout_duration, time_source_units_seconds, function() {
        if (self.waiting && self.request_id != -1) { 
            self.waiting = false;
            self.request_id = -1; 
            show_debug_message("OPENAI_API_INTERFACE Error: Request timed out.");
            if (is_callable(self.http_callback)) {
                var _timeout_response_map = ds_map_create();
                ds_map_add(_timeout_response_map, "error", "timeout");
                ds_map_add(_timeout_response_map, "message", "Request timed out after " + string(self.timeout_duration) + " seconds.");
                self.http_callback(_timeout_response_map);
                ds_map_destroy(_timeout_response_map);
            }
        }
    }, false); 
};