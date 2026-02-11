extends Control

## 設定画面
## UIConstants / UIStyleHelper を使用した統一スタイル

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
	set_anchors_preset(Control.PRESET_FULL_RECT)

	if title_label:
		title_label.text = "設定"
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_TITLE)
		title_label.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_PRIMARY)

# コントロール要素のセットアップ
func _setup_controls():
	# テキスト速度
	if text_speed_slider:
		text_speed_slider.min_value = 0.01
		text_speed_slider.max_value = 0.2
		text_speed_slider.step = 0.01
		text_speed_slider.value_changed.connect(_on_text_speed_changed)

	_style_label(text_speed_label, "テキスト速度")
	_style_value_label(text_speed_value)

	# マスター音量
	if master_volume_slider:
		master_volume_slider.min_value = 0.0
		master_volume_slider.max_value = 1.0
		master_volume_slider.step = 0.1
		master_volume_slider.value_changed.connect(_on_master_volume_changed)

	_style_label(master_volume_label, "マスター音量")
	_style_value_label(master_volume_value)

	# フルスクリーン
	if fullscreen_checkbox:
		fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)
		fullscreen_checkbox.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_CAPTION + 2)
		fullscreen_checkbox.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_PRIMARY)

	_style_label(fullscreen_label, "フルスクリーン")

	# ボタン
	if back_button:
		back_button.text = "戻る"
		back_button.pressed.connect(_on_back_button_pressed)
		UIStyleHelper.style_menu_button(back_button)

	if apply_button:
		apply_button.text = "適用"
		apply_button.pressed.connect(_on_apply_button_pressed)
		UIStyleHelper.style_menu_button(apply_button)

func _style_label(label: Label, text: String) -> void:
	if label:
		label.text = text
		label.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_BUTTON_NORMAL)
		label.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_PRIMARY)

func _style_value_label(label: Label) -> void:
	if label:
		label.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_CAPTION)
		label.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_PRIMARY)

# 背景設定
func _setup_background():
	if background:
		background.color = UIConstants.COLOR_BG_DARK
		background.set_anchors_preset(Control.PRESET_FULL_RECT)

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
