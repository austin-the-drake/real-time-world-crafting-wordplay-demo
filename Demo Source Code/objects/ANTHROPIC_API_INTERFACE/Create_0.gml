
// Requires that the API key be passed as the first argument when this instance is created

if (not variable_instance_exists(self, "api_key") || self.api_key == "") {
    show_debug_message("ERROR (ANTHROPIC_API_INTERFACE): Anthropic API key not provided or empty! Requests will fail.");
    api_key = "INVALID_KEY_PLACEHOLDER";
} else {
    show_debug_message("ANTHROPIC_API_INTERFACE: API Key loaded.");
}

// Endpoint for Anthropic messages API
endpoint = "https://api.anthropic.com/v1/messages";

// API version is required
anthropic_version = "2023-06-01";
model_name = "claude-4-sonnet-20250514";

// Internal state variables
waiting = false;
request_id = -1;
http_callback = noone;
timeout_handle = noone;
timeout_duration = 45;
instructions = "";

// Anthropic requires a token limit on all requests
generation_params_struct = {
    max_tokens: 4096
};

// Method to set system instructions
set_instructions = function(instr_text) {
    self.instructions = string(instr_text);
    show_debug_message("ANTHROPIC_API_INTERFACE: System instructions set.");
};

// Method to set generation configuration parameters
set_generation_config = function(gen_config_json_string) {
    if (is_string(gen_config_json_string) && gen_config_json_string != "") {
        var _parsed_config = json_parse(gen_config_json_string);
        if (is_struct(_parsed_config)) {
            // Ensure max_tokens is present, otherwise add a default.
            if (!variable_struct_exists(_parsed_config, "max_tokens")) {
                _parsed_config.max_tokens = 4096;
                show_debug_message("ANTHROPIC_API_INTERFACE Warning: 'max_tokens' not found in config, adding default value.");
            }
            self.generation_params_struct = _parsed_config;
            show_debug_message("ANTHROPIC_API_INTERFACE: Generation config parsed and set: " + json_stringify(self.generation_params_struct));
        } else {
            show_debug_message("ANTHROPIC_API_INTERFACE Warning: Could not parse gen_config_json_string into a struct. Using default params. Input: " + gen_config_json_string);
            self.generation_params_struct = { max_tokens: 4096 };
        }
    } else {
        show_debug_message("ANTHROPIC_API_INTERFACE: Cleared generation config (empty or invalid input). Using default params.");
        self.generation_params_struct = { max_tokens: 4096 };
    }
};

// Method to set the model name
set_model_name = function(new_model_name) {
    if (is_string(new_model_name) && new_model_name != "") {
        self.model_name = new_model_name;
        show_debug_message("ANTHROPIC_API_INTERFACE: Model name set to: " + self.model_name);
    } else {
        show_debug_message("ANTHROPIC_API_INTERFACE Warning: Invalid model name provided. Retaining current: " + self.model_name);
    }
};

// Method to send an HTTP request
send_request = function(_user_provided_headers_ds_map, _user_prompt_text, _callback_func) {
    // Anthropic uses a fixed set of headers, so _user_provided_headers_ds_map is ignored for compatibility

    if (self.waiting) {
        show_debug_message("ANTHROPIC_API_INTERFACE Info: A request is already in progress!");
        if (is_callable(_callback_func)) {
            var _error_response_map = ds_map_create();
            ds_map_add(_error_response_map, "error", "busy");
            ds_map_add(_error_response_map, "message", "Anthropic interface is already waiting for a response.");
            _callback_func(_error_response_map);
            ds_map_destroy(_error_response_map);
        }
        return;
    }
    
    self.waiting = true;
    self.http_callback = _callback_func;
    
    var _url = self.endpoint;
    
    // Prepare headers
    var _headers_ds_map = ds_map_create();
    ds_map_add(_headers_ds_map, "Content-Type", "application/json");
    ds_map_add(_headers_ds_map, "x-api-key", self.api_key);
    ds_map_add(_headers_ds_map, "anthropic-version", self.anthropic_version);
    
    // Build the payload struct
    var _payload_root_struct = {};
    _payload_root_struct.model = self.model_name;
    
    if (self.instructions != "") {
        _payload_root_struct.system = self.instructions;
    }
    
    var _messages_array = [];
    array_push(_messages_array, { role: "user", content: _user_prompt_text });
    _payload_root_struct.messages = _messages_array;
    
    // Add other generation parameters from the config struct
    if (is_struct(self.generation_params_struct)) {
        var _param_keys = variable_struct_get_names(self.generation_params_struct);
        for (var i = 0; i < array_length(_param_keys); i++) {
            var _key = _param_keys[i];
            _payload_root_struct[$ _key] = self.generation_params_struct[$ _key];
        }
    }
    
    // Encode the entire payload struct to a JSON string
    var _final_json_payload_string = json_stringify(_payload_root_struct);
    
    // json_stringify turns integers into floats >:(
    // The following fixes this by removing all text ".0," or ".0}"
    _final_json_payload_string = string_replace_all(_final_json_payload_string, ".0,", ",");
    _final_json_payload_string = string_replace_all(_final_json_payload_string, ".0}", "}");

    //show_debug_message(_final_json_payload_string);

    // Make the HTTP request
    self.request_id = http_request(_url, "POST", _headers_ds_map, _final_json_payload_string);
    
    ds_map_destroy(_headers_ds_map);

    // Timeout logic
    if (self.timeout_handle != noone) {
        call_cancel(self.timeout_handle);
    }
    self.timeout_handle = call_later(self.timeout_duration, time_source_units_seconds, function() {
        if (self.waiting && self.request_id != -1) {  
            self.waiting = false;
            self.request_id = -1;  
            show_debug_message("ANTHROPIC_API_INTERFACE Error: Request timed out.");
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

