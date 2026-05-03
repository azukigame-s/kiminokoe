shader_type canvas_item;

// 消去の進行位置（-0.1=全体表示, 1.1=全体消去）
uniform float erase_progress : hint_range(-0.1, 1.1) = -0.1;
// 透明余白を除いたコンテンツ領域のUV範囲
uniform float content_left : hint_range(0.0, 1.0) = 0.0;
uniform float content_right : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	// コンテンツ領域内でUV.xを0→1に正規化してから消去マスクを計算
	float content_uv = (UV.x - content_left) / max(content_right - content_left, 0.001);
	float mask = smoothstep(erase_progress - 0.03, erase_progress + 0.03, content_uv);
	col.a *= mask;
	COLOR = col;
}
