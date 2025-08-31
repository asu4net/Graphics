GUI_QUAD_PIXEL_WIDTH        :: 200;
GUI_QUAD_PIXEL_HEIGHT       :: 200;
WHITE_QUAD_SIZE             :: 200;
PIXEL_TO_WORLD              :: 1.0 / 500.0;

Quad_Vertex :: struct {
    position : Vector4;
    tint     : Vector4;
    uv       : Vector2;
    texture  : s32;
    entity   : s32;
}

QuadFlag :: enum_flags u16 {
    NONE;
    AUTOSIZE;
    FLIP_X;
    FLIP_Y;
}

Rect :: struct {
    x: s32; 
    y: s32; 
    width: int; 
    height: int;
}

is_rect_initialized :: inline (using rect: Rect) -> bool {
    return width != 0 || height != 0;
}

Quad :: struct {
    #as using base: Primitive2D;
    tex: *Texture;
    rect  := Rect.{};
    size  := ONE_2D;
    flags := QuadFlag.AUTOSIZE;
}

draw_quad :: (using quad: Quad = .{}) {
    draw_primitive2d(.QUAD, .ORTHO_WORLD, blend, shader);
    
    using state := context.renderer2d;
    vertex_positions := DEF_VERTEX_POSITIONS_2D;
    vertex_uvs := DEF_VERTEX_UVS_2D;

    vertex_colors: Vector4Verts2D = ---;
    for *vertex_colors it.* = tint;
    
    if tex != null {
        
        pixel_width  := tex.spec.width;
        pixel_height := tex.spec.height;

        use_subtex := is_rect_initialized(rect);

        if use_subtex {
            pixel_width  = xx rect.width;
            pixel_height = xx rect.height;
            sub_tex_uv(*vertex_uvs, tex, rect);
        }

        for *vertex_uvs multiply(it.*, tiling);
        flip_quad_vertex_uv(*vertex_uvs, xx .FLIP_X & flags, xx .FLIP_Y & flags);

        if .AUTOSIZE & flags {
            pixel_size := ifx use_subtex then {
                Vector2.{xx rect.width, xx rect.height};
            } else {
                Vector2.{xx tex.spec.width, xx tex.spec.height};
            }

            final_size := pixel_size * size * PIXEL_TO_WORLD;
            if tex == *white_texture then final_size *= WHITE_QUAD_SIZE;

            half_size := final_size / 2.0;

            vertex_positions[0] = .{ -half_size.x, -half_size.y, 0.0, 1.0 };
            vertex_positions[1] = .{  half_size.x, -half_size.y, 0.0, 1.0 };
            vertex_positions[2] = .{  half_size.x,  half_size.y, 0.0, 1.0 };
            vertex_positions[3] = .{ -half_size.x,  half_size.y, 0.0, 1.0 };
        }
    }
    
    for *vertex_positions it.* = transform * it.*;
    
    slot := assign_tex_slot(tex);

    for i : 0..VERTICES_PER_2D_PRIMITIVE - 1 {
        state.quad_batch[i + state.quad_count * VERTICES_PER_2D_PRIMITIVE] = .{
            vertex_positions[i], vertex_colors[i], vertex_uvs[i], slot, xx pixel_id
        };
    }    
    
    state.quad_index_count += INDICES_PER_2D_PRIMITIVE;
    state.quad_count += 1;
}

