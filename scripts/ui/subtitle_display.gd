extends Control
class_name SubtitleDisplay

## サブタイトル表示コンポーネント
## 黒背景 + タイプエフェクト + フェードアウト
## 旧 subtitle_scene.gd と同等の機能

# シグナル
signal subtitle_completed

# 内部ノード
var _background: ColorRect
var _label: Label

# 状態管理
enum State { IDLE, TYPING, DISPLAYING, FADING }
var _state: State = State.IDLE

# タイプエフェクト用
var _full_text: String = ""
var _displayed_text: String = ""
var _type_timer: float = 0.0
var _type_speed: float = 0.05

# アニメーション設定
var _fade_time: float = 1.0
var _display_time: float = 2.0

# Tween参照（キャンセル用）
var _current_tween: Tween

# クリックスキップ保護（表示直後の誤スキップ防止）
var _skip_protection_timer: float = 0.0
const SKIP_PROTECTION_TIME: float = 0.5  # 表示後0.5秒はクリックスキップ無効

func _ready():
	visible = false
	z_index = -1
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # 非表示時はイベントを無視

	# 全画面レイアウト
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0

	# 黒背景
	_background = ColorRect.new()
	_background.name = "background"
	_background.color = Color(0, 0, 0, 1)
	_background.anchor_left = 0.0
	_background.anchor_top = 0.0
	_background.anchor_right = 1.0
	_background.anchor_bottom = 1.0
	_background.offset_left = 0
	_background.offset_top = 0
	_background.offset_right = 0
	_background.offset_bottom = 0
	_background.visible = false
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background)

	# テキストラベル
	_label = Label.new()
	_label.name = "subtitle_label"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.anchor_left = 0.5
	_label.anchor_top = 0.5
	_label.anchor_right = 0.5
	_label.anchor_bottom = 0.5
	_label.add_theme_font_size_override("font_size", 48)
	_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_label.modulate = Color(1, 1, 1, 1)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)

	# テーマ適用
	var theme_path = "res://themes/novel_theme.tres"
	if ResourceLoader.exists(theme_path):
		var custom_theme = load(theme_path)
		if custom_theme:
			_label.theme = custom_theme
			print("[SubtitleDisplay] テーマ適用完了")

	# ラベル位置を1フレーム後に調整
	await get_tree().process_frame
	_update_label_position()

## サブタイトルを表示
func show_subtitle(text: String, p_fade_time: float = 1.0, p_display_time: float = 2.0) -> void:
	if _state != State.IDLE:
		print("[SubtitleDisplay] 表示中のためスキップ: %s (state: %s)" % [text, _state])
		return

	# ノードの存在チェック
	if not _background or not _label:
		push_error("[SubtitleDisplay] ノードが見つかりません")
		subtitle_completed.emit()
		return

	_fade_time = p_fade_time
	_display_time = p_display_time
	_state = State.TYPING

	print("[SubtitleDisplay] 表示開始: %s (fade: %s, display: %s)" % [text, _fade_time, _display_time])

	# タイプエフェクト設定
	_full_text = text
	_displayed_text = ""
	_label.text = ""

	# タイプ速度を計算（旧システムと同じ: fade_time / 文字数）
	if text.length() > 0:
		_type_speed = _fade_time / text.length()
	else:
		_type_speed = 0.05

	# ラベル位置を更新（旧システムの _start_type_effect と同様）
	_update_label_position()

	# 表示設定
	_background.visible = true
	_background.modulate = Color(1, 1, 1, 1)
	_label.modulate = Color(1, 1, 1, 1)
	visible = true
	modulate = Color(1, 1, 1, 1)
	z_index = 1000

	# クリックスキップ保護（表示直後の誤クリック防止）
	_skip_protection_timer = SKIP_PROTECTION_TIME

	# マウスイベントを遮断（下のTextDisplayにクリックが届かないようにする）
	mouse_filter = Control.MOUSE_FILTER_STOP

	# タイプエフェクト開始
	_type_timer = 0.0

## タイプエフェクト処理
func _process(delta: float) -> void:
	# スキップ保護タイマーの更新
	if _skip_protection_timer > 0:
		_skip_protection_timer -= delta

	if _state != State.TYPING:
		return

	_type_timer += delta
	if _type_timer >= _type_speed:
		_type_timer = 0.0
		if _displayed_text.length() < _full_text.length():
			_displayed_text += _full_text[_displayed_text.length()]
			_label.text = _displayed_text
		else:
			# タイプエフェクト完了
			_state = State.DISPLAYING
			print("[SubtitleDisplay] タイプ完了、表示待機 %s秒" % _display_time)
			_start_display_wait()

## 表示時間の待機
func _start_display_wait() -> void:
	await get_tree().create_timer(_display_time).timeout
	# 待機中にスキップされた場合はフェードに進まない
	if _state == State.DISPLAYING:
		_start_fade_out()

## フェードアウト開始
func _start_fade_out() -> void:
	if _state == State.FADING or _state == State.IDLE:
		return

	_state = State.FADING
	print("[SubtitleDisplay] フェードアウト開始")

	# 既存のTweenをキャンセル
	if _current_tween:
		_current_tween.kill()

	_current_tween = create_tween()
	_current_tween.set_parallel(true)

	if _background:
		_current_tween.tween_property(_background, "modulate", Color(1, 1, 1, 0), _fade_time)
	if _label:
		_current_tween.tween_property(_label, "modulate", Color(1, 1, 1, 0), _fade_time)

	await _current_tween.finished

	# 完全に非表示
	visible = false
	if _background:
		_background.visible = false
	z_index = -1
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # イベント遮断を解除
	_current_tween = null

	_state = State.IDLE
	print("[SubtitleDisplay] 完了")
	subtitle_completed.emit()

## 即座にスキップ
func skip_subtitle() -> void:
	if _state == State.IDLE or _state == State.FADING:
		return

	print("[SubtitleDisplay] スキップ (state: %s)" % _state)

	# タイプ中なら全文を即表示
	if _state == State.TYPING:
		_displayed_text = _full_text
		_label.text = _full_text

	# フェードアウトへ直接遷移
	_start_fade_out()

## クリックでスキップ（_gui_input で旧システムと同様の挙動）
func _gui_input(event: InputEvent) -> void:
	if _state == State.IDLE or _state == State.FADING:
		return

	# スキップ保護期間中はクリックを無視
	if _skip_protection_timer > 0:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			skip_subtitle()
			accept_event()

## ラベル位置の更新（画面サイズに応じて）
func _update_label_position() -> void:
	if not _label:
		return

	var screen_width = get_viewport_rect().size.x
	var label_width = screen_width * 0.8
	var font_size = 48

	_label.offset_left = -label_width / 2.0
	_label.offset_top = -font_size / 2.0
	_label.offset_right = label_width / 2.0
	_label.offset_bottom = font_size / 2.0