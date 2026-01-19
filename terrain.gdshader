shader_type spatial;

uniform float height = 64.0;
uniform sampler2D colorGradient;
uniform sampler2D normalMap;

void fragment() {
	// Called for every pixel the material is visible on.
	vec4 worldVertex = INV_VIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 modelVertex = (inverse(MODEL_MATRIX) * worldVertex).xyz;
	float gradientUV = (modelVertex.y / height) + 0.5;
	ALBEDO = texture(colorGradient, vec2(gradientUV)).rgb;
	NORMAL_MAP = texture(normalMap, UV).xyz;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
