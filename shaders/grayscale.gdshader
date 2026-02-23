shader_type canvas_item;

// グレースケールエフェクト（mix_amountで段階的適用可能）
uniform float mix_amount: hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);

	// グレースケール変換（標準的な重み付け）
	float gray = dot(tex_color.rgb, vec3(0.299, 0.587, 0.114));

	COLOR = vec4(mix(tex_color.rgb, vec3(gray), mix_amount), tex_color.a);
}

