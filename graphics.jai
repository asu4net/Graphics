Attachment :: enum u8 {
    COLOR;
    PX_ID;
    DEPTH;
}

Graphics_State :: struct {
    title         : string;
    viewport      : Vector2;
    fb            : Frame_Buffer;
    fb_tex        : Texture;
    fb_shader     : Shader;
    pixel_id      : int;
    clear_color   : Vector4;
}

#add_context gfx_state: *Graphics_State;

get_state :: inline () => context.gfx_state;
is_state_created :: inline () => context.gfx_state != null; 

#scope_module
set_state :: inline (state: *Graphics_State) { context.gfx_state = state; };
#scope_export

run :: (name := "game", width := 1280, height := 720, vsync := true, bg_tint := DARK_PURPLE) {
    if is_state_created() then end();
    set_state(New(Graphics_State));
    using state := get_state();
    
    title = name;
    clear_color = bg_tint;
    
    set_working_directory(String.path_strip_filename(System.get_path_of_running_executable()));
    init_window(name, width, height, bg_tint);
    
    create_graphics_context(context.window.handle);
    set_vsync_enabled(vsync);
    
    init_renderer2d();
}

end :: () -> bool {
    if !is_state_created() then return false;
    using state := get_state();
    
    // This texture is managed by the fb, there is no need to delete it.
    Initialize(*fb_tex);
    deinit_frame_buffer(*fb);
    deinit_shader(*fb_shader);
    deinit_renderer2d();
    set_state(null);
    free(state);
    #if DEBUG then report_memory_leaks();
    return true;
}

draw_begin :: () {
    using state := get_state();

    //#TODO_asuarez: Simplify this spagetti code.
    update_viewport_and_frame_buffer :: () {
        using app := get_state();
        window := get_window();
        if viewport.x.(int) != window.width || viewport.y.(int) != window.height {
            using app := get_state();
            viewport.x = xx window.width;
            viewport.y = xx window.height;
            set_renderer2d_viewport(viewport);
            if !is_frame_buffer_initialized(*fb) {
                spec := Frame_Buffer.Spec.{
                    width  = xx viewport.x,
                    height = xx viewport.y,
                    attachments = .[ .{.RGBA8}, .{.RED_INTEGER}, .{.DEPTH24STENCIL8} ]
                };
                init_frame_buffer(*fb, spec);
                // This is a bit hacky, sorry.
                fb_tex.id = fb.color_attachments[0];
                fb_tex.spec.width  = xx viewport.x;
                fb_tex.spec.height = xx viewport.y;
                init_shader(*fb_shader, .QUAD);
            }
            resize_frame_buffer(*fb, xx viewport.x, xx viewport.y);
        }
    }

    update_viewport_and_frame_buffer();
    bind_frame_buffer(*fb);
    clear_frame_buffer_color_and_depth(tint = clear_color);
    clear_frame_buffer_attachment(*fb, xx Attachment.PX_ID, S32_MAX);
}

draw_end :: () {
    using state := get_state();

    flush_renderer2d();

    mouse_pos := get_mouse_pos();
    mouse_pos.y = viewport.y - mouse_pos.y - 1;
    pixel_id = read_pixel(*fb, xx Attachment.PX_ID, mouse_pos);
    
    unbind_frame_buffer();
    draw_gui_quad(.{ tex = *fb_tex, shader = *fb_shader, flags = .NONE });
    flush_renderer2d();
}

// The current mouse-hovered pixel id.
get_pixel_id :: inline () -> int {
    using state := get_state();
    return pixel_id;
}

get_mouse_world_pos :: inline () -> Vector2 {
    using state := get_state();
    pv := context.renderer2d.pv_matrix_world;
    mouse_pos := get_mouse_pos();
    return screen_to_world(pv, mouse_pos, viewport);
}