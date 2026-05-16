extends CanvasLayer

## 日記の真っ黒ページ演出
## シーケンス:
##   1. クリックフェーズ（スグ。が1行ずつスタック、1→2→4クリック）
##   2. 自動フェーズ（スグ。×6 自動スタック）
##   3. 密集フェーズ（スグ×250=500文字・黒文字・速度加速）
##   4. カオスフェーズ（400文字を背景に黒ラベルが乱れ飛ぶ → 暗転）

signal horror_completed

# ── 調整用定数 ──────────────────────────────────────────
## フォントパス（怨霊フォント入手後はこの1行だけ差し替える）
const FONT_PATH             := "res://assets/fonts/EnkaDotMincho24.ttf"

## 自動フェーズの行間間隔（秒）
const AUTO_INTERVAL         := 0.8
## 密集行アニメーション開始時の秒/文字（遅い）
const DENSE_SPEED_START     := 0.02
## 密集行アニメーション終了時の秒/文字（速い）
const DENSE_SPEED_END       := 0.005
## 密集行アニメーション完了後の待機時間（秒）
const DENSE_INTERVAL        := 1.0
## カオスラベルの初期生成間隔（秒）
const CHAOS_INTERVAL_START  := 0.35
## 生成のたびに間隔に掛ける係数（小さいほど加速）
const CHAOS_ACCEL           := 0.82
## 生成間隔の下限（秒）
const CHAOS_INTERVAL_MIN    := 0.02
## 暗転完了までの時間（秒）―― 長めにして文字が画面を埋める時間を確保
const BLACKOUT_DURATION     := 8.0
## カオスラベルのフォントサイズ範囲
const CHAOS_SIZE_MIN        := 30
const CHAOS_SIZE_MAX        := 300
## カオス開幕の「スグ」：センター表示のフォントサイズと待機時間（秒）
const CHAOS_FIRST_FONT_SIZE := 250
const CHAOS_FIRST_PAUSE     := 1.2

## クリックフェーズ：2クリック1回目のジョルト量（px）
const JOLT_SMALL            := 125.0
## 4クリック3回目の傾き角度（ラジアン）±この範囲でランダム
const TILT_ANGLE_MAX        := 0.45
## 密集フェーズ中のシェイク間隔（秒）
const DENSE_SHAKE_INTERVAL  := 0.3
## 密集フェーズ終盤のシェイク最大強度（px）
const DENSE_SHAKE_MAX       := 8.0
## 密集フェーズのフォントサイズ（開始・終了）
const DENSE_FONT_SIZE_START := 24
const DENSE_FONT_SIZE_END   := 34
# ───────────────────────────────────────────────────────

const _SUGU_LINE := "スグ。"

enum _Phase { CLICK, AUTO_SINGLE, AUTO_DENSE, CHAOS, DONE }

## text_display（CommandExecutor から渡される）
var text_display

var _phase := _Phase.CLICK
var _click_target: int = 0
var _click_count:  int = 0
## 何回目のクリックでジョルトを起こすか（0=なし）
var _click_jolt_at:   int     = 0
var _click_jolt_vec:  Vector2 = Vector2.ZERO
## 何回目のクリックで傾けるか（0=なし）
var _click_tilt_at:   int     = 0
var _click_tilt_angle: float  = 0.0

## 密集フェーズ アニメーション管理
var _dense_line:          String = ""
var _dense_char_index:    int    = 0
var _dense_char_timer:    float  = 0.0
var _dense_animating:     bool   = false
var _dense_font_switched: bool   = false
var _dense_shake_timer:   float  = 0.0
var _dense_last_font_size: int   = -1

## text_label の基準位置（密集フェーズのシェイクで振れ幅の中心として使う）
var _label_origin: Vector2 = Vector2.ZERO
## 演出開始前の本当の原点（終了時に完全リセットするために保持）
var _label_true_origin: Vector2 = Vector2.ZERO
## 演出開始前の有効フォントサイズ（終了時に確実に復元するために保持）
var _original_font_size: int = -1

var _chaos_interval:   float = CHAOS_INTERVAL_START
var _chaos_timer:      float = 0.0
var _blackout_elapsed: float = 0.0

var _chaos_container: Control
var _blackout:        ColorRect
var _font:            Font

signal _clicks_done
signal _dense_done


func _ready() -> void:
	layer = 60  # PoemDisplay(55) より上
	visible = false
	set_process(false)

	# スグ × 250 = 500 文字
	for _i in 250:
		_dense_line += "スグ"

	_build_ui()


func _build_ui() -> void:
	if ResourceLoader.exists(FONT_PATH):
		_font = load(FONT_PATH)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	_chaos_container = Control.new()
	_chaos_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_chaos_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_chaos_container)

	_blackout = ColorRect.new()
	_blackout.color = Color(0, 0, 0, 0.0)
	_blackout.set_anchors_preset(Control.PRESET_FULL_RECT)
	_blackout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_blackout)


