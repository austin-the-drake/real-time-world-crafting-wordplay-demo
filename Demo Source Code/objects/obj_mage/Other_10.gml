/// @description Spell prompting
if global.current_team == my_team and my_turn {
show_debug_message("Prompting LLM for spell script...");

// Find the active LLM
var _llm_interface = noone;
if (variable_instance_exists(self, "myLLM")) { _llm_interface = self.myLLM; }
else if (variable_global_exists("patron")) { _llm_interface = global.patron; }

// Define spell input
global.current_input_spell_name = "user spell 0";
global.last_user_prompt = keyboard_string;
var current_input_spell_description = keyboard_string;

// Get current list of available elements and format as JSON string
var _current_elements_array = global.elemental_data.elements;
var _available_elements_json_array_string = json_stringify(_current_elements_array);

show_debug_message("Available elements for LLM: " + _available_elements_json_array_string);

// System instructions
var spell_script_system_instructions = "";
_llm_interface.set_instructions(spell_script_system_instructions);

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

// HTTP Headers
var spell_script_http_headers_map = ds_map_create();
ds_map_add(spell_script_http_headers_map, "Content-Type", "application/json");

// Construct the full prompt to send to the LLM
var spell_script_user_prompt_text = @'
You are an AI game design assistant. Your task is to generate a JSON object that defines a magical spell using a component-based system.
The spell will be based on a provided description.

**Overall Goal:**
Create a single JSON object.
The very first key in the root object must be "planning", containing a brief paragraph (2-3 sentences) of reasoning that outlines the plan for which components to use.
The root of this object must always contain the key: `"components"`.
The value of `"components"` must be an array of individual component objects.
The top-level spell may optionally contain the key: `"count"` when strictly appropriate for multi-cast.
The top-level spell must finally contain the key: `"friendlyName"` containing a creative 2-3 word name for future reference.
**Strict Output Requirements:**
* The entire response MUST be a single, valid JSON object.
* Do NOT include any explanatory text, markdown formatting, or anything outside this single JSON object.
* Use ONLY the `componentType`s and their associated properties as defined below.
* For fields with "Possible Options" or specific enumerated values, you MUST choose a value from the provided list(s).
Do not invent new string values for these fields.
* If a property is optional and not relevant to the spell concept, omit it.
* Properties of a spell are never automatically inherited by sub-spells; they must be repeated as necessary when using triggers.
* Always think creatively, and always consider whether to add sub-spells or physical manifestations when it could strengthen the concept.
* Numerical values should be sensible for a game context and fall within suggested ranges if provided.
--- Component Definitions ---

A spell is defined by an array under the `"components"` key.
Each object in this array is a component.

**I. Spell Class Components (Choose EXACTLY ONE as the primary form of the spell or sub-spell. Using more than one REQUIRES that they be placed in DIFFERENT nested triggers.):**

1.  `{ "componentType": "projectile", "radius": number (e.g., 2-20), "speed": number (e.g., 10-20), "bounces": integer (optional, default 0, e.g., 0-5, 999 for infinite), "gravity": number (optional, default 0.25, e.g., 0.0-0.5) }`
    * `description`: Defines the spell as a projectile.
2.  `{ "componentType": "wallCrawl", "radius": number (e.g., 5-15), "speed": number (e.g., 5-25) }`
    * `description`: A spell that moves along surfaces/walls.
3.  `{ "componentType": "aoe", "radius": number (e.g., 100-300), "turns": number of turns to persist for (e.g., 1-10) }`
    * `description`: An Area of Effect spell.
4.  `{ "componentType": "shield", "radius": number (e.g., 100-200), "turns": number of turns to persist for (e.g., 1-10) }`
    * `description`: A defensive shield, likely around the caster.
5.  `{ "componentType": "explosion", "radius": number (e.g., 64-256) }`
    * `description`: An instantaneous area burst.
Should often tend to manifest something on a deathTrigger in most cases.
6.  `{ "componentType": "teleportCaster" }`
    * `description`: Instantly teleports the caster and ends.
Primarily used as a payload.

7.  `{ "componentType": "buffCaster", "heal": number (optional, e.g., 5-100), "resist": "string (optional, an element from Available Elements)" }`
    * `description`: Instantly applies heal/resistance to caster and ends.
Primarily used as a payload.

8.  `{ "componentType": "manifestation", "radius": number (e.g., 2-10, for spawn radius in 16x16 grid cells), "material_properties": { ... } }`
    * `description`: Creates a physical object or substance.
This component ends the entire spell and cannot have its own trigger components, so it should only generally be used as the final subspell.
* `material_properties` (object, required):
        * `class` (string, required).
Possible Options: `"powder"`, `"liquid"`, `"gas"`, `"solid"`. Use powder for most dry materials, reserving solid for hard things like steel or ice.
* `color_rgb` (array of 3 integers [R,G,B], 0-255, required).
        * `blockpath` (boolean, required): whether the material is strong enough to support a heavy object atop it.
* `density` (integer, ordinal, required): `0.5` if light like helium or oil, `1` if roughly standard like water or air, `2` if dense like lava or fumes.
* `viscous` (boolean, optional, default `false`, use only for very thick substances like molases, lava, etc).
* `zombie` (boolean, optional, default `false`, converts other materials into this one upon contact).
* `elements` (array of strings, required, from Available Elements).
        * `harmful` (boolean, optional, whether the material is inherently harmful to all players, e.g., lava or poison gas).
* `lifespan` (number, optional, in seconds, e.g., 0.5-999): Duration the manifestation persists.
Should almost always be omitted, unless a lifespan is an essential property of the material, e.g., a flame.

**II.
General Spell Property Components (Add as needed):**

9.  `{ "componentType": "element", "element": "string" }` (element from Available Elements, can use multiple. Not inherited by subspells by default, so always add them again to subspells!).
10. `{ "componentType": "color", "rgb": [integer, integer, integer] }` (Primary VFX color, IGNORED for `manifestation`, only ONE per spell).
11. Spawning Orientation (Choose AT MOST ONE if spell has a direction):
    * `{ "componentType": "spawnAngle", "angle": number (0-359, 0 is right, positive is counterclockwise) }`
    * `{ "componentType": "spawnRandAngle" }`

12. `{ "componentType": "manaCost", "cost": number (e.g., 5-100) }`

**III.
Behavior Modifier Components (Can be stacked; primarily affect `projectile` or `wallCrawl`):**

13. `{ "componentType": "homing", "strength": number (e.g., 0.05-0.5) }` (Seeks enemies).
14. `{ "componentType": "boomerang", "strength": number (e.g., 0.05-0.5) }` (Seeks caster).
15. `{ "componentType": "controllable", "mana_cost": number (optional, e.g., 0.01-1 per 1/60th of a second) }` (Player guides).

**IV.
Trigger Components (Define sub-spells or effects triggered by conditions):**
* All triggers require a `payload_components` property.
* `payload_components` (array, required): An array of component objects defining the new sub-spell (follows these same component rules).
16. `{ "componentType": "timerTrigger", "secs": number (e.g., 0.1-5.0), "loop": boolean (optional, default false), "reps": integer (optional, default 1, e.g., 1-10), "replace": boolean (optional, default false), "count": integer (optional, default 1, e.g., 1-5), "payload_components": [ ... ] }`

17. `{ "componentType": "buttonTrigger", "reps": integer (optional, default 1, e.g., 1-5), "replace": boolean (optional, default false), "count": integer (optional, default 1, e.g., 1-5), "payload_components": [ ... ] }`

18. `{ "componentType": "impactTrigger", "reps": integer (optional, default 1, e.g., 1-5 for non-replace), "replace": boolean (optional, default false), "count": integer (optional, default 1, e.g., 1-5), "payload_components": [ ... ] }` (If `replace` is true, `reps` is typically 
1; `loop` and `secs` are ignored for the trigger itself).
19. `{ "componentType": "deathTrigger", "count": integer (optional, default 1, e.g., 1-5), "payload_components": [ ... ] }` (`replace` not applicable).
---

--- Examples to help you understand the task ---

Example Input: "A small tomato with a satisfying heft to it"
Example Available Elements: `["fire", "water", "earth", "plant", "darkness"]`
Example Output JSON:
```json
{"planning":"The user wants a small tomato, which is best represented as a projectile with a small radius.
The phrase satisfying heft suggests it should have some gravity.
The implied action is that it splats on impact, which requires an impactTrigger that replaces the projectile with a manifestation of a red, powder-class material to simulate the splat.",
"friendlyName":"Summon plump tomato","count":1,"components":[
{"componentType":"projectile","radius":2,"speed":15},
{"componentType":"element","element":"plant"},
{"componentType":"color","rgb":[255,64,64]},
{"componentType":"impactTrigger","replace":true,"payload_components":[
{"componentType":"manifestation","radius":4,"material_properties":{"class":"powder","color_rgb":[255,64,64],"blockpath":true,"density":1,"elements":["plant"]}}]}]}
```

Example Input: "A volley of flaming arrows"
Example Available Elements: `["fire", "water", "earth", "wind", "arcane"]`
Example Output JSON:

```json
{"planning":"The user requested a volley of fast arrows, which implies a base projectile component with a top-level count of 3 to represent the multiple arrows.
The phrase erupts on impact necessitates an impactTrigger component to define the secondary effect.
The payload for this trigger will be a manifestation of a gas class with a fire element to create the fiery cloud effect.",
"friendlyName":"Singeing Arrow Volley","count":3,"components":[
{"componentType":"projectile","radius":5,"speed":15,"gravity":0.25},
{"componentType":"element","element":"fire"},
{"componentType":"color","rgb":[255,60,0]},
{"componentType":"manaCost","cost":10},
{"componentType":"impactTrigger","reps":1,"payload_components":[
{"componentType":"manifestation","radius":5,"material_properties":{"class":"gas","color_rgb":[255,100,0],"solid":0,"density":0.1,"viscous":false,"spreads":true,"elements":["fire"],"lifespan":1.0}}]}]}
```

Example Input: "A mote of light controlled by telekinesis.
It is bound to my soul and allows me to walk the planes between realities."
Example Available Elements: `["fire", "water", "earth", "wind", "ice"]`
Example Output JSON:

```json
{"planning":"The core concept is a mote of light, best represented as a projectile.
The phrase controlled by telekinesis directly maps to the controllable component.
The key function, walk the planes between realities, implies teleportation, which is handled by the teleportCaster component.
Since this action is user-activated, it should be placed within a buttonTrigger as the payload.",
"friendlyName":"Controllable orb of teleportation","count":1,"components":[
{"componentType":"projectile","radius":2,"speed":15,"bounces":5,"gravity":0.1},
{"componentType":"element","element":"wind"},
{"componentType":"color","rgb":[188,188,188]},
{"componentType":"controllable","mana_cost":0.1},
{"componentType":"buttonTrigger","replace":true,"payload_components":[
{"componentType":"teleportCaster"}]}]}
```

Example Input: "A mischievous fire sprite that explores the map and sends out homing flames on button press"
Example Available Elements: `["fire", "water", "earth", "wind", "arcane"]`
Example Output JSON:

```json
{"planning":"The primary form is a sprite that explores, which suggests a mobile entity; wallCrawl is a good fit.
The main action is triggered on button press, which requires a buttonTrigger.
The payload of this trigger is the homing flames, which must be a new projectile sub-spell that includes a homing component and a fire element.
The plural flames suggests using the count property on the trigger to create a volley.",
"friendlyName":"Devilish fire sprite","count":1,"components":[
{"componentType":"wallCrawl","radius":7,"speed":10},
{"componentType":"element","element":"fire"},
{"componentType":"color","rgb":[255,60,0]},
{"componentType":"buttonTrigger","replace":true,"count":5,"payload_components":[
{"componentType":"projectile","radius":3,"speed":15,"bounces":3,"gravity":0},
{"componentType":"element","element":"fire"},
{"componentType":"color","rgb":[255,60,0]},
{"componentType":"spawnRandAngle"},
{"componentType":"homing","strength":0.1},
{"componentType":"deathTrigger","payload_components":[
{"componentType":"manifestation","radius":2,"material_properties":{"class":"gas","color_rgb":[255,100,0],"blockpath":false,"density":0.5,"elements":["fire"],"harmful":true,"lifespan":3}}]}]}]}
```

Example Input: "A bouncing blob of magma that leaves a lava trail in its wake"
Example Available
Elements: `["fire", "water", "earth", "wind", "arcane"]`
Example Output JSON:

```json
{"planning":"The spell is a bouncing blob of magma, which is a projectile with the bounces property.
The lava trail effect requires an impactTrigger that does not replace the projectile (replace: false) and fires multiple times (reps), once for each bounce.
The payload for this trigger is a manifestation of a viscous, fiery liquid to create the lava.
A final deathTrigger with an explosion payload provides a satisfying end for the magma blob.",
"friendlyName":"Magma catapault","count":1,"components":[
{"componentType":"projectile","radius":10,"speed":15,"bounces":5},
{"componentType":"element","element":"fire"},
{"componentType":"color","rgb":[255,60,0]},
{"componentType":"impactTrigger","reps":6,"replace":false,"payload_components":[
{"componentType":"manifestation","radius":2,"material_properties":{"class":"liquid","color_rgb":[255,100,0],"blockpath":false,"density":1,"elements":["fire"],"viscous":true,"harmful":true,"lifespan":30}}]},
{"componentType":"deathTrigger","payload_components":[
{"componentType":"explosion","radius":128},
{"componentType":"element","element":"fire"},
{"componentType":"color","rgb":[255,60,0]}]}]}
```

-----

**Your Task:**

Generate the JSON object containing a `"components"` array for the spell concept provided below.
Ensure all your choices and values adhere to the definitions, constraints, and suggested ranges listed above.
The user description of a magical spell will be provided first, followed by a list of all magical elements available in your toolbox.
' + "Your spell concept is: " + current_input_spell_description + "\\n" +
"Your available elements are: " + _available_elements_json_array_string;


// Define the callback function to be called when a response is recieved
// A lot of messy error handling here, some outdated
var spell_script_callback = function(response_from_llm_lib) {
    show_debug_message("Spell script callback triggered");

    var _error_msg = ds_map_find_value(response_from_llm_lib, "error");
    var _msg_details = ds_map_find_value(response_from_llm_lib, "message");

    if (_error_msg != undefined && string_length(string(_error_msg)) > 0) {
        show_debug_message("LLM Error (Spell Script): " + string(_error_msg));
		if string(_error_msg) == "timeout" {
			with(obj_mage) {
				waiting_for_response = false;
			}
		}
        if (_msg_details != undefined) { show_debug_message("Details: " + string(_msg_details)); }
        var _raw_body_if_error = ds_map_find_value(response_from_llm_lib, "response_body_string");
        if (_raw_body_if_error != undefined) { show_debug_message("Raw error response body: " + string(_raw_body_if_error));}
        return;
    }

    var _gemini_response_json_string = ds_map_find_value(response_from_llm_lib, "result");
	show_debug_message("Result field of response object: " + string(_gemini_response_json_string));
    var _parsed_gemini_response_struct = undefined;
    var _llm_generated_spell_script_json_text = undefined;

    if (is_string(_gemini_response_json_string)) {
        _parsed_gemini_response_struct = json_parse(_gemini_response_json_string);
        if (is_struct(_parsed_gemini_response_struct)) {
            if (true) {
                 _llm_generated_spell_script_json_text = extract_text_from_llm_response(global.api, _parsed_gemini_response_struct);
            } else { 
                show_debug_message("true was not true");
            }
        } else {
            show_debug_message("Error: Could not parse main response string into a struct. Raw: " + _gemini_response_json_string);
        }
    } else {
        show_debug_message("Error: LLM 'result' was not a string for spell script response.");
    }
    
    if (is_string(_llm_generated_spell_script_json_text)) {
        show_debug_message("LLM Generated Spell Script JSON for '" + global.current_input_spell_name + "'");
        show_debug_message(_llm_generated_spell_script_json_text); 
        show_debug_message("----------------------------------------------------");
        
        var _test_parse_struct = json_parse(_llm_generated_spell_script_json_text);
        if (is_struct(_test_parse_struct)) {
            show_debug_message("Valid JSON, saved and equiped spell");
			global.latest_spell_data = _test_parse_struct;
			
			if global.doing_log {
				add_to_log("spellScripting", global.last_user_prompt, json_stringify(global.elemental_data.elements), _llm_generated_spell_script_json_text);
			}
			
			with(obj_mage) {
				event_perform(ev_other, ev_user1);
			}
			
        } else {
			if global.doing_log {
				add_to_log("spellScripting", global.last_user_prompt, json_stringify(global.elemental_data.elements),"INVALID JSON: " + _llm_generated_spell_script_json_text);
			}
		}
        
    } else {
        show_debug_message("Error: No spell script JSON text extracted from LLM response.");
        show_debug_message("Value of _llm_generated_spell_script_json_text: " + string(_llm_generated_spell_script_json_text));
		if global.doing_log {
			add_to_log("spellScripting", global.last_user_prompt, json_stringify(global.elemental_data.elements), _llm_generated_spell_script_json_text);
		}
		global.latest_spell_data = global.failure_spell;
			with(obj_mage) {
				event_perform(ev_other, ev_user1);
			}
		
    }
};

// Make the request
show_debug_message("Sending spell script JSON prompt to LLM for: " + global.current_input_spell_name);
_llm_interface.prompt(spell_script_http_headers_map, spell_script_user_prompt_text, spell_script_callback);

// Clean up data structures
ds_map_destroy(spell_script_http_headers_map);
}