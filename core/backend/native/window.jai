Window :: struct {
    Process_Events_Proc     :: #type (event: Event); 
    Process_Events_Callbacs :: [..] Process_Events_Proc;
    
    handle    : *Window_Type;
    width     : int;
    height    : int;
    callbacks : Process_Events_Callbacs;
}

#run #if !DEBUG then disable_runtime_console();

#add_context window: *Window;

is_window_created :: inline () => context.window != null;
get_window :: inline () => context.window;

#scope_module
set_window :: inline (state: *Window) { context.window = state; };
#scope_export

init_window :: (name := "game", w := 1280, h := 720, bg := DARK_PURPLE) -> bool {
    if is_window_created() then return false;
    set_window(New(Window));
    using window := get_window();
    
    width  = w;
    height = h;
    
    assert(handle == null);
    
    #if OS == .WINDOWS {
        windows :: #import "Windows";
        windows.SetProcessDPIAware();

        // Windows is very bad at thread-switching by default unless you do this. Sad.
        windows.timeBeginPeriod(1);
    }

    handle = create_window(width, height, name, background_color_rgb = .[ bg.x, bg.y, bg.z ]); 
    
    if !handle {
        log_error("Failed to create the window.");
        return false;
    }
    
    return true;
}

swap_buffers :: inline ()  {
    window := get_window();
    swap_buffers(window.handle);
    reset_temporary_storage();
}

set_window_callback :: inline (callback: Window.Process_Events_Proc) {
    window := get_window();
    array_add(*window.callbacks, callback);
}

process_events :: (done: *bool = null) {
    update_window_events();
    using window := get_window();
    resizes := get_window_resizes();
    
    if resizes.count {
        last := resizes[resizes.count - 1];
        width  = last.width;
        height = last.height;
    }

    for events_this_frame {

        for callback: callbacks {
            callback(it);
        }
        
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