draw_gui_quad :: (using quad: Quad = .{ flags = .NONE }) {
    draw_primitive2d(.QUAD, .ORTHO_SCREEN, blend, shader);
    using state := context.renderer2d;

    vertex_positions: Vector4Verts2D = ---;
    vertex_colors: Vector4Verts2D = ---;
    
    vertex_uvs := DEF_VERTEX_UVS_2D;
    for *vertex_colors it.* = tint;

    pixel_size := Vector2.{ GUI_QUAD_PIXEL_WIDTH, GUI_QUAD_PIXEL_HEIGHT };

    use_subtex := is_rect_initialized(rect);

    if tex != null {
        
        if use_subtex then {
            pixel_size = Vector2.{ xx rect.width, xx rect.height };
            sub_tex_uv(*vertex_uvs, tex, rect);
        }
        else pixel_size = Vector2.{ xx tex.spec.width, xx tex.spec.height };

        for *vertex_uvs multiply(it.*, tiling);
        flip_quad_vertex_uv(*vertex_uvs, xx .FLIP_X & flags, xx .FLIP_Y & flags);
    }

    p := viewport;

    if flags & .AUTOSIZE {
        coef_x := viewport / viewport_gui;
        coef_y := viewport / viewport_gui;
        coef := min(coef_x, coef_y);
        p = multiply(pixel_size * coef, size);
    }

    vertex_positions[0] = .{ 0.0, p.y, 0.0, 1.0 };
    vertex_positions[1] = .{ p.x, p.y, 0.0, 1.0 };
    vertex_positions[2] = .{ p.x, 0.0, 0.0, 1.0 };
    vertex_positions[3] = .{ 0.0, 0.0, 0.0, 1.0 };
    
    for *vertex_positions it.* = transform * it.*;
    
    slot := assign_tex_slot(tex);

    for i: 0..VERTICES_PER_2D_PRIMITIVE - 1 {
        state.quad_batch[i + state.quad_count * VERTICES_PER_2D_PRIMITIVE] = .{
            vertex_positions[i], vertex_colors[i], vertex_uvs[i], slot, xx pixel_id
        };
    }    
    
    state.quad_index_count += INDICES_PER_2D_PRIMITIVE;
    state.quad_count += 1;
}

#scope_file

flip_quad_vertex_uv :: (vertex_uvs : *Vector2Verts2D, flip_x : bool, flip_y : bool) {

    DoCopy :: () #expand {
        `uv := array_copy(vertex_uvs.*, ,,temp);
    }

    if flip_x && flip_y {
        DoCopy();
        vertex_uvs.*[0] = uv[3];
        vertex_uvs.*[1] = uv[2];
        vertex_uvs.*[2] = uv[1];
        vertex_uvs.*[3] = uv[0];
        return;
    }
    if flip_x {
        DoCopy();
        vertex_uvs.*[0] = uv[1];
        vertex_uvs.*[1] = uv[0];
        vertex_uvs.*[2] = uv[3];
        vertex_uvs.*[3] = uv[2];
        return;
    }
    if flip_y {
        DoCopy();
        vertex_uvs.*[0] = uv[2];
        vertex_uvs.*[1] = uv[3];
        vertex_uvs.*[2] = uv[0];
        vertex_uvs.*[3] = uv[1];
        return;
    }
}

sub_tex_uv :: (vertex_uvs : *Vector2Verts2D, texture : *Texture, rect : Rect) {
    assert(texture && vertex_uvs);
    
    item_px_pos  := Vector2.{ xx rect.x, xx rect.y };
    texture_size := Vector2.{ xx texture.spec.width, xx texture.spec.height };
    item_size    := Vector2.{ xx rect.width, xx rect.height };
    
    top_right, bottom_left : Vector2;
    top_right.x = (item_px_pos.x + item_size.x) * (1 / texture_size.x);
    top_right.y = (item_px_pos.y + item_size.y) * (1 / texture_size.y);
    
    bottom_left.x = item_px_pos.x * (1 / texture_size.x);
    bottom_left.y = (item_px_pos.y * (1 / texture_size.y));
    
    vertex_uvs.*[0] = .{ bottom_left.x, bottom_left.y }; // bottom-left
    vertex_uvs.*[1] = .{ top_right.x,   bottom_left.y }; // bottom-right
    vertex_uvs.*[2] = .{ top_right.x,   top_right.y };   // top-right
    vertex_uvs.*[3] = .{ bottom_left.x, top_right.y };   // top-left
}