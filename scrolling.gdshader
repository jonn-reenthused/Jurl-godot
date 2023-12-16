shader_type canvas_item;

uniform vec2 scroll = vec2(0.1, 0.1);

void fragment() {
	vec4 textureColour = texture(TEXTURE, UV + scroll * TIME);
	COLOR = textureColour;
}
