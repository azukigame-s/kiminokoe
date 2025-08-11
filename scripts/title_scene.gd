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
	
	# VBoxContainerを画面右から3分の1の範囲に配置
	var vbox = $VBoxContainer
	if vbox:
		vbox.anchor_left = 0.7  # 画面の右3分の1から開始（2/3の位置）
		vbox.anchor_top = 0.3    # 少し下から開始（中央配置）
		vbox.anchor_right = 1.0  # 右端まで
		vbox.anchor_bottom = 0.7 # 少し上で終了（中央配置）
		vbox.offset_left = 20    # 少し右にずらす
		vbox.offset_right = -20  # 右端から少し内側
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER # 垂直中央配置
	
	# タイトルラベルを非表示にする（画像にタイトルが含まれているため）
	if title_label:
		title_label.visible = false
	
	# バージョンラベル設定
	if version_label:
		version_label.text = version_text
		version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		version_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		version_label.add_theme_font_size_override("font_size", 16)
		version_label.add_theme_color_override("font_color", Color.BLACK)

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
	# 明示的にすべての状態で文字色を設定
	button.add_theme_color_override("font_color", Color.BLACK)         # 通常時黒色
	button.add_theme_color_override("font_hover_color", Color.WHITE)   # ホバー時白色
	button.add_theme_color_override("font_pressed_color", Color.WHITE) # 押下時白色
	button.add_theme_color_override("font_focus_color", Color.BLACK)   # フォーカス時黒色
	button.add_theme_color_override("font_disabled_color", Color.GRAY) # 無効時グレー
	button.custom_minimum_size = Vector2(250, 50) # 少し幅を広げる
	
	# ボタンテキストを左寄せに設定
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	# テーマの継承をリセット（既存のテーマの影響を排除）
	button.theme = null
	
	# 透明な背景スタイル
	var transparent_style = StyleBoxFlat.new()
	transparent_style.bg_color = Color.TRANSPARENT  # 完全に透明
	transparent_style.border_width_left = 0
	transparent_style.border_width_right = 0
	transparent_style.border_width_top = 0
	transparent_style.border_width_bottom = 0
	
	# ホバー時のスタイル（透明背景）
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color.TRANSPARENT  # 完全に透明
	hover_style.corner_radius_top_left = 8
	hover_style.corner_radius_top_right = 8
	hover_style.corner_radius_bottom_left = 8
	hover_style.corner_radius_bottom_right = 8
	hover_style.border_width_left = 0
	hover_style.border_width_right = 0
	hover_style.border_width_top = 0
	hover_style.border_width_bottom = 0
	
	# 各状態にスタイルを適用
	button.add_theme_stylebox_override("normal", transparent_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)
	button.add_theme_stylebox_override("focus", transparent_style)

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
				background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
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
