extends Control

## 起動時スプラッシュ画面
## ロゴ動画再生 → フィクション表記 → タイトル画面

const LOGO_VIDEO_PATH = "res://assets/videos/azukigame-s_logo.ogv"
const FICTION_DISPLAY_DURATION = 3.0  # フィクション表記の表示秒数
const FICTION_FADE_DURATION = 0.8  # フェードイン/アウト秒数
const CROSSFADE_DURATION = 1.0  # 動画後の白→背景色クロスフェード秒数

var _video_player: VideoStreamPlayer
var _fiction_label: Label
var _background: ColorRect
var _crossfade_overlay: ColorRect  # 動画→フィクション間のクロスフェード用

signal _advance_requested  # 内部フェーズ進行用（クリックまたは自然終了で発火）

func _ready():
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	_build_ui()
	_start_sequence()

func _build_ui():
	# 黒背景
	_background = ColorRect.new()
	_background.color = UIConstants.COLOR_BASE_DARK
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_background)

	# ロゴ動画プレーヤー
	_video_player = VideoStreamPlayer.new()
	_video_player.name = "VideoPlayer"
	_video_player.set_anchors_preset(Control.PRESET_FULL_RECT)
	_video_player.expand = true
	_video_player.autoplay = false
	add_child(_video_player)

	# クロスフェード用オーバーレイ（動画の上に白→背景色を重ねる）
	_crossfade_overlay = ColorRect.new()
	_crossfade_overlay.color = Color.WHITE
	_crossfade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_crossfade_overlay.modulate.a = 0.0
	_crossfade_overlay.visible = false
	add_child(_crossfade_overlay)

	# フィクション表記ラベル（初期は非表示）
	_fiction_label = Label.new()
	_fiction_label.text = "この物語はフィクションです。\n登場する人物・団体・地名・事件等はすべて架空のものであり、\n実在のものとは一切関係ありません。"
	_fiction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fiction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_fiction_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fiction_label.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_BODY)
	_fiction_label.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_PRIMARY)
	_fiction_label.modulate.a = 0.0
	_fiction_label.visible = false
	add_child(_fiction_label)

func _start_sequence():
	# Phase 1: ロゴ動画再生
	await _play_logo_video()

	# Phase 2: フィクション表記
	await _show_fiction_notice()

	# Phase 3: タイトル画面へ
	SceneManager.goto_title()

## _advance_requested を発火するヘルパー（video.finished / timer.timeout のコールバック用）
func _emit_advance():
	_advance_requested.emit()

## ロゴ動画を再生し、終了またはクリックスキップまで待つ
func _play_logo_video():
	var stream = load(LOGO_VIDEO_PATH)
	if not stream:
		push_warning("[SplashScene] ロゴ動画が見つかりません: %s" % LOGO_VIDEO_PATH)
		return

	_video_player.stream = stream
	_video_player.play()

	# 動画が自然に終了した場合も _advance_requested を発火させる
	_video_player.finished.connect(_emit_advance, CONNECT_ONE_SHOT)
	await _advance_requested

	# クリックスキップ時、finished の接続が残っていれば切る
	if _video_player.finished.is_connected(_emit_advance):
		_video_player.finished.disconnect(_emit_advance)

	# 白→ゲーム背景色へクロスフェード
	_crossfade_overlay.visible = true
	_crossfade_overlay.color = Color.WHITE
	_crossfade_overlay.modulate.a = 1.0
	_video_player.visible = false

	var tween = create_tween()
	tween.tween_property(_crossfade_overlay, "color", UIConstants.COLOR_BASE_DARK, CROSSFADE_DURATION)
	await tween.finished

	_crossfade_overlay.visible = false

## フィクション表記をフェードイン → 表示（タイマーかクリック待ち）→ フェードアウト
func _show_fiction_notice():
	_fiction_label.visible = true

	# フェードイン
	var tween_in = create_tween()
	tween_in.tween_property(_fiction_label, "modulate:a", 1.0, FICTION_FADE_DURATION)
	await tween_in.finished

	# 表示維持（タイマーかクリックで進む）
	var timer = get_tree().create_timer(FICTION_DISPLAY_DURATION)
	timer.timeout.connect(_emit_advance, CONNECT_ONE_SHOT)
	await _advance_requested

	# クリックで早送りした場合、タイマーの接続が残っていれば切る
	if timer.timeout.is_connected(_emit_advance):
		timer.timeout.disconnect(_emit_advance)

	# フェードアウト
	var tween_out = create_tween()
	tween_out.tween_property(_fiction_label, "modulate:a", 0.0, FICTION_FADE_DURATION)
	await tween_out.finished

## クリックで現在のフェーズを進める
## 注意: VideoStreamPlayer.stop() は finished を発火しないため _advance_requested を直接 emit する
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if _video_player.is_playing():
			_video_player.stop()
		_advance_requested.emit()
		get_viewport().set_input_as_handled()