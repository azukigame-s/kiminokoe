extends Control

## 設定画面
## トロフィー画面と同じデザインで統一

# UI要素への参照
var text_speed_slider: HSlider
var text_speed_label: Label
var master_volume_slider: HSlider
var master_volume_value: Label
var window_mode_button: Button
var apply_button: Button

# テキスト速度の段階定義（スライダー値 → ラベル）
# スライダーは 1〜5 の整数値、左がゆっくり・右が速い
var text_speed_steps = [
	{"value": 1, "speed": 0.16, "label": "とてもゆっくり"},
	{"value": 2, "speed": 0.10, "label": "ゆっくり"},
	{"value": 3, "speed": 0.06, "label": "ふつう"},
	{"value": 4, "speed": 0.04, "label": "速い"},
	{"value": 5, "speed": 0.02, "label": "とても速い"}
]

# ウィンドウモードの選択肢（循環）
var window_mode_options = [
	{"id": "fullscreen", "label": "フルスクリーン"},
	{"id": "1280x720", "label": "1280 × 720"},
	{"id": "1920x1080", "label": "1920 × 1080"}
]
var current_window_mode_index = 0

# 設定値
var settings_data = {
	"text_speed": 0.06,
	"master_volume": 0.8,
	"window_mode": "fullscreen"  # "fullscreen", "1280x720", "1920x1080"
}

# 設定ファイルパス
var settings_file_path = "user://settings.cfg"

func _ready():
	print("[SettingsScene] Settings scene initialized")
	
	# 設定の読み込み
	_load_settings()
	
	# UI要素の構築
	_build_ui()
	
	# 現在の設定値をUIに反映
	_apply_settings_to_ui()
	
	# 初期フォーカス設定
	if text_speed_slider:
		text_speed_slider.grab_focus()

func _build_ui():
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# 背景（墨色 95%）
	var bg = ColorRect.new()
	bg.color = Color(UIConstants.COLOR_BASE_DARK, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# ── タイトルエリア ──
	_build_title_area()
	
	# スクロールコンテナ
	var scroll = ScrollContainer.new()
	scroll.name = "ScrollContainer"
	scroll.anchor_left = 0.12
	scroll.anchor_top = 0.0
	scroll.anchor_right = 0.88
	scroll.anchor_bottom = 1.0
	scroll.offset_top = 70
	scroll.offset_bottom = -80
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	
	var content = VBoxContainer.new()
	content.name = "Content"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 4)
	scroll.add_child(content)
	
	# 設定項目
	content.add_child(_create_setting_entry("テキスト速度", "text_speed"))
	content.add_child(_create_separator())
	content.add_child(_create_setting_entry("マスター音量", "master_volume"))
	content.add_child(_create_separator())
	content.add_child(_create_setting_entry("ウィンドウモード", "window_mode"))
	
	# ボタンエリア（スクロール外、画面下部に固定）
	_build_button_area()
	
	# もどるボタン
	var back_button = Button.new()
	back_button.text = "もどる"
	back_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyleHelper.style_back_button(back_button)
	back_button.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	back_button.offset_top = -35
	back_button.offset_bottom = -12
	back_button.pressed.connect(func(): SceneManager.goto_return_from_settings())
	add_child(back_button)

## タイトルエリア（装飾線 ── 設定 ── の形）
func _build_title_area():
	var title_container = HBoxContainer.new()
	title_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title_container.offset_top = 22
	title_container.offset_bottom = 58
	title_container.offset_left = 60
	title_container.offset_right = -60
	title_container.alignment = BoxContainer.ALIGNMENT_CENTER
	title_container.add_theme_constant_override("separation", 16)
	add_child(title_container)
	
	title_container.add_child(_create_rule())
	
	var title = Label.new()
	title.text = "設定"
	title.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_HEADING)
	title.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_PRIMARY)
	title_container.add_child(title)
	
	title_container.add_child(_create_rule())

## 装飾線を作成
func _create_rule() -> Control:
	var rule_wrapper = Control.new()
	rule_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rule_wrapper.custom_minimum_size.y = 1
	
	var rule = ColorRect.new()
	rule.color = UIConstants.COLOR_RULE
	rule.set_anchors_preset(Control.PRESET_CENTER)
	rule.anchor_left = 0.0
	rule.anchor_right = 1.0
	rule.offset_top = -0.5
	rule.offset_bottom = 0.5
	rule.offset_left = 0
	rule.offset_right = 0
	rule_wrapper.add_child(rule)
	
	return rule_wrapper

