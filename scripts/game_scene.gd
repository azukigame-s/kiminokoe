extends Control

## 本番用ゲームシーン
## ScenarioEngine を使ったビジュアルノベルの実行環境

# スクリプトのpreload
const BackgroundDisplayScript = preload("res://scripts/ui/background_display.gd")
const AudioManagerScript = preload("res://scripts/ui/audio_manager.gd")
const TextDisplayScript = preload("res://scripts/ui/text_display.gd")
const ChoiceDisplayScript = preload("res://scripts/ui/choice_display.gd")
const SubtitleDisplayScript = preload("res://scripts/ui/subtitle_display.gd")
const ToastNotificationScript = preload("res://scripts/toast_notification.gd")
const ScenarioEngineScript = preload("res://scripts/core/scenario_engine.gd")

# コンポーネント参照
var scenario_engine
var text_display
var background_display
var audio_manager
var choice_display
var subtitle_display
var toast_notification
var skip_indicator: Label

func _ready():
	print("[GameScene] 初期化開始")

	# 自身をフルスクリーンに設定
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0

	# UI構築
	_setup_ui()

	# ScenarioEngine の初期化
	_setup_scenario_engine()

	# スキップインジケータの設定
	_setup_skip_indicator()

	# TrophyManager にトースト通知を接続
	_setup_trophy_manager()

	# シナリオ実行開始（少し待ってから）
	await get_tree().create_timer(0.3).timeout
	_start_game()

## UI構築
func _setup_ui():
	# 背景表示
	background_display = TextureRect.new()
	background_display.set_script(BackgroundDisplayScript)
	background_display.name = "BackgroundDisplay"
	background_display.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background_display)

	# テキスト表示用の半透明パネル
	var text_panel = Panel.new()
	text_panel.name = "TextPanel"
	text_panel.anchor_left = 0.0
	text_panel.anchor_top = 0.0
	text_panel.anchor_right = 1.0
	text_panel.anchor_bottom = 1.0

	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0, 0, 0, 0.5)
	text_panel.add_theme_stylebox_override("panel", style_box)
	add_child(text_panel)

	# TextDisplay
	text_display = Control.new()
	text_display.set_script(TextDisplayScript)
	text_display.name = "TextDisplay"
	text_display.anchor_left = 0.0
	text_display.anchor_top = 0.0
	text_display.anchor_right = 1.0
	text_display.anchor_bottom = 1.0
	add_child(text_display)

	# TextLabel（RichTextLabel）
	var text_label = RichTextLabel.new()
	text_label.name = "TextLabel"
	text_label.anchor_left = 0.1
	text_label.anchor_top = 0.1
	text_label.anchor_right = 0.9
	text_label.anchor_bottom = 0.9
	text_label.add_theme_font_size_override("normal_font_size", 24)
	text_label.add_theme_color_override("default_color", Color.WHITE)

	# テーマ適用
	var theme_path = "res://themes/novel_theme.tres"
	if ResourceLoader.exists(theme_path):
		var custom_theme = load(theme_path)
		if custom_theme:
			text_label.theme = custom_theme

	text_display.add_child(text_label)
	text_display.text_label = text_label

	# AudioManager
	audio_manager = Node.new()
	audio_manager.set_script(AudioManagerScript)
	audio_manager.name = "AudioManager"
	add_child(audio_manager)

	# ChoiceDisplay
	choice_display = Control.new()
	choice_display.set_script(ChoiceDisplayScript)
	choice_display.name = "ChoiceDisplay"
	add_child(choice_display)

	# SubtitleDisplay
	subtitle_display = Control.new()
	subtitle_display.set_script(SubtitleDisplayScript)
	subtitle_display.name = "SubtitleDisplay"
	add_child(subtitle_display)

	# ToastNotification
	toast_notification = Control.new()
	toast_notification.set_script(ToastNotificationScript)
	toast_notification.name = "toast_notification"
	add_child(toast_notification)

	print("[GameScene] UI構築完了")

## ScenarioEngine の初期化
func _setup_scenario_engine():
	scenario_engine = Node.new()
	scenario_engine.set_script(ScenarioEngineScript)
	add_child(scenario_engine)

	# CommandExecutor に各コンポーネントを接続
	var executor = scenario_engine.command_executor
	executor.text_display = text_display
	executor.background_display = background_display
	executor.audio_manager = audio_manager
	executor.choice_display = choice_display
	executor.subtitle_display = subtitle_display

	print("[GameScene] ScenarioEngine 初期化完了")

## スキップインジケータの設定
func _setup_skip_indicator():
	skip_indicator = Label.new()
	skip_indicator.text = "⏩ SKIP"
	skip_indicator.position = Vector2(900, 20)
	skip_indicator.add_theme_font_size_override("font_size", 32)
	skip_indicator.add_theme_color_override("font_color", Color.RED)
	skip_indicator.visible = false
	add_child(skip_indicator)

	scenario_engine.skip_controller.skip_mode_changed.connect(_on_skip_mode_changed)

## TrophyManager との接続
func _setup_trophy_manager():
	var trophy_manager = get_node_or_null("/root/TrophyManager")
	if trophy_manager:
		trophy_manager.toast_notification = toast_notification
		print("[GameScene] TrophyManager にトースト通知を接続しました")
	else:
		print("[GameScene] TrophyManager が見つかりません")

## ゲーム開始（メインシナリオを読み込み）
func _start_game():
	print("[GameScene] メインシナリオ読み込み開始")

	var scenario_data = await scenario_engine.load_scenario_data("main")
	if scenario_data.is_empty():
		push_error("[GameScene] メインシナリオの読み込みに失敗しました")
		return

	await scenario_engine.start_scenario(scenario_data, "main")

	print("[GameScene] シナリオ完了")

## スキップモード変更時のコールバック
func _on_skip_mode_changed(is_skipping: bool):
	skip_indicator.visible = is_skipping

## 入力処理
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_S:
				# Sキーでスキップモード切り替え
				scenario_engine.toggle_skip_mode()
			KEY_T:
				# Tキーでトロフィー状態表示（デバッグ用）
				var trophy_manager = get_node_or_null("/root/TrophyManager")
				if trophy_manager:
					trophy_manager.print_trophy_status()