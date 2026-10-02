shader_type spatial;
render_mode cull_disabled, diffuse_toon, specular_toon;

// Zelda: Tears of the Kingdom / Ghibli watercolor grass shader
uniform vec3 color_root : source_color = vec3(0.18, 0.32, 0.12);    // Raiz verde-musgo escura
uniform vec3 color_mid : source_color = vec3(0.42, 0.65, 0.22);     // Meio verde-folha vibrante
uniform vec3 color_tip : source_color = vec3(0.85, 0.82, 0.36);     // Ponta dourada ensolarada
uniform vec3 color_watercolor_wash : source_color = vec3(0.92, 0.88, 0.55); // Lavagem de aquarela sutil

uniform float wind_speed : hint_range(0.5, 5.0) = 2.0;
uniform float wind_strength : hint_range(0.05, 1.0) = 0.28;
uniform float wind_wave_freq : hint_range(0.05, 1.0) = 0.22;
uniform float blade_height : hint_range(0.2, 2.0) = 0.75;

void vertex() {
	// Apenas a parte superior da haste balança com o vento (ancorada na raiz Y=0)
	float height_ratio = clamp(VERTEX.y / blade_height, 0.0, 1.0);
	float flex = pow(height_ratio, 1.6);
	
	// Posição no espaço de mundo para propagação contínua das ondas de vento
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// Ondas compostas de vento (brisa pastoral suave estilo Arrietty / Zelda)
	float wave1 = sin(TIME * wind_speed + world_pos.x * wind_wave_freq + world_pos.z * (wind_wave_freq * 0.8));
	float wave2 = cos(TIME * (wind_speed * 0.75) + world_pos.x * 0.15 - world_pos.z * 0.25);
	float gust = sin(TIME * (wind_speed * 0.3) + world_pos.x * 0.05) * 0.4;
	
	float total_sway = (wave1 * 0.65 + wave2 * 0.35 + gust) * wind_strength * flex;
	
	// Curvatura tridimensional elegante da folha de grama
	VERTEX.x += total_sway;
	VERTEX.z += total_sway * 0.6;
	VERTEX.y -= abs(total_sway) * 0.18; // Leve compressão na dobra do vento
}

void fragment() {
	// Gradiente vertical de aquarela
	float v = clamp(UV.y, 0.0, 1.0);
	
	// Interpolação suave em 3 faixas: Raiz -> Meio -> Ponta
	vec3 base_col = mix(color_tip, color_mid, smoothstep(0.0, 0.6, v));
	base_col = mix(base_col, color_root, smoothstep(0.5, 1.0, v));
	
	// Variação de lavagem de aquarela sutil dependendo da orientação
	float wash = sin(UV.x * 3.14159) * 0.08;
	vec3 final_color = base_col + (color_watercolor_wash - base_col) * wash;
	
	ALBEDO = final_color;
	ROUGHNESS = 0.88;
	SPECULAR = 0.12;
}
