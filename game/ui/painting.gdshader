shader_type canvas_item;
// A painting's light: slow cloud shadows crossing it and, where it has them, soft rays from above. All of it is
// computed here, so it needs no textures.

uniform float clouds = 0.0;
uniform float rays = 0.0;
uniform vec3 ray_color = vec3(1.0, 0.9, 0.7);
// Where the rays come from, in the painting's width, above its top edge.
uniform float ray_from = 0.3;

// A hash with no sine in it: a sine of a large number loses its precision on some GPUs and breaks the clouds into blocks.
float hash(vec2 p) {
	vec3 q = fract(vec3(p.xyx) * 0.1031);
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 at = UV * vec2(2.0, 1.0);
	if (clouds > 0.0) {
		vec2 p = at * 1.6 + vec2(TIME * 0.018, TIME * 0.006);
		float n = noise(p) * 0.62 + noise(p * 2.1 + 4.0) * 0.38;
		COLOR.rgb *= 1.0 - clouds * smoothstep(0.46, 0.68, n);
	}
	if (rays > 0.0) {
		vec2 d = UV - vec2(ray_from, -0.25);
		float a = atan(d.x, d.y);
		float streak = noise(vec2(a * 9.0, TIME * 0.05)) * noise(vec2(a * 23.0 + 3.0, TIME * 0.08));
		float fall = smoothstep(1.15, 0.1, length(d));
		COLOR.rgb += ray_color * rays * smoothstep(0.12, 0.5, streak) * fall;
	}
}
