# settings_scene.gd
# 保存先: res://scripts/settings_scene.gd

extends Control

# UI要素への参照
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var text_speed_label: Label = $VBoxContainer/SettingsContainer/TextSpeedContainer/TextSpeedLabel
@onready var text_speed_slider: HSlider = $VBoxContainer/SettingsContainer/TextSpeedContainer/TextSpeedSlider
@onready var text_speed_value: Label = $VBoxContainer/SettingsContainer/TextSpeedContainer/TextSpeedValue
@onready var master_volume_label: Label = $VBoxContainer/SettingsContainer/VolumeContainer/MasterVolumeLabel
@onready var master_volume_slider: HSlider = $VBoxContainer/SettingsContainer/VolumeContainer/MasterVolumeSlider
@onready var master_volume_value: Label = $VBoxContainer/SettingsContainer/VolumeContainer/MasterVolumeValue
@onready var fullscreen_label: Label = $VBoxContainer/SettingsContainer/FullscreenContainer/FullscreenLabel
@onready var fullscreen_checkbox: CheckBox = $VBoxContainer/SettingsContainer/FullscreenContainer/FullscreenCheckBox
@onready var back_button: Button = $VBoxContainer/ButtonContainer/BackButton
@onready var apply_button: Button = $VBoxContainer/ButtonContainer/ApplyButton
@onready var background: ColorRect = $Background

# 設定値
var settings_data = {
	"text_speed": 0.05,
	"master_volume": 0.8,
	"fullscreen": false
}

# 設定ファイルパス
var settings_file_path = "user://settings.cfg"

func _ready():
	print("[SettingsScene] Settings scene initialized")
	
	# 設定の読み込み
	_load_settings()
	
	# UI要素のセットアップ
	_setup_ui()
	_setup_controls()
	_setup_background()
	
	# 現在の設定値をUIに反映
	_apply_settings_to_ui()
	
	# 初期フォーカス設定
	if text_speed_slider:
		text_speed_slider.grab_focus()

# UI要素のセットアップ
func _setup_ui():
	# フルスクリーン設定
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	# タイトル設定
	if title_label:
		title_label.text = "設定"
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.add_theme_font_size_override("font_size", 36)
		title_label.add_theme_color_override("font_color", Color.WHITE)

# コントロール要素のセットアップ
func _setup_controls():
	# テキスト速度スライダー
	if text_speed_slider:
		text_speed_slider.min_value = 0.01
		text_speed_slider.max_value = 0.2
		text_speed_slider.step = 0.01
		text_speed_slider.value_changed.connect(_on_text_speed_changed)
	
	if text_speed_label:
		text_speed_label.text = "テキスト速度"
		text_speed_label.add_theme_font_size_override("font_size", 20)
		text_speed_label.add_theme_color_override("font_color", Color.WHITE)
	
	if text_speed_value:
		text_speed_value.add_theme_font_size_override("font_size", 16)
		text_speed_value.add_theme_color_override("font_color", Color.WHITE)
	
	# マスター音量スライダー
	if master_volume_slider:
		master_volume_slider.min_value = 0.0
		master_volume_slider.max_value = 1.0
		master_volume_slider.step = 0.1
		master_volume_slider.value_changed.connect(_on_master_volume_changed)
	
	if master_volume_label:
		master_volume_label.text = "マスター音量"
		master_volume_label.add_theme_font_size_override("font_size", 20)
		master_volume_label.add_theme_color_override("font_color", Color.WHITE)
	
	if master_volume_value:
		master_volume_value.add_theme_font_size_override("font_size", 16)
		master_volume_value.add_theme_color_override("font_color", Color.WHITE)
	
	# フルスクリーンチェックボックス
	if fullscreen_checkbox:
		fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)
		fullscreen_checkbox.add_theme_font_size_override("font_size", 18)
		fullscreen_checkbox.add_theme_color_override("font_color", Color.WHITE)
	
	if fullscreen_label:
		fullscreen_label.text = "フルスクリーン"
		fullscreen_label.add_theme_font_size_override("font_size", 20)
		fullscreen_label.add_theme_color_override("font_color", Color.WHITE)
	
	# ボタン設定
	if back_button:
		back_button.text = "戻る"
		back_button.pressed.connect(_on_back_button_pressed)
		_style_button(back_button)
	
	if apply_button:
		apply_button.text = "適用"
		apply_button.pressed.connect(_on_apply_button_pressed)
		_style_button(apply_button)

# ボタンスタイリング
func _style_button(button: Button):
	if not button:
		return
	
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.YELLOW)
	button.custom_minimum_size = Vector2(120, 40)
	
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
		background.color = Color(0.1, 0.1, 0.1, 0.9)
		background.anchor_left = 0.0
		background.anchor_top = 0.0
		background.anchor_right = 1.0
		background.anchor_bottom = 1.0

# 設定値をUIに反映
func _apply_settings_to_ui():
	if text_speed_slider:
		text_speed_slider.value = settings_data.text_speed
	if master_volume_slider:
		master_volume_slider.value = settings_data.master_volume
	if fullscreen_checkbox:
		fullscreen_checkbox.button_pressed = settings_data.fullscreen
	
	_update_value_labels()

# 値ラベルの更新
func _update_value_labels():
	if text_speed_value:
		text_speed_value.text = str(snapped(settings_data.text_speed, 0.01))
	if master_volume_value:
		master_volume_value.text = str(int(settings_data.master_volume * 100)) + "%"

# 設定変更イベント
func _on_text_speed_changed(value: float):
	settings_data.text_speed = value
	_update_value_labels()

func _on_master_volume_changed(value: float):
	settings_data.master_volume = value
	_update_value_labels()
	
	# 音量をリアルタイムで適用
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), 
		linear_to_db(settings_data.master_volume))

func _on_fullscreen_toggled(pressed: bool):
	settings_data.fullscreen = pressed

# ボタンイベント
func _on_back_button_pressed():
	print("[SettingsScene] Back button pressed")
	SceneManager.goto_title()

func _on_apply_button_pressed():
	print("[SettingsScene] Apply button pressed")
	_save_settings()
	_apply_settings()

# 設定の保存
func _save_settings():
	var config = ConfigFile.new()
	
	for key in settings_data.keys():
		config.set_value("settings", key, settings_data[key])
	
	var error = config.save(settings_file_path)
	if error == OK:
		print("[SettingsScene] Settings saved successfully")
	else:
		print("[SettingsScene] Failed to save settings: ", error)

# 設定の読み込み
func _load_settings():
	var config = ConfigFile.new()
	var error = config.load(settings_file_path)
	
	if error == OK:
		for key in settings_data.keys():
			if config.has_section_key("settings", key):
				settings_data[key] = config.get_value("settings", key)
		print("[SettingsScene] Settings loaded successfully")
	else:
		print("[SettingsScene] Settings file not found, using defaults")

# 設定の適用
func _apply_settings():
	# ProjectSettingsに反映（ノベルシステムが参照）
	ProjectSettings.set_setting("visual_novel/text_speed", settings_data.text_speed)
	
	# 音量設定の適用
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), 
		linear_to_db(settings_data.master_volume))
	
	# フルスクリーン設定の適用
	if settings_data.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	print("[SettingsScene] Settings applied")

# キーボード入力処理
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				_on_back_button_pressed()
			KEY_ENTER:
				_on_apply_button_pressed()
