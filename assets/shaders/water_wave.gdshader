shader_type canvas_item;

// 波紋の輪の色（ゲームの墨色 0.11 〜 グレー程度に留める）
uniform vec4 ring_color : source_color = vec4(0.17, 0.17, 0.17, 1.0);
// 波紋の動く速さ
uniform float ripple_speed : hint_range(0.05, 1.0) = 0.3;
// 1ドロップの周期
uniform float ripple_period : hint_range(2.0, 20.0) = 10.0;
// 背景の歪み強度（0 にすると歪みなし）
uniform float distortion_strength : hint_range(0.0, 0.03) = 0.008;
// 波紋リングの細さ（大きいほど細い）
uniform float ring_sharpness : hint_range(50.0, 500.0) = 200.0;
// 画面アスペクト比（16:9 なら 1.778）
uniform float aspect_ratio : hint_range(0.5, 3.0) = 1.778;
// 同時発生するドロップ数
uniform int drop_count : hint_range(2, 10) = 6;
// 同心円の本数
uniform int ring_count : hint_range(1, 4) = 3;
// 同心円の間隔
uniform float ring_spacing : hint_range(0.02, 0.15) = 0.06;
// 波紋の不透明度（大きいほど目立つ）
uniform float ring_opacity : hint_range(0.0, 1.0) = 0.45;
// 経過時間（GDScript から更新、0のまま＝静止）
uniform float elapsed = 0.0;
// 波紋の表示強度（0=非表示, 1=通常。フェードイン用）
uniform float ripple_intensity : hint_range(0.0, 1.0) = 0.0;

float hash11(float p) {
    return fract(sin(p * 127.1) * 43758.5453);
}
vec2 hash12(float p) {
    return vec2(hash11(p), hash11(p + 57.0));
}

float single_ring(float dist, float radius, float max_r) {
    if (radius <= 0.0) return 0.0;
    float delta = dist - radius;
    // ガウシアン包絡線 × コサインキャリア：正のクレストと負のトラフを持つ波
    float wave = exp(-delta * delta * ring_sharpness) * cos(delta * 55.0);
    float fade = 1.0 - smoothstep(0.0, max_r, radius);
    return wave * fade * fade;
}

void fragment() {
    vec2  uv    = UV;
    float max_r = 0.72;

    vec2  total_warp = vec2(0.0);
    float total_wave = 0.0; // max 取りで靄を防ぐ

    for (int i = 0; i < 10; i++) {
        if (i >= drop_count) break;

        float fi = float(i);
        // 3列×ceil(drop_count/3)行のグリッドで画面全体に均等配置
        int col = i % 3;
        int row = i / 3;
        float num_rows = ceil(float(drop_count) / 3.0);
        vec2 cell_size = vec2(1.0 / 3.0, 1.0 / num_rows);
        vec2 jitter = hash12(fi + 1.3) * 0.7 + 0.15;  // セル内でランダムにずらす
        vec2  center      = (vec2(float(col), float(row)) + jitter) * cell_size;
        // 元のtime_offsetによるサイクリングを維持（常に連続して波紋が出続ける）
        float time_offset = hash11(fi + 37.0) * ripple_period;
        float t           = mod(elapsed * ripple_speed + time_offset, ripple_period);
        float phase       = t / ripple_period;
        float lead_r      = phase * max_r;

        vec2  diff = uv - center;
        float dist = length(vec2(diff.x * aspect_ratio, diff.y));

        float wave_sum = 0.0;
        for (int k = 0; k < 4; k++) {
            if (k >= ring_count) break;
            float r = lead_r - float(k) * ring_spacing;
            wave_sum += single_ring(dist, r, max_r) * pow(0.6, float(k));
        }

        // 着水の瞬間に中心が光る
        wave_sum += exp(-phase * 15.0) * exp(-dist * dist * 300.0) * 0.5;

        // 起動時のみ：各ドロップを時間差でフェードイン（ripple_intensityと独立して動作）
        float startup_delay = hash11(fi * 3.7 + 1.1) * 3.5;
        wave_sum *= smoothstep(startup_delay, startup_delay + 1.5, elapsed);

        // 符号付き波の加算 → 重なると自然に干渉（靄は cos の正負で相殺）
        total_wave += wave_sum;

        if (dist > 0.001) {
            total_warp += normalize(diff) * wave_sum;
        }
    }

    // 背景を取得（わずかに歪ませる）
    vec4 base = texture(TEXTURE, uv + total_warp * distortion_strength * ripple_intensity);

    // 波紋の輪を背景に上書きブレンド（加算でなく mix）
    float blend = clamp(total_wave * ring_opacity * ripple_intensity, 0.0, 1.0);
    COLOR = vec4(mix(base.rgb, ring_color.rgb, blend), base.a);
}
