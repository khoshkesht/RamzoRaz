shader_type canvas_item;

// Reference-space decorative rain; no extra viewport scale or input transform.
void fragment() {
	vec4 scene = texture(TEXTURE, UV);
	vec2 point = UV * vec2(1920.0, 1080.0);
	point.x += point.y * 0.22;
	vec2 cell = vec2(point.x / 110.0, point.y / 180.0 - TIME * 2.8);
	float seed = fract(sin(floor(cell.x) * 127.1) * 43758.5453);
	vec2 local = fract(cell + vec2(seed * 0.6, seed));
	float streak = (1.0 - smoothstep(0.009, 0.026, abs(local.x - 0.5)))
		* smoothstep(0.10, 0.15, local.y) * (1.0 - smoothstep(0.32, 0.38, local.y));
	scene.rgb = mix(scene.rgb, vec3(0.27, 0.51, 0.65), streak * 0.42);
	COLOR = scene;
}
