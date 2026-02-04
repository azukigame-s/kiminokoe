extends Control

## ScenarioEngine のテストスクリプト
## Step 2: 背景、BGM/SFX、テキストバッファのテスト

# スクリプトをpreloadで読み込み
const BackgroundDisplayScript = preload("res://scripts/ui/background_display.gd")
const AudioManagerScript = preload("res://scripts/ui/audio_manager.gd")
const TextDisplayScript = preload("res://scripts/ui/text_display.gd")
const ScenarioEngineScript = preload("res://scripts/core/scenario_engine.gd")

var scenario_engine
var text_display
var background_display
var audio_manager
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

	# Step 2 のテストシナリオ
	# 背景、BGM、テキストバッファ、go_next をテスト
	var test_scenario = [
		# 背景設定
		{
			"type": "background",
			"path": "res://assets/backgrounds/sea.jpg"
		},
		# BGM再生（ファイルが存在しない場合は警告が出るだけ）
		{
			"type": "bgm",
			"path": "res://assets/music/sample_bgm.mp3"
		},
		# テキスト表示（新しいページ）
		{
			"type": "dialogue",
			"text": "車窓を流れる景色――。見えるのは青い空、そして青い海。",
			"new_page": true
		},
		# テキスト追加（同じページに追加）
		{
			"type": "dialogue",
			"text": "そんな景色を眺めながら僕はバスに揺られていた。"
		},
		# テキスト追加（同じページに追加、go_next付き）
		{
			"type": "dialogue",
			"text": "僕はこの席が好きだった。",
			"go_next": true
		},
		# 新しいページ
		{
			"type": "dialogue",
			"text": "理由は２つ。",
			"new_page": true
		},
		{
			"type": "dialogue",
			"text": "フロントガラスから左の車窓にかけて、大パノラマの景色を拝むことができるというのがひとつ。"
		},
		{
			"type": "dialogue",
			"text": "運賃箱を見るのが好き、というのがもうひとつだ。",
			"go_next": true
		},
		# 背景変更
		{
			"type": "background",
			"path": "res://assets/backgrounds/busstop.jpg"
		},
		# 新しいページ
		{
			"type": "dialogue",
			"text": "バス停に到着した。",
			"new_page": true
		},
		# テスト完了
		{
			"type": "dialogue",
			"text": "【Step 2 テスト完了】背景、BGM、テキストバッファが動作しました！",
			"new_page": true
		}
	]

	await scenario_engine.start_scenario(test_scenario)

	print("[TestScenarioEngine] テストシナリオ完了")

## 入力処理（スキップモード切り替え）
func _input(event):
	if event is InputEventKey:
		if event.keycode == KEY_S and event.pressed:
			scenario_engine.toggle_skip_mode()