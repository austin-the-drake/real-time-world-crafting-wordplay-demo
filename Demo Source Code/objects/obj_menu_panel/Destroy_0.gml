
if array_length(elements) > 0 {
	for (var i=0; i < array_length(elements); i++) {
		with(elements[i]) {
			instance_destroy();
		}
	}
}