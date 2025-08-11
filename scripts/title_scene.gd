# title_scene.gd
# 保存先: res://scripts/title_scene.gd

extends Control

# UI要素への参照
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var start_button: Button = $VBoxContainer/ButtonContainer/StartButton
@onready var settings_button: Button = $VBoxContainer/ButtonContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/ButtonContainer/QuitButton
@onready var background: TextureRect = $Background
@onready var version_label: Label = $VersionLabel

# 設定値
var title_text: String = "あなたのゲームタイトル"
var version_text: String = "Version 1.0.0"

func _ready():
	print("[TitleScene] Title scene initialized")
	
	# UI要素のセットアップ
	_setup_ui()
	_setup_buttons()
	_setup_background()
	
	# 初期フォーカス設定
	if start_button:
		start_button.grab_focus()

# UI要素のセットアップ
func _setup_ui():
	# フルスクリーン設定
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	# タイトルテキスト設定
	if title_label:
		title_label.text = title_text
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.add_theme_font_size_override("font_size", 48)
		title_label.add_theme_color_override("font_color", Color.WHITE)
	
	# バージョンラベル設定
	if version_label:
		version_label.text = version_text
		version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		version_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		version_label.add_theme_font_size_override("font_size", 16)
		version_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

# ボタンのセットアップ
func _setup_buttons():
	# スタートボタン
	if start_button:
		start_button.text = "ゲームを始める"
		start_button.pressed.connect(_on_start_button_pressed)
		_style_button(start_button)
	
	# 設定ボタン
	if settings_button:
		settings_button.text = "設定"
		settings_button.pressed.connect(_on_settings_button_pressed)
		_style_button(settings_button)
	
	# 終了ボタン
	if quit_button:
		quit_button.text = "終了"
		quit_button.pressed.connect(_on_quit_button_pressed)
		_style_button(quit_button)

# ボタンスタイリング
func _style_button(button: Button):
	if not button:
		return
	
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.YELLOW)
	button.custom_minimum_size = Vector2(200, 50)
	
	# ボタン背景のスタイル設定
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.corner_radius_bottom_left = 8
	normal_style.corner_radius_bottom_right = 8
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = Color(0.5, 0.5, 0.5)
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.3, 0.3, 0.3, 0.9)
	hover_style.corner_radius_top_left = 8
	hover_style.corner_radius_top_right = 8
	hover_style.corner_radius_bottom_left = 8
	hover_style.corner_radius_bottom_right = 8
	hover_style.border_width_left = 2
	hover_style.border_width_right = 2
	hover_style.border_width_top = 2
	hover_style.border_width_bottom = 2
	hover_style.border_color = Color.YELLOW
	
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)

# 背景設定
func _setup_background():
	if background:
		# 既存の背景画像がある場合は使用
		var bg_path = "res://assets/backgrounds/title_bg.jpg"
		if ResourceLoader.exists(bg_path):
			var bg_texture = load(bg_path)
			if bg_texture:
				background.texture = bg_texture
				background.expand = true
				background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		else:
			# 背景画像がない場合はグラデーション背景を作成
			background.texture = _create_gradient_background()
		
		# フルスクリーン設定
		background.anchor_left = 0.0
		background.anchor_top = 0.0
		background.anchor_right = 1.0
		background.anchor_bottom = 1.0

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
	SceneManager.goto_game()

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
				# Enterやスペースキーでゲーム開始
				if start_button and start_button.has_focus():
					_on_start_button_pressed()
			KEY_ESCAPE:
				# Escキーで終了
				_on_quit_button_pressed()
