/// @description Init

#region Variable declarations

// Variables for staggering cellular automata updates for low-end systems
flip_flop = 0;
flops = 0;

// Variables for animating fading in and out
fade = 1;
fade_target = 0;

// Load fonts
global.countdown_font = font_add_sprite_ext(spr_countdown, "0123456789%.", true, 0);
global.rune_font = font_add_sprite_ext(spr_runes, "abcdefghijklmnopqrstuvwxyz0123456789", true, 1);

// Random seed
randomize();

// Start playing music and save a reference to it
global.music_ref = audio_play_sound(snd_music, 1, true);

// Variables for game state
global.current_team = 1;
global.mana = [100, 100];
global.paused = false;
global.spell_history = [];
global.winner = noone;

// Set warm up timer
alarm_set(0, 3 * game_get_speed(gamespeed_fps));

// Define the default elemental data structure
global.elemental_data = {
    elements: [
        "fire",
        "water",
        "ice",
        "electric",
        "poison",
        "wind",
        "earth",
        "plant",
        "neutral",
		"healing"
    ],

    "fire": {
        "RGB_COLOR": [255, 69, 0],
        "SOUND_LIB": "flaming",
        "fire": 0,
        "water": -1,
        "ice": 1,
        "electric": 0,
        "poison": 1,
        "wind": -1,
        "earth": -1,
        "plant": 1,
        "neutral": 0,
		"healing": 0
    },
    "water": {
        "RGB_COLOR": [30, 144, 255],
        "SOUND_LIB": "blowing",
        "fire": 1,
        "water": 0,
        "ice": -1,
        "electric": -1,
        "poison": 1,
        "wind": 0,
        "earth": 1,
        "plant": 0,
        "neutral": 0,
		"healing": 0
    },
    "ice": {
        "RGB_COLOR": [173, 216, 230],
        "SOUND_LIB": "crackling",
        "fire": -1,
        "water": 1,
        "ice": 0,
        "electric": 0,
        "poison": 1,
        "wind": -1,
        "earth": 1,
        "plant": 1,
        "neutral": 0,
		"healing": 0
    },
    "electric": {
        "RGB_COLOR": [255, 255, 0],
        "SOUND_LIB": "energetic",
        "fire": 0,
        "water": 1,
        "ice": 0,
        "electric": 0,
        "poison": -1,
        "wind": 0,
        "earth": -1,
        "plant": 1,
        "neutral": 0,
		"healing": 0
    },
    "poison": {
        "RGB_COLOR": [128, 0, 128],
        "SOUND_LIB": "blowing",
        "fire": -1,
        "water": -1,
        "ice": -1,
        "electric": 1,
        "poison": 0,
        "wind": -1,
        "earth": 1,
        "plant": 1,
        "neutral": 0,
		"healing": 0
    },
    "wind": {
        "RGB_COLOR": [176, 224, 230],
        "SOUND_LIB": "blowing",
        "fire": 1,
        "water": 0,
        "ice": 1,
        "electric": 0,
        "poison": 1,
        "wind": 0,
        "earth": 1,
        "plant": -1,
        "neutral": 0,
		"healing": 0
    },
    "earth": {
        "RGB_COLOR": [139, 69, 19],
        "SOUND_LIB": "crackling",
        "fire": 1,
        "water": -1,
        "ice": -1,
        "electric": 1,
        "poison": -1,
        "wind": -1,
        "earth": 0,
        "plant": 0,
        "neutral": 0,
		"healing": 0
    },
    "plant": {
        "RGB_COLOR": [34, 139, 34],
        "SOUND_LIB": "blowing",
        "fire": -1,
        "water": 0,
        "ice": -1,
        "electric": -1,
        "poison": -1,
        "wind": 1,
        "earth": 0,
        "plant": 0,
        "neutral": 0,
		"healing": 0
    },
    "neutral": {
        "RGB_COLOR": [169, 169, 169],
        "SOUND_LIB": "energetic",
        "fire": 0,
        "water": 0,
        "ice": 0,
        "electric": 0,
        "poison": 0,
        "wind": 0,
        "earth": 0,
        "plant": 0,
        "neutral": 0,
		"healing": 0
    },
    "healing": {
        "RGB_COLOR": [255, 255, 200],
        "SOUND_LIB": "blowing",
        "fire": 0,
        "water": 0,
        "ice": 0,
        "electric": 0,
        "poison": 0,
        "wind": 0,
        "earth": 0,
        "plant": 0,
        "neutral": 0,
		"healing": 0
    }
}

// Variables for team information and turn-taking
global.team_colors = [noone, noone];
global.team_colors[0] = choose(dull_yellow, happy_red, grumpy_blue, wonder_green);
global.team_colors[1] = choose(dull_yellow, happy_red, grumpy_blue, wonder_green);
global.round_team_fifo = [];
global.square_team_fifo = [];

while(global.team_colors[0] == global.team_colors[1]) {
	global.team_colors[1] = choose(dull_yellow, happy_red, grumpy_blue, wonder_green);
}

for (var i=0; i<3; i++) {
	array_insert(global.round_team_fifo, 0, instance_create_layer(random(room_width), 64, layer, obj_mage_round));
	array_insert(global.square_team_fifo, 0, instance_create_layer(random(room_width), 64, layer, obj_mage_square));
}


// Variables for tracking spell data
global.current_input_spell_name = "Beebo's Heavy Stone Orb";
global.user_provided_input_string = "Aegis of the Frost Wyrm";
global.latest_spell_data = "";
global.last_user_prompt = "";

