shader_type canvas_item;

// 波の速さ（小さいほどゆっくり）
uniform float speed : hint_range(0.1, 3.0) = 0.4;
// 波の振れ幅（小さいほど控えめ）
uniform float amplitude : hint_range(0.0, 0.02) = 0.004;
// 波の細かさ
uniform float frequency : hint_range(1.0, 20.0) = 5.0;

void fragment() {
	vec2 uv = UV;
	float t = TIME * speed;

	// 縦横それぞれに少しずつ位相をずらして自然なゆらぎを作る
	uv.x += sin(uv.y * frequency + t) * amplitude;
	uv.y += sin(uv.x * frequency + t * 0.7) * amplitude;

	COLOR = texture(TEXTURE, uv);
}
