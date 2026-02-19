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

	# オートセーブシグナル接続
	scenario_engine.auto_save_requested.connect(_on_auto_save_requested)

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

## ゲーム開始
func _start_game():
	if SceneManager.game_start_mode == "continue":
		await _continue_game()
	else:
		await _new_game()

## プレイ時間の計測
func _process(delta):
	if not get_tree().paused:
		SceneManager.play_time += delta

## 新規ゲーム開始（メインシナリオを最初から）
## play_time は保持（「はじめからはじめる」でも累計を維持するため）
func _new_game():
	print("[GameScene] 新規ゲーム開始")

	var scenario_data = scenario_engine.load_scenario_data("main")
	if scenario_data.is_empty():
		push_error("[GameScene] メインシナリオの読み込みに失敗しました")
		return

	await scenario_engine.start_scenario(scenario_data, "main")

	print("[GameScene] シナリオ完了")
	await _show_demo_ending()

## セーブデータからの続行
func _continue_game():
	print("[GameScene] セーブデータから続行")

	var save_data = SceneManager.load_save_data()
	if save_data.is_empty() or save_data.get("scenario_path", "").is_empty():
		push_error("[GameScene] セーブデータの読み込みに失敗しました。新規ゲームを開始します")
		await _new_game()
		return

	# 主人公名とプレイ時間を復元
	SceneManager.protagonist_name = save_data.get("protagonist_name", "コウ")
	SceneManager.play_time = save_data.get("play_time", 0.0)

	# シナリオエンジンの状態を復元
	var engine_state = {
		"scenario_path": save_data.get("scenario_path", ""),
		"index": save_data.get("index", 0),
		"stack": save_data.get("stack", []),
		"background_path": save_data.get("background_path", ""),
		"bgm_path": save_data.get("bgm_path", ""),
		"effect": save_data.get("effect", "normal"),
		"backlog": save_data.get("backlog", []),
	}
	await scenario_engine.load_from_save_state(engine_state)

	print("[GameScene] シナリオ完了")
	await _show_demo_ending()

## 体験版エンディング画面
func _show_demo_ending():
	# 体験版コンプリートトロフィーのチェック
	TrophyManager.check_demo_complete(SceneManager.play_time)

	# 下部メニューを非表示
	bottom_menu.visible = false

	# ED用オーバーレイ（CanvasLayer で最前面に）
	var canvas = CanvasLayer.new()
	canvas.layer = 50
	add_child(canvas)

	var overlay = ColorRect.new()
	overlay.color = UIConstants.COLOR_BASE_DARK
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.offset_left = 0
	overlay.offset_top = 0
	overlay.offset_right = 0
	overlay.offset_bottom = 0
	overlay.modulate.a = 0.0
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(overlay)

	# フェードイン
	var fade_tween = create_tween()
	fade_tween.tween_property(overlay, "modulate:a", 1.0, 1.5)
	await fade_tween.finished

	# コンテンツ用コンテナ
	var content = VBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_CENTER)
	content.offset_left = -300
	content.offset_right = 300
	content.offset_top = -150
	content.offset_bottom = 150
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 24)
	overlay.add_child(content)

	# 「体験版はここまでです」
	var thanks_label = Label.new()
	thanks_label.text = "体験版をプレイしていただき\nありがとうございました"
	thanks_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	thanks_label.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_HEADING)
	thanks_label.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_PRIMARY)
	content.add_child(thanks_label)

	# 装飾線
	var rule = ColorRect.new()
	rule.color = UIConstants.COLOR_RULE
	rule.custom_minimum_size = Vector2(200, 1)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(rule)

	# トロフィー取得状況
	var trophy_data = TrophyManager.get_trophy_display_data()
	var unlocked = trophy_data.unlocked_count
	var total = trophy_data.total_count

	var trophy_label = Label.new()
	trophy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	trophy_label.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_BODY)

	if unlocked < total:
		trophy_label.text = "軌跡: %d / %d\nまだ見つけていない軌跡があるようです" % [unlocked, total]
		trophy_label.add_theme_color_override("font_color", UIConstants.COLOR_SUB_ACCENT)
	else:
		trophy_label.text = "軌跡: %d / %d\nすべての軌跡を見つけました" % [unlocked, total]
		trophy_label.add_theme_color_override("font_color", UIConstants.COLOR_ACCENT)

	content.add_child(trophy_label)

	# コンテンツをフェードイン
	content.modulate.a = 0.0
	var content_tween = create_tween()
	content_tween.tween_property(content, "modulate:a", 1.0, 1.0)
	await content_tween.finished

	# もどるボタン（コンテンツと一緒に表示）
	var back_button = Button.new()
	back_button.text = "タイトルへもどる"
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UIStyleHelper.style_back_button(back_button)
	content.add_child(back_button)

	# ボタン押下待ち
	await back_button.pressed

	# シナリオ進行のみクリア（名前・プレイ時間・軌跡は保持）
	SceneManager.clear_scenario_progress()

	# タイトルへ
	SceneManager.goto_title()

## オートセーブ処理
func _on_auto_save_requested(save_state: Dictionary) -> void:
	save_state["play_time"] = SceneManager.play_time
	SceneManager.auto_save(save_state)

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
	# 設定画面へ遷移する前にオートセーブを実行
	var save_state = scenario_engine.get_save_state()
	save_state["play_time"] = SceneManager.play_time
	SceneManager.auto_save(save_state)
	# ポーズを解除（シーン遷移でゲームツリーが破棄されるため）
	get_tree().paused = false
	SceneManager.goto_settings("game")

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
