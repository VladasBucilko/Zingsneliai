shader_type canvas_item;
// Rounded-corner mask for photos.
uniform vec2 size_px = vec2(256.0);
uniform float radius_px = 28.0;

void fragment() {
	vec2 p = UV * size_px;
	vec2 q = abs(p - size_px * 0.5) - (size_px * 0.5 - vec2(radius_px));
	float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius_px;
	vec4 c = texture(TEXTURE, UV);
	c.a *= clamp(0.5 - d, 0.0, 1.0);
	COLOR = c;
}
