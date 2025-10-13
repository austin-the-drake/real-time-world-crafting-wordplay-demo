/// @description Update cellular automata

// Stagger cellular automata updates for low-spec systems
flip_flop ++;
if flip_flop > flops {
	flip_flop = 0;
}

// Call the update routine for all active cells
with(obj_cell) {
	if (floor(x/16) + floor(y/16)) % (1 + obj_controller.flops) == obj_controller.flip_flop {
		event_perform(ev_other, ev_user0);
	}
}