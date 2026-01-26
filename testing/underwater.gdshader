shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float activate: hint_range(0.0, 1.0, 0.01) = 1.0;

// color of the water
uniform vec3 water_color: source_color = vec3(0, 0, 0.165);
uniform float color_intensity: hint_range(0.0, 0.8, 0.01) = 0.4;

// how fast the waves ripple
uniform float speed: hint_range(0.0, 10.0, 0.01) = 1.0;
// the density of the wave function
uniform float wave: hint_range(0.0, 100.0, 0.1) = 20.0;
// The distance to offset by
uniform float warp: hint_range(0.1, 20.0, 0.01) = 5.0;

uniform sampler2D noiseA;
uniform sampler2D noiseB;

void fragment() {
	vec2 uv = SCREEN_UV;
	float time = TIME * speed;
	vec2 s = uv * wave + time;

	uv.x += sin(s.x - s.y) * warp * 1e-3 * sin(s.y);
	uv.y += cos(s.x - s.y) * warp * 1e-3 * cos(s.y);

	vec2 offsetA = 0.02 * cos(uv - 0.3 * TIME) + 5.8 * TIME * vec2(0.04, 0.01);
	vec2 offsetB = 0.09 * sin(uv + 2.4 * TIME) + 4.6 * TIME * vec2(-0.01, 0.03);
	uv += vec2(-.9, -.4) * 0.03 * texture(noiseA, uv / 0.33 + offsetA).x;
	uv += vec2(.9, -.1) * 0.02 * texture(noiseB, uv / 0.25 + offsetB).x;
	uv += vec2(0.008, 0.0);

	// actually load that UV now that we are done toying around with it
	uv = mix(SCREEN_UV, uv, activate);
	vec3 c = textureLod(screen_texture, uv, 0.0).rgb;

	// make it blue & set color
    COLOR.rgb = mix(c, water_color, activate * color_intensity);
}
