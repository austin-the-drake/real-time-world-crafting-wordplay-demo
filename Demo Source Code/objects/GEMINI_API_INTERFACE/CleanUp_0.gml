
if (self.timeout_handle != noone && !is_undefined(self.timeout_handle)) {
    call_cancel(self.timeout_handle);
    self.timeout_handle = noone;
    show_debug_message("GEMINI_API_INTERFACE: Pending timeout cancelled.");
}