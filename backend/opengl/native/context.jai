create_graphics_context :: (window: *Window_Type) {

    gl_create_context(window, 4, 4, compatibility = false, debug = DEBUG);
    gl_load(*gl);
    
    #if DEBUG {
        log("GL Vendor = %\n", to_string(glGetString(GL_VENDOR)));
        log("GL Version = %\n", to_string(glGetString(GL_VERSION)));
        gl_enable_debug_output(break_on_error = true);
        DumpGLErrors(tag = "context");
    }
}

swap_buffers :: inline (window: *Window_Type)  {
    
    #if OS == .WINDOWS {
        #import "Windows";
        dc := GetDC(window);
        SwapBuffers(dc);
    } else #if OS == .LINUX {
        info := find_window_info(window);
        if (!info) || !info.specific.glx_window {
            log_error("Simp: Attempt to swap_buffers on a previously unseen window!\n");
            return;
        }

        glXSwapBuffers(x_global_display, info.specific.glx_window);
    } else #if OS == .MACOS {
        // On macOS, OpenGL buffer swapping is done on the context, not on the view.
        // So we can only swap for the active window. (And you need to swap before switching to another view).
        NSOpenGLContext.flushBuffer(the_gl_context);
    } else #if OS == .ANDROID {
        // I think it's gonna make more sense for display and surface to be on the specific window info, then
        // we will have to get the window here like Linux does.
        eglSwapBuffers(the_egl_display, the_egl_surface);
    } else {
        assert(false);
    }
}