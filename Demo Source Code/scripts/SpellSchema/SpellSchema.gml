

var master_spell = {
	components: [
	
	// Spell classes: these are all mutually exclusive
	{componentType: "projectile", radius: 10, bounces: 0, speed: 10, gravity: 0.25},
	{componentType: "wallCrawl", radius: 10, speed:10},
	{componentType: "aoe", radius: 10, secs: 5},
	{componentType: "shield", radius: 10, secs: 5},
	{componentType: "explosion", radius: 10},
	{componentType: "teleportCaster"},
	{componentType: "buffCaster", heal: 10, resist: "fire"},
	{componentType: "manifestation", radius: 3, "material_properties": {
		class: "liquid",
		color_rgb: [255, 64, 0],
		solid: 0,
		density: 2,
		viscous: true,
		spreads: false,
		elements: ["fire"]
		}},
	
	// More than one element component can be added per spell
	{componentType: "element", element: "fire"},
	
	// Only one color per spell
	{componentType: "color", rgb: [255, 150, 0]},
	
	// Spawning properties are mutually exclusive
	{componentType: "spawnAngle", angle: 270},
	{componentType: "spawnRandAngle"},
	
	// Mana consumed upon cast, or upon sub-spell creation
	{componentType: "manaCost", cost: 10},
	
	// Behavior components can be stacked
	{componentType: "homing", strength: 0.1},
	{componentType: "boomerang", strength: 0.1},
	{componentType: "controllable", mana_cost: 0.25},
	
	// Triggers contain another list of components for a new spell to spawn when activated
	{componentType: "timerTrigger", replace: false, count: 1, secs: 0.1, loop: true, reps: 999, payload_components: []},
	{componentType: "buttonTrigger", replace: false, count: 1, reps: 1, payload_components: []},
	{componentType: "impactTrigger", replace: false, count: 1, reps: 1, payload_components: []},
	{componentType: "deathTrigger", count: 1, payload_components: []},
	
	]
}

example_spell_data = {
	components: [
	{componentType: "projectile", radius: 10, speed: 15, gravity: 0.25},
	{componentType: "element", element: "wind"},
	{componentType: "controllable", mana_cost: 0.25},
	{componentType: "color", rgb: [255, 255, 255]},
	{componentType: "impactTrigger", replace: true, payload_components: [
		{componentType: "manifestation", radius: 3, material_properties: {
			class: "powder",
			color_rgb: [255, 224, 180],
			solid: 1,
			density: 1
			}}
		]}
	]
}