// This event is triggered when an HTTP request completes or updates its status

// First, check if this async event corresponds to the request we sent
if (async_load[? "id"] == request_id) {

    switch (async_load[? "status"]) {

        // The request is still in progress
        // The event will be triggered again later when the status changes
        // We just ignore it for now and let the event pass
        case 1: {
            show_debug_message("HTTP Request (id: " + string(request_id) + ") is still in progress...");
		} break;

        // The request finished successfully
        case 0: {
            show_debug_message("HTTP Request (id: " + string(request_id) + ") finished successfully.");
            show_debug_message("Response Details: " + string(async_load));

            // Cancel the timeout callback since we got a response
            if (timeout_handle != noone) {
                call_cancel(timeout_handle);
                timeout_handle = noone;
            }

            // Pass the full response data to the provided callback
            if (is_callable(http_callback)) {
                http_callback(async_load);
            }

            // Reset state variables for the next request
            waiting = false;
            request_id = -1;
		} break;

        // The request failed
        default: {
            show_debug_message("HTTP Request (id: " + string(request_id) + ") failed!");
            show_debug_message("Failure Details: " + string(async_load));

            // Cancel the timeout callback
            if (timeout_handle != noone) {
                call_cancel(timeout_handle);
                timeout_handle = noone;
            }

            if (is_callable(http_callback)) {
                http_callback(async_load);
            }

            // Reset state variables for the next request
            waiting = false;
            request_id = -1;
		} break;
    }
}