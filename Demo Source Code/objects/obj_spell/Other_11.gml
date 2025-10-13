/// @description Max turns reached
if spell_class == "aoe" or spell_class == "shield" {
	turns_left--;

	if turns_left < 0 {
		instance_destroy();
	}
}

