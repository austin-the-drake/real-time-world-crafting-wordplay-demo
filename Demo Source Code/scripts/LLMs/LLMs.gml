// LLM constructor
// This constructor simply wraps the API-specific objects and provides a simple interface for them
function LLM(api, api_key) constructor {
    // Check if the provided API is supported
    if (api != "gemini") and (api != "openai") and (api != "anthropic") {
        show_debug_message("Error: Unsupported API type. Only 'gemini', 'openai', and 'anthropic' are supported.");
        return;
    }
    
    // Create an instance of llm_http_handler, passing in the api_key
    var handler;
	switch(api) {
		default: {
			show_debug_message("Shouldn't be possible");
		} break;
		case "gemini": {
			handler = instance_create_layer(0, 0, "Instances", GEMINI_API_INTERFACE, {api_key: api_key});
		} break;
		case "openai": {
			handler = instance_create_layer(0, 0, "Instances", OPENAI_API_INTERFACE, {api_key: api_key});
		} break;
		case "anthropic": {
			handler = instance_create_layer(0, 0, "Instances", ANTHROPIC_API_INTERFACE, {api_key: api_key});
		} break;
	}
    
    // Set up struct methods:
    self.prompt = function(headers, body, callback) {
        // Since all requests are POST, we only need headers, prompt body, and callback
        handler.send_request(headers, body, callback);
    };
    
    self.set_instructions = function(instr) {
        handler.set_instructions(instr);
    };
    
    self.set_generation_config = function(genConfig) {
        handler.set_generation_config(genConfig);
    };
    
    self.destroy = function() {
        if (instance_exists(handler)) {
            instance_destroy(handler);
        }
        handler = noone;
    };
    
    self.handler = handler;
};