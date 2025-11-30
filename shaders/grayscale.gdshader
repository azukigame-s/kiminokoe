shader_type canvas_item;

// グレースケールエフェクト
void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	
	// グレースケール変換（標準的な重み付け）
	float gray = dot(tex_color.rgb, vec3(0.299, 0.587, 0.114));
	
	COLOR = vec4(vec3(gray), tex_color.a);
}