## 演出を開始する（CommandExecutor から呼ぶ）
func start() -> void:
	visible = true
	_phase = _Phase.CLICK
	_click_target = 0
	if text_display and text_display.text_label:
		_label_true_origin = text_display.text_label.position
		_original_font_size = text_display.text_label.get_theme_font_size("normal_font_size")
		text_display.text_label.scroll_active = false
	set_process(true)
	_run_click_phase()


# ── クリックフェーズ（3行：1→2→4クリック）──────────────

func _run_click_phase() -> void:
	await text_display.show_text(_SUGU_LINE, true)
	await _wait_clicks(1)

	# 2クリック待ち：1回目で125pxずれる
	_click_jolt_at  = 1
	_click_jolt_vec = Vector2(randf_range(-JOLT_SMALL, JOLT_SMALL),
							  randf_range(-JOLT_SMALL, JOLT_SMALL))
	await text_display.show_text(_SUGU_LINE, false)
	await _wait_clicks(2)

	# 3行目表示前にフォントを怨霊書体へ切り替え（突然の違和感）
	if _font and text_display and text_display.text_label:
		text_display.text_label.add_theme_font_override("font", _font)
	# 4クリック待ち：3回目で傾く
	_click_tilt_at    = 3
	_click_tilt_angle = randf_range(-TILT_ANGLE_MAX, TILT_ANGLE_MAX)
	await text_display.show_text(_SUGU_LINE, false)
	await _wait_clicks(4)

	_phase = _Phase.AUTO_SINGLE
	_run_auto_single_phase()


# ── 自動フェーズ（6行：自動スタック）────────────────────

func _run_auto_single_phase() -> void:
	text_display.block_advance = true
	for i in range(6):
		# 偶数行：通常フォント、奇数行：怨霊フォント（交互に揺れ動く）
		if text_display and text_display.text_label:
			if _font and i % 2 == 1:
				text_display.text_label.add_theme_font_override("font", _font)
			else:
				text_display.text_label.remove_theme_font_override("font")
		await text_display.show_text(_SUGU_LINE, false)
		await get_tree().create_timer(AUTO_INTERVAL).timeout
	text_display.block_advance = false

	_phase = _Phase.AUTO_DENSE
	_run_auto_dense_phase()


# ── 密集フェーズ（500文字・黒文字・速度加速）─────────────

func _run_auto_dense_phase() -> void:
	text_display.clear()
	text_display.block_advance = true

	if text_display.text_label:
		text_display.text_label.add_theme_color_override("default_color", Color.BLACK)
		text_display.text_label.text = ""
		text_display.text_label.remove_theme_font_override("font")
		_label_origin = text_display.text_label.position

	_dense_char_index     = 0
	_dense_char_timer     = 0.0
	_dense_shake_timer    = 0.0
	_dense_last_font_size = -1
	_dense_animating      = true
	_dense_font_switched  = false
	await _dense_done

	await get_tree().create_timer(DENSE_INTERVAL).timeout

	_spawn_first_chaos_label()
	await get_tree().create_timer(CHAOS_FIRST_PAUSE).timeout

	_phase = _Phase.CHAOS
	_chaos_interval = CHAOS_INTERVAL_START
	_chaos_timer = 0.0
	_blackout_elapsed = 0.0


# ── クリック待機 ─────────────────────────────────────────

func _wait_clicks(target: int) -> void:
	_click_target = target
	_click_count  = 0
	text_display.block_advance = true
	text_display.wait_for_advance()
	await _clicks_done
	text_display.force_complete()
	text_display.block_advance = false


func _input(event: InputEvent) -> void:
	if not visible or _click_target == 0:
		return

	var advance := false
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			advance = true
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ENTER, KEY_SPACE]:
			advance = true

	if not advance:
		return

	_click_count += 1
	if _click_jolt_at > 0 and _click_count == _click_jolt_at:
		_jolt_text(_click_jolt_vec)
	if _click_tilt_at > 0 and _click_count == _click_tilt_at:
		_tilt_text(_click_tilt_angle)
	if _click_count >= _click_target:
		_click_target  = 0
		_click_jolt_at = 0
		_click_tilt_at = 0
		_clicks_done.emit()

	get_viewport().set_input_as_handled()


# ── テキストジョルト・シェイク ───────────────────────────

## クリックフェーズ用：テキストエリアをガクッとずらす（戻さない）
func _jolt_text(offset: Vector2) -> void:
	if not text_display or not text_display.text_label:
		return
	var lbl: RichTextLabel = text_display.text_label
	if _label_origin == Vector2.ZERO:
		_label_origin = lbl.position
	lbl.position = _label_origin + offset


## 4クリック3回目：テキストエリアを傾ける（戻さない）
func _tilt_text(angle: float) -> void:
	if not text_display or not text_display.text_label:
		return
	var lbl: RichTextLabel = text_display.text_label
	lbl.pivot_offset = lbl.size * 0.5
	lbl.rotation = angle


