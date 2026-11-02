shader_type canvas_item;
// A broad stroke of ink crossing the screen on a slant, with a torn, bristled edge. `progress` runs it from off one
// side to off the other.

uniform float progress = 0.0;
uniform float aspect = 2.0;

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = fract(sin(dot(i, vec2(127.1, 311.7))) * 43758.5453);
	float b = fract(sin(dot(i + vec2(1.0, 0.0), vec2(127.1, 311.7))) * 43758.5453);
	float c = fract(sin(dot(i + vec2(0.0, 1.0), vec2(127.1, 311.7))) * 43758.5453);
	float d = fract(sin(dot(i + vec2(1.0, 1.0), vec2(127.1, 311.7))) * 43758.5453);
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	float along = UV.x + (1.0 - UV.y) * 0.22;
	float bristle = noise(vec2(UV.y * 26.0, 1.0)) * 0.1 + noise(vec2(UV.y * 90.0, UV.x * 3.0)) * 0.05;
	float head = mix(-0.25, 1.75, progress);
	float tail = head - 0.75;
	float a = smoothstep(head + 0.02, head - 0.03, along + bristle) * smoothstep(tail - 0.03, tail + 0.05, along - bristle);
	COLOR.a *= a;
}
