shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_toon, specular_toon;

uniform vec4 albedo_color : source_color = vec4(0.8, 0.7, 0.5, 1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform bool use_texture = false;

uniform vec4 shadow_tint : source_color = vec4(0.25, 0.35, 0.45, 1.0);
uniform vec4 rim_color : source_color = vec4(1.0, 0.92, 0.75, 1.0);
uniform float rim_power : hint_range(0.5, 8.0) = 3.0;
uniform float rim_strength : hint_range(0.0, 2.0) = 0.6;

uniform float shadow_threshold : hint_range(0.0, 1.0) = 0.35;
uniform float shadow_softness : hint_range(0.001, 0.2) = 0.05;

void fragment() {
	vec4 base = albedo_color;
	if (use_texture) {
		base *= texture(albedo_texture, UV);
	}
	ALBEDO = base.rgb;
	ROUGHNESS = 0.85;
	METALLIC = 0.0;
}

void light() {
	// N dot L for cel-shading
	float NdotL = dot(NORMAL, LIGHT);
	float light_factor = smoothstep(shadow_threshold - shadow_softness, shadow_threshold + shadow_softness, NdotL);
	
	// Warm Ghibli light mix
	vec3 light_color_toned = mix(ALBEDO * shadow_tint.rgb, ALBEDO * LIGHT_COLOR, light_factor);
	
	// Golden Rim light (Fresnel)
	float fresnel = 1.0 - max(0.0, dot(NORMAL, VIEW));
	float rim = pow(fresnel, rim_power) * max(0.0, NdotL);
	vec3 rim_term = rim_color.rgb * rim * rim_strength * LIGHT_COLOR;
	
	DIFFUSE_LIGHT += (light_color_toned + rim_term) * ATTENUATION;
}
