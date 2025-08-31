is_key_down :: inline (input: Key_Code) -> bool {
    return input_button_states[input] & .DOWN == 1;
}

get_mouse_pos :: inline () -> Vector2 {
    x, y := get_mouse_pointer_position();
    return .{ xx x, xx y };
}