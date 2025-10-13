/// @description End of a turn

struct_foreach(passive_damage_this_turn, function(_name, _value) {
	if _name != "healing" {
		life -= _value;
	} else {
		life += _value;
	}
});
ready_to_cast=false;
passive_damage_this_turn = {};
aim_power = 0;
aim_angle = 0;
status_color = c_white;

if life <= 0 {
	instance_destroy();
}