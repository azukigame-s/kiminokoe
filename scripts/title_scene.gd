extends Control

## タイトル画面
## UIConstants / UIStyleHelper を使用した統一スタイル

# UI要素への参照
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var start_button: Button = $VBoxContainer/ButtonContainer/StartButton
@onready var continue_button: Button = $VBoxContainer/ButtonContainer/ContinueButton
@onready var trophy_button: Button = $VBoxContainer/ButtonContainer/TrophyButton
@onready var settings_button: Button = $VBoxContainer/ButtonContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/ButtonContainer/QuitButton
@onready var background: TextureRect = $Background
@onready var version_label: Label = $VersionLabel

# 設定値
var title_text: String = "あなたのゲームタイトル"
var version_text: String = "v" + ProjectSettings.get_setting("application/config/version", "0.0.0")

func _ready():
	print("[TitleScene] Title scene initialized")

	# UI要素のセットアップ
	_setup_ui()
	_setup_buttons()
	_setup_background()
	_setup_bgm()

	# 初期フォーカス設定
	if start_button:
		start_button.grab_focus()

# BGMのセットアップ
func _setup_bgm():
	var bgm_path = "res://assets/bgm/悠久の彼方.mp3"
	if not ResourceLoader.exists(bgm_path):
		return
	var player = AudioStreamPlayer.new()
	player.stream = load(bgm_path)
	player.volume_db = 0.0
	add_child(player)
	player.play()

# UI要素のセットアップ
func _setup_ui():
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# VBoxContainerを画面右から3分の1の範囲に配置
	var vbox = $VBoxContainer
	if vbox:
		vbox.anchor_left = 0.7
		vbox.anchor_top = 0.3
		vbox.anchor_right = 1.0
		vbox.anchor_bottom = 0.7
		vbox.offset_left = 20
		vbox.offset_right = -20
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	# タイトルラベルを非表示にする（画像にタイトルが含まれているため）
	if title_label:
		title_label.visible = false

	# バージョンラベル設定
	if version_label:
		version_label.text = version_text
		version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		version_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		version_label.anchor_left = 0.0
		version_label.anchor_top = 0.0
		version_label.anchor_right = 0.5
		version_label.anchor_bottom = 0.0
		version_label.offset_left = 12
		version_label.offset_top = 12
		version_label.offset_right = 0
		version_label.offset_bottom = 32
		version_label.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_CAPTION)
		version_label.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_PRIMARY)

# ボタンのセットアップ
func _setup_buttons():
	if start_button:
		start_button.text = "はじめる"
		start_button.pressed.connect(_on_start_button_pressed)
		UIStyleHelper.style_title_button(start_button)

	# ContinueButton は不要（セーブ情報画面に統合）
	if continue_button:
		continue_button.visible = false

	if trophy_button:
		trophy_button.text = "軌跡"
		trophy_button.pressed.connect(_on_trophy_button_pressed)
		UIStyleHelper.style_title_button(trophy_button)

	if settings_button:
		settings_button.text = "設定"
		settings_button.pressed.connect(_on_settings_button_pressed)
		UIStyleHelper.style_title_button(settings_button)

	if quit_button:
		quit_button.text = "終了"
		quit_button.pressed.connect(_on_quit_button_pressed)
		UIStyleHelper.style_title_button(quit_button)

# 背景設定
func _setup_background():
	if background:
		var bg_path = "res://assets/backgrounds/title_bg.jpg"
		if ResourceLoader.exists(bg_path):
			var bg_texture = load(bg_path)
			if bg_texture:
				background.texture = bg_texture
				background.expand = true
				background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		else:
			background.texture = _create_gradient_background()

		background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

		# 波シェーダーを適用
		var shader_path = "res://assets/shaders/water_wave.gdshader"
		if ResourceLoader.exists(shader_path):
			var mat = ShaderMaterial.new()
			mat.shader = load(shader_path)
			background.material = mat

# グラデーション背景の作成
func _create_gradient_background() -> GradientTexture2D:
	var gradient = Gradient.new()
	gradient.colors = [Color(0.1, 0.1, 0.3), Color(0.3, 0.1, 0.1)]
	gradient.offsets = [0.0, 1.0]

	var gradient_texture = GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.width = 1920
	gradient_texture.height = 1080

	return gradient_texture

# ボタンイベント処理
func _on_start_button_pressed():
	print("[TitleScene] Start button pressed")
	SceneManager.goto_save_info()

func _on_trophy_button_pressed():
	print("[TitleScene] Trophy button pressed")
	SceneManager.goto_trophy()

func _on_settings_button_pressed():
	print("[TitleScene] Settings button pressed")
	SceneManager.goto_settings()

func _on_quit_button_pressed():
	print("[TitleScene] Quit button pressed")
	SceneManager.quit_game()

# キーボード入力処理
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ENTER, KEY_SPACE:
				if start_button and start_button.has_focus():
					_on_start_button_pressed()
			KEY_ESCAPE:
				_on_quit_button_pressed()