## 区切り線を作成
func _create_separator() -> ColorRect:
	var sep = ColorRect.new()
	sep.color = UIConstants.COLOR_SEPARATOR
	sep.custom_minimum_size = Vector2(0, 1)
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return sep

## 設定項目エントリを作成
func _create_setting_entry(label_text: String, setting_key: String) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style = StyleBoxFlat.new()
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_right = 2
	style.bg_color = UIConstants.COLOR_ENTRY_BG
	style.border_width_left = 3
	style.border_color = UIConstants.COLOR_ENTRY_BORDER

	panel.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(hbox)

	var font_size = UIConstants.FONT_SIZE_BUTTON_NORMAL

	# ラベル
	var name_label = Label.new()
	name_label.text = label_text
	name_label.add_theme_font_size_override("font_size", font_size)
	name_label.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_PRIMARY)
	name_label.custom_minimum_size.x = 160
	hbox.add_child(name_label)

	# コントロール
	if setting_key == "text_speed":
		var slider = HSlider.new()
		slider.name = "TextSpeedSlider"
		slider.min_value = 1
		slider.max_value = 5
		slider.step = 1
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.custom_minimum_size.y = 24
		slider.value_changed.connect(_on_text_speed_changed)
		_style_slider(slider)
		text_speed_slider = slider
		hbox.add_child(slider)

		var value_label = Label.new()
		value_label.name = "TextSpeedLabel"
		value_label.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_CAPTION)
		value_label.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_SECONDARY)
		value_label.custom_minimum_size.x = 120
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		text_speed_label = value_label
		hbox.add_child(value_label)

	elif setting_key == "master_volume":
		var slider = HSlider.new()
		slider.name = "MasterVolumeSlider"
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.1
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.custom_minimum_size.y = 24
		slider.value_changed.connect(_on_master_volume_changed)
		_style_slider(slider)
		master_volume_slider = slider
		hbox.add_child(slider)

		var value_label = Label.new()
		value_label.name = "MasterVolumeValue"
		value_label.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_CAPTION)
		value_label.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_SECONDARY)
		value_label.custom_minimum_size.x = 120
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		master_volume_value = value_label
		hbox.add_child(value_label)

	elif setting_key == "window_mode":
		var mode_button = Button.new()
		mode_button.name = "WindowModeButton"
		mode_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mode_button.pressed.connect(_on_window_mode_clicked)
		UIStyleHelper.style_menu_button(mode_button)
		window_mode_button = mode_button
		hbox.add_child(mode_button)

	return panel

## ボタンエリアを作成
func _build_button_area():
	var button_container = HBoxContainer.new()
	button_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	button_container.offset_top = -80
	button_container.offset_bottom = -60
	button_container.offset_left = 60
	button_container.offset_right = -60
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(button_container)
	
	# 適用ボタン
	apply_button = Button.new()
	apply_button.text = "適用する"
	apply_button.pressed.connect(_on_apply_button_pressed)
	UIStyleHelper.style_title_button(apply_button)
	apply_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button_container.add_child(apply_button)

## スライダーの和風スタイル設定
func _style_slider(slider: HSlider):
	# トラック（背景線）— 丁子茶の薄い線
	var track_style = StyleBoxFlat.new()
	track_style.bg_color = Color(UIConstants.COLOR_SUB_ACCENT, 0.3)
	track_style.content_margin_top = 4
	track_style.content_margin_bottom = 4
	track_style.corner_radius_top_left = 2
	track_style.corner_radius_top_right = 2
	track_style.corner_radius_bottom_left = 2
	track_style.corner_radius_bottom_right = 2
	slider.add_theme_stylebox_override("slider", track_style)

	# 選択済み部分 — 赤銅
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(UIConstants.COLOR_ACCENT, 0.6)
	fill_style.content_margin_top = 4
	fill_style.content_margin_bottom = 4
	fill_style.corner_radius_top_left = 2
	fill_style.corner_radius_top_right = 2
	fill_style.corner_radius_bottom_left = 2
	fill_style.corner_radius_bottom_right = 2
	slider.add_theme_stylebox_override("grabber_area", fill_style)

	# ホバー時 — 赤銅を強調
	var highlight_style = fill_style.duplicate()
	highlight_style.bg_color = Color(UIConstants.COLOR_ACCENT, 0.85)
	slider.add_theme_stylebox_override("grabber_area_highlight", highlight_style)

