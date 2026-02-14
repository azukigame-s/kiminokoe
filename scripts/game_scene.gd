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
const PauseMenuScript = preload("res://scripts/ui/pause_menu.gd")
const BottomMenuScript = preload("res://scripts/ui/bottom_menu.gd")
const BacklogDisplayScript = preload("res://scripts/ui/backlog_display.gd")

# コンポーネント参照
var scenario_engine
var text_display
var background_display
var audio_manager
var choice_display
var subtitle_display
var toast_notification
var bottom_menu: Control
var backlog_display: Control
var pause_menu: Control

func _ready():
	print("[GameScene] 初期化開始")

	# 自身をフルスクリーンに設定
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# UI構築
	_setup_ui()

	# ScenarioEngine の初期化
	_setup_scenario_engine()

	# 下部メニューの設定
	_setup_bottom_menu()

	# ポーズメニューの設定
	_setup_pause_menu()

	# バックログ表示の設定
	_setup_backlog_display()

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
	text_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style_box = UIStyleHelper.create_panel_style(UIConstants.COLOR_BG_OVERLAY, 0)
	text_panel.add_theme_stylebox_override("panel", style_box)
	add_child(text_panel)

	# TextDisplay
	text_display = Control.new()
	text_display.set_script(TextDisplayScript)
	text_display.name = "TextDisplay"
	text_display.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(text_display)

	# TextLabel（RichTextLabel）
	var text_label = RichTextLabel.new()
	text_label.name = "TextLabel"
	text_label.anchor_left = UIConstants.MARGIN_TEXT
	text_label.anchor_top = UIConstants.MARGIN_TEXT
	text_label.anchor_right = 1.0 - UIConstants.MARGIN_TEXT
	text_label.anchor_bottom = 1.0 - UIConstants.MARGIN_TEXT
	text_label.add_theme_font_size_override("normal_font_size", UIConstants.FONT_SIZE_BODY)
	text_label.add_theme_color_override("default_color", UIConstants.COLOR_TEXT_PRIMARY)
	UIStyleHelper.apply_outline_to_rich_text(text_label)

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

## 下部メニューの設定（ログ / スキップ / メニュー）
func _setup_bottom_menu():
	bottom_menu = Control.new()
	bottom_menu.set_script(BottomMenuScript)
	bottom_menu.name = "BottomMenu"
	add_child(bottom_menu)

	# シグナル接続
	bottom_menu.log_pressed.connect(_on_log_pressed)
	bottom_menu.skip_pressed.connect(_on_skip_pressed)
	bottom_menu.menu_pressed.connect(_on_menu_pressed)

	# スキップモード変更を下部メニューに反映
	scenario_engine.skip_controller.skip_mode_changed.connect(_on_skip_mode_changed)

	# 選択肢表示中は下部メニューを隠す
	choice_display.visibility_changed.connect(_on_choice_visibility_changed)

## ポーズメニューの設定（CanvasLayer で確実に最前面に描画）
func _setup_pause_menu():
	var pause_layer = CanvasLayer.new()
	pause_layer.name = "PauseMenuLayer"
	pause_layer.layer = 40  # ゲーム画面より上、バックログ(50)より下
	pause_layer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	add_child(pause_layer)

	pause_menu = Control.new()
	pause_menu.set_script(PauseMenuScript)
	pause_menu.name = "PauseMenu"
	pause_layer.add_child(pause_menu)

	pause_menu.title_requested.connect(_on_title_requested)
	pause_menu.settings_requested.connect(_on_settings_requested)
	pause_menu.backlog_requested.connect(_on_backlog_from_pause)

	print("[GameScene] ポーズメニュー設定完了")

## バックログ表示の設定（CanvasLayer で確実に最前面に描画）
func _setup_backlog_display():
	var backlog_layer = CanvasLayer.new()
	backlog_layer.name = "BacklogLayer"
	backlog_layer.layer = 50  # ゲーム画面より上、SceneManager のフェード(1000)より下
	backlog_layer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	add_child(backlog_layer)

	backlog_display = Control.new()
	backlog_display.set_script(BacklogDisplayScript)
	backlog_display.name = "BacklogDisplay"
	backlog_layer.add_child(backlog_display)

	backlog_display.closed.connect(_on_backlog_closed)

	print("[GameScene] バックログ表示設定完了")

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

	var scenario_data = scenario_engine.load_scenario_data("main")
	if scenario_data.is_empty():
		push_error("[GameScene] メインシナリオの読み込みに失敗しました")
		return

	await scenario_engine.start_scenario(scenario_data, "main")

	print("[GameScene] シナリオ完了")

## スキップモード変更時のコールバック
func _on_skip_mode_changed(is_skipping: bool):
	bottom_menu.set_skip_active(is_skipping)

## 下部メニューからのシグナル処理
func _on_log_pressed():
	_open_backlog()

func _on_skip_pressed():
	scenario_engine.toggle_skip_mode()

func _on_menu_pressed():
	if not pause_menu.is_open:
		pause_menu.open()

## 選択肢表示状態の変更時
func _on_choice_visibility_changed():
	if choice_display.visible:
		bottom_menu.visible = false
	else:
		bottom_menu.visible = true

## バックログを開く
var _backlog_paused_by_us: bool = false

func _open_backlog():
	# ポーズメニューから開いた場合はすでに一時停止中
	if not get_tree().paused:
		get_tree().paused = true
		_backlog_paused_by_us = true
	var history = scenario_engine.backlog_manager.get_history()
	print("[GameScene] バックログ表示: %d 件のエントリ" % history.size())
	if history.size() > 0:
		print("[GameScene] 最新エントリ: %s" % history[-1].get("text", "(empty)"))
	backlog_display.open(history)
	bottom_menu.visible = false

## ポーズメニューからバックログを開く
func _on_backlog_from_pause():
	pause_menu.visible = false
	_open_backlog()

## バックログが閉じられた時
func _on_backlog_closed():
	if pause_menu.is_open:
		# ポーズメニューから開いた場合 → ポーズメニューに戻る
		pause_menu.visible = true
	elif _backlog_paused_by_us:
		# 下部メニューから開いた場合 → 一時停止を解除
		get_tree().paused = false
	_backlog_paused_by_us = false
	bottom_menu.visible = true

## ポーズメニューからのシグナル処理
func _on_title_requested():
	SceneManager.goto_title()

func _on_settings_requested():
	SceneManager.goto_settings()

## 入力処理
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				if backlog_display.is_open:
					backlog_display.close()
				elif not pause_menu.is_open:
					pause_menu.open()
			KEY_L:
				# Lキーでバックログ開閉
				if backlog_display.is_open:
					backlog_display.close()
				elif not pause_menu.is_open:
					_open_backlog()
			KEY_S:
				# Sキーでスキップモード切り替え（ポーズ中・バックログ中は無視）
				if not pause_menu.is_open and not backlog_display.is_open:
					scenario_engine.toggle_skip_mode()
			KEY_T:
				var trophy_manager = get_node_or_null("/root/TrophyManager")
				if trophy_manager:
					if event.shift_pressed:
						trophy_manager.reset_trophy_data()
						print("[GameScene] トロフィーデータをリセットしました")
					else:
						trophy_manager.print_trophy_status()
