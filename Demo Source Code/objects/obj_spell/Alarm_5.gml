/// @description buffCaster

caster.life += heal_amount;

if resist_to != noone {
	if not array_contains(caster.armor_elements, resist_to) {
		array_push(caster.armor_elements, resist_to);
	}
}

instance_destroy();