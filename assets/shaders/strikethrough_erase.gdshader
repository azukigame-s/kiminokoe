shader_type canvas_item;

// 消去の進行位置（-0.1=全体表示, 1.1=全体消去）
uniform float erase_progress : hint_range(-0.1, 1.1) = -0.1;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	// UV.x < erase_progress の領域を左から順に消去
	float mask = smoothstep(erase_progress - 0.03, erase_progress + 0.03, UV.x);
	col.a *= mask;
	COLOR = col;
}
