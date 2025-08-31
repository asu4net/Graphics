Window :: struct {
    handle : *Window_Type;
    width  : int;
    height : int;
}

init_window :: (using window: *Window, name := "game", w := 1280, h := 720, bg := DARK_PURPLE) -> bool {

    width  = w;
    height = h;
    
    assert(handle == null);
    
    handle = create_window(width, height, name, background_color_rgb = .[ bg.x, bg.y, bg.z ]); 
    
    if !handle {
        log_error("Failed to create the window.");
        return false;
    }
    
    return true;
}

swap_buffers :: inline (using window: *Window)  {
    swap_buffers(window.handle);    
}

process_window_events :: (using window: *Window, done: *bool) {
    update_window_events();
    
    resizes := get_window_resizes();
    
    if resizes.count {
        last := resizes[resizes.count - 1];
        width  = last.width;
        height = last.height;
    }

    for events_this_frame {

        should_close: bool;

        if it.type == .QUIT 
        then should_close = true;

        #if DEBUG {
            if it.type == .KEYBOARD && it.key_code == .ESCAPE
            then should_close = true;
        }

        if done != null then done.* = should_close;
    }
}