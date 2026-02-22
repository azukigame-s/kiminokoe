extends Control

## 波紋オーバーレイ
## タイトル画面に水面の波紋をランダムに描画する

# 波紋1つ分のデータ（水滴1滴 = 複数リング）
class Ripple:
	var pos: Vector2        # 発生位置
	var radius: float       # 現在の半径（横方向）
	var max_radius: float   # 最大半径
	var delay: float        # 出現までの遅延秒数（同心円のずれ）
	var elapsed: float      # 経過時間

# アクティブな波紋リスト
var _ripples: Array[Ripple] = []

# 設定
const MAX_RADIUS     := 100.0  # 最大半径（横）
const ASPECT_RATIO   := 0.38   # 縦/横比（小さいほど平べったく＝遠近感が強い）
const EXPAND_SPEED   := 38.0   # 広がる速さ（px/秒）
const SPAWN_INTERVAL_MIN := 1.8  # 波紋グループの出る間隔・最短（秒）
const SPAWN_INTERVAL_MAX := 4.5  # 波紋グループの出る間隔・最長（秒）
const RING_COUNT     := 3      # 同心円の数
const RING_DELAY     := 0.35   # 同心円ごとの遅延（秒）
const LINE_COLOR     := Color(1.0, 1.0, 1.0, 0.22)
const LINE_WIDTH     := 1.1

var _spawn_timer: float = 0.0
var _next_spawn: float = 1.5  # 最初の波紋が出るまでの秒数

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(delta: float) -> void:
	for ripple in _ripples:
		ripple.elapsed += delta

	# 遅延を過ぎたものだけ半径を更新
	for ripple in _ripples:
		if ripple.elapsed >= ripple.delay:
			ripple.radius += EXPAND_SPEED * delta

	_ripples = _ripples.filter(func(r): return r.radius < r.max_radius)

	_spawn_timer += delta
	if _spawn_timer >= _next_spawn:
		_spawn_timer = 0.0
		_next_spawn = randf_range(SPAWN_INTERVAL_MIN, SPAWN_INTERVAL_MAX)
		_spawn_ripple_group()

	queue_redraw()

func _draw() -> void:
	for ripple in _ripples:
		if ripple.elapsed < ripple.delay:
			continue
		var progress = ripple.radius / ripple.max_radius
		var alpha = (1.0 - progress) * (1.0 - progress)  # 二乗でなめらかにフェード
		var color = LINE_COLOR
		color.a = LINE_COLOR.a * alpha
		_draw_ellipse(ripple.pos, ripple.radius, ripple.radius * ASPECT_RATIO, color)

# 楕円を描画（水面の遠近感）
func _draw_ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var steps := 56
	var points := PackedVector2Array()
	for i in range(steps + 1):
		var angle := (float(i) / steps) * TAU
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_polyline(points, color, LINE_WIDTH, true)

# 同心円グループを生成（1滴 = RING_COUNT本のリング）
func _spawn_ripple_group() -> void:
	var pos := Vector2(
		randf_range(size.x * 0.1, size.x * 0.9),
		randf_range(size.y * 0.25, size.y * 0.75)
	)
	for i in range(RING_COUNT):
		var r := Ripple.new()
		r.pos = pos
		r.radius = 0.0
		r.max_radius = randf_range(MAX_RADIUS * 0.7, MAX_RADIUS) - i * 12.0
		r.delay = i * RING_DELAY
		r.elapsed = 0.0
		_ripples.append(r)
