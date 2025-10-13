
// Requires that the API key be passed as the first argument when this instance is created

if (not variable_instance_exists(self, "api_key")) {
    show_debug_message("Error: API key must be provided to GEMINI_API_INTERFACE instance!");
    api_key = "";
}

// Set the endpoint solely within this object using the instance variable api_key
endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=" + api_key;

// Internal state variables
waiting = false;
request_id = -1;
http_callback = noone;
timeout_handle = noone;
timeout_duration = 30;

// System instructions and generation config
instructions = "";
generation_config = "";

// Define a method to set system instructions
set_instructions = function(instr_text) {
    self.instructions = instr_text;
};

// Define a method to set the generation configuration
set_generation_config = function(gen_config_json_string) {
    self.generation_config = gen_config_json_string;
};

// Define the method to send an HTTP request
send_request = function(_headers_ds_map, _body_text_prompt, _callback_func) {
    if (self.waiting) {
        show_debug_message("LLM Info: A request is already in progress. Please wait.");
        if (is_callable(_callback_func)) {
            var _error_response_map = ds_map_create();
            ds_map_add(_error_response_map, "error", "busy");
            ds_map_add(_error_response_map, "message", "LLM interface is already waiting for a response.");
            _callback_func(_error_response_map);
            ds_map_destroy(_error_response_map);
        }
        return;
    }
    
    self.waiting = true;
    self.http_callback = _callback_func;
    
    var _url = self.endpoint;
    
    // Build the payload
    var _payload_root_struct = {};

    // Add contents (User's prompt)
    _payload_root_struct.contents = [
        {
            role: "user",
            parts: [
                { text: _body_text_prompt }
            ]
        }
    ];

    // Add system_instruction (if available)
    if (self.instructions != "") {
        _payload_root_struct.system_instruction = {
            parts: [
                { text: self.instructions }
            ]
        };
    }
    
    // Add generationConfig (if available)
    if (self.generation_config != "") {
        var _gen_conf_parsed_struct = json_parse(self.generation_config);
        if (is_struct(_gen_conf_parsed_struct)) {
            _payload_root_struct.generationConfig = _gen_conf_parsed_struct;
        } else {
            show_debug_message("LLM Warning: Could not parse generation_config string into a struct. It will not be included. Check format: " + self.generation_config);
        }
    }
    
    // Encode the entire payload struct to a JSON string
    var _final_json_payload_string = json_stringify(_payload_root_struct);
    show_debug_message("LLM Payload (Sent by GEMINI_API_INTERFACE): " + _final_json_payload_string);

    // Make the HTTP request
    self.request_id = http_request(_url, "POST", _headers_ds_map, _final_json_payload_string);
    
    // Timeout logic
    if (self.timeout_handle != noone && !is_undefined(self.timeout_handle)) {
         call_cancel(self.timeout_handle);
    }
    self.timeout_handle = call_later(self.timeout_duration, time_source_units_seconds, function() {
        if (self.waiting && self.request_id != -1) { 
            self.waiting = false;
            self.request_id = -1; 
            show_debug_message("LLM Error: Request timed out.");
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