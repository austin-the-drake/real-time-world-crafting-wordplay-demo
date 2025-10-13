/// @description Clear world

for (var j=world_size-1; j>=0; j--) {
	for (var i=0; i<world_size; i++) {
		if (i==0) or (j==0) or (i==world_size-1) or (j==world_size-1) {
			set_cell(i, j, "wall", 100);
			//ca_grid[i][j] = ["wall", 100, 0];
		} else {
			set_cell(i, j, "air", 0);
			//ca_grid[i][j] = ["air", 0, 0];
		}
	}
}

garbage_collect_ca_types();