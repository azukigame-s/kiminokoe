extends Control

## ScenarioEngine のテストスクリプト
## 最小限のシナリオを動かして動作確認

var scenario_engine: ScenarioEngine
var text_display: TextDisplay
var skip_indicator: Label

func _ready():
	print("[TestScenarioEngine] Starting test")

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
	# TextDisplay の作成
	text_display = TextDisplay.new()
	add_child(text_display)

	# TextLabel の作成
	var text_label = RichTextLabel.new()
	text_label.name = "TextLabel"
	text_label.custom_minimum_size = Vector2(800, 200)
	text_label.position = Vector2(100, 300)
	text_label.size = Vector2(800, 200)
	text_label.add_theme_font_size_override("normal_font_size", 24)
	text_display.add_child(text_label)

	# TextDisplay に TextLabel を設定
	text_display.text_label = text_label

	print("[TestScenarioEngine] UI setup complete")

## ScenarioEngine の初期化
func setup_scenario_engine():
	scenario_engine = ScenarioEngine.new()
	add_child(scenario_engine)

	# CommandExecutor に TextDisplay を設定
	scenario_engine.command_executor.text_display = text_display

	print("[TestScenarioEngine] ScenarioEngine setup complete")

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

	print("[TestScenarioEngine] Skip indicator setup complete")

## スキップモード変更時のコールバック
func _on_skip_mode_changed(is_skipping: bool):
	skip_indicator.visible = is_skipping
	print("[TestScenarioEngine] Skip indicator: %s" % ("VISIBLE" if is_skipping else "HIDDEN"))

## テストシナリオの実行
func run_test_scenario():
	print("[TestScenarioEngine] Running test scenario")

	# 簡単なテストシナリオ
	var test_scenario = [
		{
			"type": "dialogue",
			"text": "こんにちは！",
			"new_page": true
		},
		{
			"type": "dialogue",
			"text": "これは新しいScenarioEngineのテストです。",
			"new_page": false
		},
		{
			"type": "dialogue",
			"text": "クリックして次に進んでください。",
			"new_page": true
		},
		{
			"type": "dialogue",
			"text": "スキップモードもテストしてみましょう。",
			"new_page": false
		},
		{
			"type": "dialogue",
			"text": "テスト完了！",
			"new_page": true
		}
	]

	await scenario_engine.start_scenario(test_scenario)

	print("[TestScenarioEngine] Test scenario completed")

## 入力処理（スキップモード切り替え）
func _input(event):
	if event is InputEventKey:
		if event.keycode == KEY_S and event.pressed:
			scenario_engine.toggle_skip_mode()