## 密集フェーズ用：_process から呼ぶシェイク（基準位置を使う）
func _shake_text_bg(intensity: float) -> void:
	if not text_display or not text_display.text_label:
		return
	var lbl: RichTextLabel = text_display.text_label
	var tw := create_tween()
	tw.tween_property(lbl, "position",
		_label_origin + Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity)), 0.05)
	tw.tween_property(lbl, "position",
		_label_origin + Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity)), 0.05)
	tw.tween_property(lbl, "position",
		_label_origin + Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity)), 0.05)
	tw.tween_property(lbl, "position", _label_origin, 0.05)


# ── メインループ ─────────────────────────────────────────

func _process(delta: float) -> void:
	# 密集フェーズ：速度加速アニメーション
	if _dense_animating:
		_dense_char_timer += delta
		var total := float(_dense_line.length())
		var speed := lerpf(DENSE_SPEED_START, DENSE_SPEED_END,
				float(_dense_char_index) / total)
		while _dense_char_timer >= speed and _dense_char_index < _dense_line.length():
			_dense_char_timer -= speed
			_dense_char_index += 1
			speed = lerpf(DENSE_SPEED_START, DENSE_SPEED_END,
					float(_dense_char_index) / total)
		if text_display and text_display.text_label:
			text_display.text_label.text = _dense_line.substr(0, _dense_char_index)
		# 進行率に応じてフォントサイズを徐々に拡大
		var progress := float(_dense_char_index) / total
		var new_size := DENSE_FONT_SIZE_START + int(progress * (DENSE_FONT_SIZE_END - DENSE_FONT_SIZE_START))
		if new_size != _dense_last_font_size:
			_dense_last_font_size = new_size
			if text_display and text_display.text_label:
				text_display.text_label.add_theme_font_size_override("normal_font_size", new_size)
		# 50% 進行でカオスフォントに切り替え
		if not _dense_font_switched and _font \
				and _dense_char_index >= _dense_line.length() / 2:
			_dense_font_switched = true
			if text_display and text_display.text_label:
				text_display.text_label.add_theme_font_override("font", _font)
		# 進行に合わせて定期シェイク（後半ほど揺れが大きくなる）
		_dense_shake_timer += delta
		if _dense_shake_timer >= DENSE_SHAKE_INTERVAL:
			_dense_shake_timer = 0.0
			_shake_text_bg(lerpf(1.0, DENSE_SHAKE_MAX, progress))
		if _dense_char_index >= _dense_line.length():
			_dense_animating = false
			_dense_done.emit()
		return

	# カオスフェーズ
	if _phase != _Phase.CHAOS:
		return

	_chaos_timer += delta
	if _chaos_timer >= _chaos_interval:
		_chaos_timer -= _chaos_interval
		_spawn_chaos_label()
		_chaos_interval = maxf(CHAOS_INTERVAL_MIN, _chaos_interval * CHAOS_ACCEL)

	_blackout_elapsed += delta
	_blackout.color.a = minf(1.0, _blackout_elapsed / BLACKOUT_DURATION)

	if _blackout.color.a >= 1.0:
		_phase = _Phase.DONE
		set_process(false)
		# 文字色・フォント・フォントサイズ・位置を元に戻してから完了
		if text_display and text_display.text_label:
			text_display.text_label.add_theme_color_override(
					"default_color", UIConstants.COLOR_TEXT_PRIMARY)
			text_display.text_label.remove_theme_font_override("font")
			text_display.text_label.add_theme_font_size_override("normal_font_size", _original_font_size)
			text_display.text_label.position = _label_true_origin
			text_display.text_label.rotation = 0.0
			text_display.text_label.pivot_offset = Vector2.ZERO
			text_display.text_label.scroll_active = true
		if text_display:
			text_display.block_advance = false
		horror_completed.emit()


# ── カオスラベル生成 ─────────────────────────────────────

func _spawn_first_chaos_label() -> void:
	var lbl := Label.new()
	lbl.text = "スグ"
	if _font:
		lbl.add_theme_font_override("font", _font)
	lbl.add_theme_font_size_override("font_size", CHAOS_FIRST_FONT_SIZE)
	lbl.add_theme_color_override("font_color", Color.BLACK)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.size = get_viewport().size
	lbl.position = Vector2.ZERO
	_chaos_container.add_child(lbl)


func _spawn_chaos_label() -> void:
	var lbl := Label.new()
	lbl.text = "スグ"
	if _font:
		lbl.add_theme_font_override("font", _font)
	var size := randi_range(CHAOS_SIZE_MIN, CHAOS_SIZE_MAX)
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", Color.BLACK)
	lbl.size = Vector2(size * 2.0, size * 1.5)
	lbl.pivot_offset = lbl.size * 0.5
	lbl.position = Vector2(
		randf() * get_viewport().size.x - lbl.pivot_offset.x,
		randf() * get_viewport().size.y - lbl.pivot_offset.y
	)
	lbl.rotation = randf_range(-PI, PI)
	_chaos_container.add_child(lbl)