# 設定値をUIに反映
func _apply_settings_to_ui():
	if text_speed_slider:
		text_speed_slider.value = _speed_to_step(settings_data.text_speed)
	if master_volume_slider:
		master_volume_slider.value = settings_data.master_volume

	_update_text_speed_label()
	_update_value_labels()
	_update_window_mode_display()

# 値ラベルの更新
func _update_value_labels():
	if master_volume_value:
		master_volume_value.text = str(int(settings_data.master_volume * 100)) + "%"

# ウィンドウモード表示の更新
func _update_window_mode_display():
	# 現在の設定値からインデックスを取得
	var mode_id = settings_data.get("window_mode", "fullscreen")
	for i in range(window_mode_options.size()):
		if window_mode_options[i].id == mode_id:
			current_window_mode_index = i
			break
	
	# ボタンのテキストを更新
	if window_mode_button:
		var option = window_mode_options[current_window_mode_index]
		window_mode_button.text = option.label

# テキスト速度: スライダー値(1-5) → 秒数
func _step_to_speed(step: int) -> float:
	for s in text_speed_steps:
		if s.value == step:
			return s.speed
	return 0.06

# テキスト速度: 秒数 → 最も近いスライダー値(1-5)
func _speed_to_step(speed: float) -> int:
	var best_step = 3
	var best_diff = 999.0
	for s in text_speed_steps:
		var diff = absf(s.speed - speed)
		if diff < best_diff:
			best_diff = diff
			best_step = s.value
	return best_step

# テキスト速度ラベルの更新
func _update_text_speed_label():
	if text_speed_label:
		var step = _speed_to_step(settings_data.text_speed)
		for s in text_speed_steps:
			if s.value == step:
				text_speed_label.text = s.label
				break

# テキスト速度スライダー変更時
func _on_text_speed_changed(value: float):
	settings_data.text_speed = _step_to_speed(int(value))
	_update_text_speed_label()

# 設定変更イベント
func _on_master_volume_changed(value: float):
	settings_data.master_volume = value
	_update_value_labels()
	
	# 音量をリアルタイムで適用
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"),
		linear_to_db(settings_data.master_volume))

# ウィンドウモードボタンクリック時（次の選択肢に切り替え）
func _on_window_mode_clicked():
	current_window_mode_index = (current_window_mode_index + 1) % window_mode_options.size()
	var option = window_mode_options[current_window_mode_index]
	settings_data.window_mode = option.id
	_update_window_mode_display()

# ボタンイベント
func _on_apply_button_pressed():
	print("[SettingsScene] Apply button pressed")
	_save_settings()
	_apply_settings()
	# 設定画面を閉じてトップ画面に戻る
	SceneManager.goto_return_from_settings()

# 設定の保存
func _save_settings():
	var config = ConfigFile.new()
	
	# 既存の設定を読み込んで、古いキーを削除
	var error = config.load(settings_file_path)
	if error == OK and config.has_section_key("settings", "fullscreen"):
		config.erase_section_key("settings", "fullscreen")
	
	# 現在の設定を保存
	for key in settings_data.keys():
		config.set_value("settings", key, settings_data[key])
	
	error = config.save(settings_file_path)
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
		
		# 互換性: 既存のfullscreen設定をwindow_modeに変換
		if config.has_section_key("settings", "fullscreen"):
			var old_fullscreen = config.get_value("settings", "fullscreen")
			if old_fullscreen is bool:
				settings_data.window_mode = "fullscreen" if old_fullscreen else "1280x720"
				# 古い設定を削除（次回保存時に）
		
		# 互換性: 既存のwindowed設定を1280x720に変換
		if settings_data.get("window_mode") == "windowed":
			settings_data.window_mode = "1280x720"
		
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
	
	# ウィンドウモード設定の適用
	var mode = settings_data.get("window_mode", "fullscreen")
	if mode == "fullscreen":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		# 解像度指定（例: "1280x720", "1920x1080"）
		var parts = mode.split("x")
		if parts.size() == 2:
			var width = int(parts[0])
			var height = int(parts[1])
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(Vector2i(width, height))
			# 画面中央に配置
			var screen_size = DisplayServer.screen_get_size()
			var window_pos = (screen_size - Vector2i(width, height)) / 2
			DisplayServer.window_set_position(window_pos)
	
	print("[SettingsScene] Settings applied")

# キーボード入力処理
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				get_viewport().set_input_as_handled()
				SceneManager.goto_return_from_settings()
			KEY_ENTER:
				get_viewport().set_input_as_handled()
				_on_apply_button_pressed()
