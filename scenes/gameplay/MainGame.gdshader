shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_intensity : hint_range(0.0, 5.0) = 3.2;
// Tinte oscuro verdoso/marino para mantener el contraste del tablero
uniform vec4 tint_color : source_color = vec4(0.06, 0.12, 0.10, 0.72);

void fragment() {
    vec4 blurred = textureLod(screen_texture, SCREEN_UV, blur_intensity);
    COLOR = mix(blurred, vec4(tint_color.rgb, 1.0), tint_color.a);
}