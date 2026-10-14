shader_type spatial;
render_mode cull_disabled, diffuse_toon, specular_toon;

// Zelda: Tears of the Kingdom / Ghibli watercolor grass shader with Wind
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform bool use_texture = false;

uniform vec3 color_root : source_color = vec3(0.14, 0.26, 0.09);    // Raiz verde-musgo profundo
uniform vec3 color_mid : source_color = vec3(0.36, 0.62, 0.20);     // Meio verde-folha viçoso
uniform vec3 color_tip : source_color = vec3(0.68, 0.84, 0.30);     // Ponta ensolarada com reflexo dourado
uniform vec3 color_watercolor_wash : source_color = vec3(0.92, 0.88, 0.55); // Lavagem de aquarela

uniform float wind_speed : hint_range(0.5, 5.0) = 2.4;
uniform float wind_strength : hint_range(0.05, 2.0) = 0.35;
uniform float wind_wave_freq : hint_range(0.05, 1.0) = 0.25;

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// Flexibilidade ao longo da altura Y da lâmina de grama (base ancorada em Y=0.0)
	float flex = clamp(VERTEX.y / 0.95, 0.0, 1.0);
	flex = pow(flex, 1.4);
	
	// Ondas compostas de vento estilo Zelda TotK
	float wave1 = sin(TIME * wind_speed + world_pos.x * wind_wave_freq + world_pos.z * (wind_wave_freq * 0.85));
	float wave2 = cos(TIME * (wind_speed * 0.72) + world_pos.x * 0.18 - world_pos.z * 0.28);
	float gust = sin(TIME * (wind_speed * 0.35) + world_pos.x * 0.06) * 0.35;
	
	float total_sway = (wave1 * 0.65 + wave2 * 0.35 + gust) * (0.22 * wind_strength) * flex;
	
	VERTEX.x += total_sway;
	VERTEX.z += total_sway * 0.5;
}

void fragment() {
	float v = clamp(VERTEX.y / 0.95, 0.0, 1.0);
	vec3 base_col = mix(color_root, color_mid, smoothstep(0.0, 0.45, v));
	base_col = mix(base_col, color_tip, smoothstep(0.45, 1.0, v));
	
	// Multiplica pela cor da instância para variação natural
	base_col *= COLOR.rgb;
	
	if (use_texture) {
		vec4 tex_col = texture(albedo_texture, UV);
		ALBEDO = tex_col.rgb * (base_col * 1.2);
	} else {
		ALBEDO = base_col;
	}
	
	// Rim light sutil estilo animação pastoral japonesa
	float rim = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	rim = pow(rim, 3.5) * 0.22;
	ALBEDO += color_tip * rim;
	
	ROUGHNESS = 0.86;
	SPECULAR = 0.14;
}