// Camera variables
global.camera_focus_x = room_width/2;
global.camera_focus_y = room_height/2;
global.camera_zoom = 1;

// Instantiate LLM
global.patron = new LLM(global.api, global.key);

#endregion

#region Particle systems

global.partsys = part_system_create_layer(layer_get_id("PartSys"), false);
part_system_draw_order(global.partsys, true);

// Gas particle
global.part_gas = part_type_create();
part_type_shape(global.part_gas, pt_shape_cloud);
part_type_size(global.part_gas, 1, 2, 0, 0);
part_type_scale(global.part_gas, 1, 1);
part_type_speed(global.part_gas, 0, 0.5, 0, 0);
part_type_direction(global.part_gas, 0, 360, 0, 0);
part_type_gravity(global.part_gas, 0, 270);
part_type_orientation(global.part_gas, 0, 360, 0, 0, false);
part_type_colour3(global.part_gas, $FFFFFF, $FFFFFF, $FFFFFF);
part_type_alpha3(global.part_gas, 0, 1, 0);
part_type_blend(global.part_gas, false);
part_type_life(global.part_gas, 60, 120);

// Projectile particle
global.part_proj = part_type_create();
part_type_shape(global.part_proj, pt_shape_spark);
part_type_size(global.part_proj, 0.5, 1, 0, 0);
part_type_scale(global.part_proj, 1, 1);
part_type_speed(global.part_proj, 0, 0, 0, 0);
part_type_direction(global.part_proj, 0, 360, 0.1, 0);
part_type_gravity(global.part_proj, 0, 270);
part_type_orientation(global.part_proj, 0, 360, 0, 0, false);
part_type_colour3(global.part_proj, $FFFFFF, $FFFFFF, $FFFFFF);
part_type_alpha3(global.part_proj, 1, 0.439, 0);
part_type_blend(global.part_proj, false);
part_type_life(global.part_proj, 10, 30);

// AoE particle
global.part_aoe = part_type_create();
part_type_sprite(global.part_aoe, spr_aoe, false, true, true)
part_type_size(global.part_aoe, 0.9, 1.1, 0.001, 0);
part_type_scale(global.part_aoe, 1, 1);
part_type_speed(global.part_aoe, 0, 0, 0, 0);
part_type_direction(global.part_aoe, 0, 360, 0.1, 0);
part_type_gravity(global.part_aoe, 0, 270);
part_type_orientation(global.part_aoe, 0, 360, 0, 0, false);
part_type_colour3(global.part_aoe, $FFFFFF, $FFFFFF, $FFFFFF);
part_type_alpha3(global.part_aoe, 0, 0.1, 0);
part_type_blend(global.part_aoe, false);
part_type_life(global.part_aoe, 120, 180);

// Shield particle
global.part_shield = part_type_create();
part_type_sprite(global.part_shield, spr_shield, false, true, true)
part_type_size(global.part_shield, 0.9, 1.1, 0.001, 0);
part_type_scale(global.part_shield, 1, 1);
part_type_speed(global.part_shield, 0, 0, 0, 0);
part_type_direction(global.part_shield, 0, 360, 0.1, 0);
part_type_gravity(global.part_shield, 0, 270);
part_type_orientation(global.part_shield, 0, 360, 0, 0, false);
part_type_colour3(global.part_shield, $FFFFFF, $FFFFFF, $FFFFFF);
part_type_alpha3(global.part_shield, 0, 0.251, 0);
part_type_blend(global.part_shield, false);
part_type_life(global.part_shield, 120, 180);

// Explosion particle
global.part_explosion = part_type_create();
part_type_sprite(global.part_explosion, spr_explosion, false, true, true)
part_type_size(global.part_explosion, 0.1, 0.3, 0.02, 0.01);
part_type_scale(global.part_explosion, 1, 1);
part_type_speed(global.part_explosion, 0, 1, 0, 0);
part_type_direction(global.part_explosion, 0, 360, 0.1, 0);
part_type_gravity(global.part_explosion, 0, 270);
part_type_orientation(global.part_explosion, 0, 360, 0, 0, false);
part_type_colour3(global.part_explosion, $FFFFFF, $FFFFFF, $FFFFFF);
part_type_alpha3(global.part_explosion, 1, 0.431, 0);
part_type_blend(global.part_explosion, false);
part_type_life(global.part_explosion, 15, 45);

// Pop particle
global.part_pop = part_type_create();
part_type_sprite(global.part_pop, spr_explosion, false, true, true)
part_type_size(global.part_pop, 0.05, 0.15, 0.02, 0.01);
part_type_scale(global.part_pop, 1, 1);
part_type_speed(global.part_pop, 0, 1, 0, 0);
part_type_direction(global.part_pop, 0, 360, 0.1, 0);
part_type_gravity(global.part_pop, 0, 270);
part_type_orientation(global.part_pop, 0, 360, 0, 0, false);
part_type_colour3(global.part_pop, $FFFFFF, $FFFFFF, $FFFFFF);
part_type_alpha3(global.part_pop, 1, 0.431, 0);
part_type_blend(global.part_pop, false);
part_type_life(global.part_pop, 10, 15);

#endregion

// Resize the window as necessary
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

// Add random clouds to the background layer
for (i=0; i<16; i++) {
	instance_create_layer(random_range(-room_width, room_width*2), random_range(0, room_height / 2), layer_get_id("BackgroundObjects"), obj_cloud);
}