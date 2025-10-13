/// @description Paste code from clipboard

if keyboard_check(vk_control) {
	show_debug_message("ctrl+v detected");
	if array_contains(struct_get_names(ca_types), global.selected_element) {
		show_debug_message("calling import_element_from_clipboard()");
		import_element_from_clipboard();
	}
}

