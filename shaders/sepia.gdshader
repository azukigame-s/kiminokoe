shader_type canvas_item;

// セピア調エフェクト
void fragment() {
	vec3 color = texture(TEXTURE, UV).rgb;
	
	// セピア変換行列
	mat3 sepia_matrix = mat3(
		vec3(0.393, 0.769, 0.189),
		vec3(0.349, 0.686, 0.168),
		vec3(0.272, 0.534, 0.131)
	);
	
	vec3 sepia_color = sepia_matrix * color;
	COLOR = vec4(sepia_color, texture(TEXTURE, UV).a);
}

