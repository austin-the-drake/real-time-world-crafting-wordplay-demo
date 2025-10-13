


elements = [instance_create_layer(x, y+256, layer, obj_panel_button, {
	par: id,
	action: "close",
	text: "OK",
	image_yscale: 0.6875
	})];
image_xscale = 6;
image_yscale = 6;


text = "Latent Space is an educational project designed to demonstrate how Large Language Models can translate natural language descriptions into rule-based scripts for generating creative effects. This game implements the conversion of natural language instructions into executable sequences to test AI's capacity for understanding and implementing complex symbolic systems.\n\nBattle mode allows players to script unique abilities for their combatants using natural language.\n\nAlchemy mode allows users to describe desired behaviors for particle-based cellular automata, with the LLM then generating the underlying simulation rules.";
event_inherited();

