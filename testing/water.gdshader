shader_type spatial;
//render_mode specular_toon;

uniform float height_scale = 0.02;
uniform sampler2D noiseA;

uniform sampler2D noiseB;
uniform sampler2D noiseC;

varying vec2 tex_position;

float height(vec2 position, float time) {
 	//return texture(noiseA, position / 10.0).x; // Scaling factor is based on mesh size (this PlaneMesh is 10×10).

	vec2 offsetA = 0.05 * cos(position + 0.1 * time) + 0.1 * time * vec2(-0.02, 0.04);

	vec2 offsetB = 0.02 * cos(position - 0.3 * time) + 5.8 * time * vec2(0.04, 0.01);
	vec2 offsetC = 0.09 * sin(position + 2.4 * time) + 4.6 * time * vec2(-0.01, 0.03);

	float val = 0.0;
	val += 0.5 * texture(noiseA, position / 256.0 + offsetA).x - 0.25;
	val += 0.03 * texture(noiseB, position / 0.33 + offsetB).x;
	val += 0.01 * texture(noiseC, position / 0.25 + offsetC).x;
	//val +=

	return val;
}

void vertex() {
	tex_position = VERTEX.xz / 2.0 + 0.5;
	float k = height(tex_position, TIME);
	VERTEX.y += k * height_scale;

	NORMAL = normalize(vec3(k - height(tex_position + vec2(0.1, 0.0), TIME), 0.1, k - height(tex_position + vec2(0.0, 0.1), TIME)));
}

void fragment() {

	float fresnel = sqrt(1.0 - max(dot(NORMAL, VIEW), 1.0));
	RIM = 0.2;
	METALLIC = 0.0;
	ROUGHNESS = 0.01 * (1.0 - fresnel);
	ALBEDO = vec3(0.01, 0.01, 0.09) + (0.1 * fresnel);
	ALPHA = 0.9;
}