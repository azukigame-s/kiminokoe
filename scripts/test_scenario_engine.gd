extends Control

## ScenarioEngine のテストスクリプト
## Step 5: 選択肢のテスト

# スクリプトをpreloadで読み込み
const BackgroundDisplayScript = preload("res://scripts/ui/background_display.gd")
const AudioManagerScript = preload("res://scripts/ui/audio_manager.gd")
const TextDisplayScript = preload("res://scripts/ui/text_display.gd")
const ChoiceDisplayScript = preload("res://scripts/ui/choice_display.gd")
const ScenarioEngineScript = preload("res://scripts/core/scenario_engine.gd")

var scenario_engine
var text_display
var background_display
var audio_manager
var choice_display
var skip_indicator: Label

func _ready():
	print("[TestScenarioEngine] テスト開始")

	# 自身（Control）をフルスクリーンに設定
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0

	# UI構築
	setup_ui()

	# ScenarioEngine の初期化
	setup_scenario_engine()

	# スキップインジケータの設定
	setup_skip_indicator()

	# テストシナリオの実行
	await get_tree().create_timer(0.5).timeout
	run_test_scenario()

## UI構築
func setup_ui():
	# 背景表示の作成
	background_display = TextureRect.new()
	background_display.set_script(BackgroundDisplayScript)
	background_display.name = "BackgroundDisplay"
	# フルスクリーン設定（add_child前に設定が必要）
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

	# TextDisplay の作成
	text_display = Control.new()
	text_display.set_script(TextDisplayScript)
	text_display.name = "TextDisplay"
	text_display.anchor_left = 0.0
	text_display.anchor_top = 0.0
	text_display.anchor_right = 1.0
	text_display.anchor_bottom = 1.0
	add_child(text_display)

	# TextLabel の作成
	var text_label = RichTextLabel.new()
	text_label.name = "TextLabel"
	text_label.anchor_left = 0.1
	text_label.anchor_top = 0.1
	text_label.anchor_right = 0.9
	text_label.anchor_bottom = 0.9
	text_label.add_theme_font_size_override("normal_font_size", 24)
	text_label.add_theme_color_override("default_color", Color.WHITE)
	text_display.add_child(text_label)

	# TextDisplay に TextLabel を設定
	text_display.text_label = text_label

	# AudioManager の作成
	audio_manager = Node.new()
	audio_manager.set_script(AudioManagerScript)
	audio_manager.name = "AudioManager"
	add_child(audio_manager)

	# ChoiceDisplay の作成
	choice_display = Control.new()
	choice_display.set_script(ChoiceDisplayScript)
	choice_display.name = "ChoiceDisplay"
	add_child(choice_display)

	print("[TestScenarioEngine] UI構築完了")

## ScenarioEngine の初期化
func setup_scenario_engine():
	scenario_engine = Node.new()
	scenario_engine.set_script(ScenarioEngineScript)
	add_child(scenario_engine)

	# CommandExecutor に各コンポーネントを設定
	scenario_engine.command_executor.text_display = text_display
	scenario_engine.command_executor.background_display = background_display
	scenario_engine.command_executor.audio_manager = audio_manager
	scenario_engine.command_executor.choice_display = choice_display

	print("[TestScenarioEngine] ScenarioEngine 初期化完了")

## スキップインジケータの設定
func setup_skip_indicator():
	# スキップインジケータの作成
	skip_indicator = Label.new()
	skip_indicator.text = "⏩ SKIP"
	skip_indicator.position = Vector2(900, 20)
	skip_indicator.add_theme_font_size_override("font_size", 32)
	skip_indicator.add_theme_color_override("font_color", Color.RED)
	skip_indicator.visible = false
	add_child(skip_indicator)

	# SkipController のシグナルに接続
	scenario_engine.skip_controller.skip_mode_changed.connect(_on_skip_mode_changed)

	print("[TestScenarioEngine] スキップインジケータ設定完了")

## スキップモード変更時のコールバック
func _on_skip_mode_changed(is_skipping: bool):
	skip_indicator.visible = is_skipping
	print("[TestScenarioEngine] スキップインジケータ: %s" % ("表示" if is_skipping else "非表示"))

## テストシナリオの実行
func run_test_scenario():
	print("[TestScenarioEngine] テストシナリオ実行開始")

	# JSONファイルからテストシナリオを読み込み
	var scenario_data = await scenario_engine.load_scenario_data("test_step5")
	if scenario_data.is_empty():
		print("[TestScenarioEngine] テストシナリオの読み込みに失敗しました")
		return

	await scenario_engine.start_scenario(scenario_data, "test_step5")

	print("[TestScenarioEngine] テストシナリオ完了")

	# テスト結果をコンソールに出力
	print_test_results()

## テスト結果をコンソールに出力
func print_test_results():
	print("")
	print("========== テスト結果 ==========")

	# TrophyManager の状態確認
	var trophy_manager = get_node_or_null("/root/TrophyManager")
	if trophy_manager:
		trophy_manager.print_trophy_status()
	else:
		print("[TestScenarioEngine] TrophyManager が見つかりません（オートロード未設定？）")

	# ScenarioEngine のセーブ状態確認
	var save_state = scenario_engine.get_save_state()
	print("[TestScenarioEngine] セーブ状態: %s" % str(save_state))
	print("================================")

## 入力処理（スキップモード切り替え / デバッグ）
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_S:
				scenario_engine.toggle_skip_mode()
			KEY_T:
				# Tキーでトロフィー状態を表示
				var trophy_manager = get_node_or_null("/root/TrophyManager")
				if trophy_manager:
					trophy_manager.print_trophy_status()