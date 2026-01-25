shader_type spatial;

uniform sampler2D grass_texture;
uniform sampler2D rock_texture;
uniform sampler2D sand_texture;
uniform sampler2D underwater_texture;

uniform float min_rock_slope:hint_range(0.f,1.f) = 0.5;
uniform float max_grass_slope:hint_range(0.f,1.f) = 0.9;

uniform float min_rockgrass_height = 2.f;
uniform float max_sand_height = 6.f;

uniform float min_sand_height = -8.f;
uniform float max_underwater_height = 0.f;

varying float normal_y;
varying float vertex_y;

void vertex(){
    normal_y = NORMAL.y;
    vertex_y = VERTEX.y;
}

void fragment() {
    // Albedo Values
    vec3 grass_albedo = texture(grass_texture, UV * 4.f).xyz;
    vec3 rock_albedo = texture(rock_texture, UV * 4.f).xyz;
    vec3 sand_albedo = texture(sand_texture, UV * 4.f).xyz;
    vec3 underwater_albedo = texture(underwater_texture, UV * 4.f).xyz;

    // Calculating Rock/Grass Weight
    float rock_grass_weight = min(max_grass_slope, max(min_rock_slope, normal_y)) - min_rock_slope;
    rock_grass_weight /= max_grass_slope - min_rock_slope;

    // Calculating Sand/RockGrass Weight
    float sand_rockgrass_weight = min(max_sand_height, max(min_rockgrass_height, vertex_y)) - min_rockgrass_height;
    sand_rockgrass_weight /= max_sand_height - min_rockgrass_height;

    // Calculating Underwater/Sand Weight
    float underwater_sand_weight = min(max_underwater_height, max(min_sand_height, vertex_y)) - min_sand_height;
    underwater_sand_weight /= max_underwater_height - min_sand_height;

    // Mixing and Assigning Albedo
    vec3 rockgrass_albedo = mix(rock_albedo, grass_albedo, rock_grass_weight);
    vec3 temp = mix(sand_albedo, rockgrass_albedo, sand_rockgrass_weight);
    ALBEDO = mix(underwater_albedo, temp, underwater_sand_weight);
}
