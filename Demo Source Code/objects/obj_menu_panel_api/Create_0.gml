


elements = [instance_create_layer(x-224, y+256, layer, obj_panel_button, {
	par: id,
	action: "close",
	text: "OK",
	image_yscale: 0.6875
	}),
instance_create_layer(x-188, y-100, layer, obj_panel_button, {
	par: id,
	action: "api_left",
	text: "<",
	image_yscale: 0.6875,
	image_xscale: 0.6875
	}),
instance_create_layer(x+188, y-100, layer, obj_panel_button, {
	par: id,
	action: "api_right",
	text: ">",
	image_yscale: 0.6875,
	image_xscale: 0.6875
	}),
instance_create_layer(x+112, y+256, layer, obj_panel_button, {
	par: id,
	action: "api_paste",
	text: "Paste API key from clipboard",
	image_yscale: 0.6875,
	image_xscale: 2.75
	})
];
image_xscale = 6;
image_yscale = 6;

switch(global.api) {
	default:
	case "gemini": secondary_sprite = spr_gemini; break;
	case "openai": secondary_sprite = spr_openai; break;
	case "anthropic": secondary_sprite = spr_claude; break;
}

prelude_text = "This is a pre-release evaluation build. Providers are currently restricted to Google Gemini, ChatGPT, and Anthropic using temporary evaluation credentials. You may use custom endpoints through the OpenAI API by editing the \"Custom Endpoints.ini\" file";
text = prelude_text + "\n\n\n\n\n\n\nCurrent Provider:\n" + global.api + "\n\nAPI key:\n" + string_copy(global.key, 1, min(16, string_length(global.key))) + " . . .";
event_inherited();

