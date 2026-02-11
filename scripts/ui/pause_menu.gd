extends Control

## ゲーム中のポーズメニュー
## Escapeキーで開閉。表示中はゲームを一時停止する。

signal resumed
signal title_requested
signal settings_requested

var is_open: bool = false

# UI要素
var background: ColorRect
var menu_container: VBoxContainer
var title_label: Label
var resume_button: Button
var backlog_button: Button
var save_button: Button
var load_button: Button
var trophy_button: Button
var settings_button: Button
var title_button: Button

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	z_index = 100
	_build_ui()

func _build_ui():
	# フルスクリーン設定
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# 半透明ダーク背景
	background = ColorRect.new()
	background.name = "Background"
	background.color = UIConstants.COLOR_BG_DARK
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	# 中央揃え VBoxContainer
	menu_container = VBoxContainer.new()
	menu_container.name = "MenuContainer"
	menu_container.anchor_left = 0.35
	menu_container.anchor_top = 0.2
	menu_container.anchor_right = 0.65
	menu_container.anchor_bottom = 0.8
	menu_container.alignment = BoxContainer.ALIGNMENT_CENTER
	menu_container.add_theme_constant_override("separation", 12)
	add_child(menu_container)

	# タイトル
	title_label = Label.new()
	title_label.text = "メニュー"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_HEADING)
	title_label.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_PRIMARY)
	menu_container.add_child(title_label)

	# セパレータ
	var separator = HSeparator.new()
	separator.add_theme_constant_override("separation", 16)
	menu_container.add_child(separator)

	# ボタン生成
	resume_button = _create_button("ゲームに戻る")
	resume_button.pressed.connect(_on_resume)
	menu_container.add_child(resume_button)

	backlog_button = _create_button("バックログ")
	backlog_button.disabled = true  # 7b で有効化
	menu_container.add_child(backlog_button)

	save_button = _create_button("セーブ")
	save_button.disabled = true  # 7d で有効化
	menu_container.add_child(save_button)

	load_button = _create_button("ロード")
	load_button.disabled = true  # 7d で有効化
	menu_container.add_child(load_button)

	trophy_button = _create_button("トロフィー")
	trophy_button.disabled = true  # 7c で有効化
	menu_container.add_child(trophy_button)

	settings_button = _create_button("設定")
	settings_button.pressed.connect(_on_settings)
	menu_container.add_child(settings_button)

	# セパレータ
	var separator2 = HSeparator.new()
	separator2.add_theme_constant_override("separation", 16)
	menu_container.add_child(separator2)

	title_button = _create_button("タイトルへ戻る")
	title_button.pressed.connect(_on_title)
	menu_container.add_child(title_button)

func _create_button(text: String) -> Button:
	var button = Button.new()
	button.text = text
	UIStyleHelper.style_menu_button(button)
	return button

func open():
	if is_open:
		return
	is_open = true
	visible = true
	get_tree().paused = true
	resume_button.grab_focus()
	print("[PauseMenu] Opened")

func close():
	if not is_open:
		return
	is_open = false
	visible = false
	get_tree().paused = false
	resumed.emit()
	print("[PauseMenu] Closed")

func toggle():
	if is_open:
		close()
	else:
		open()

func _input(event):
	if not is_open:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()

func _on_resume():
	close()

func _on_settings():
	settings_requested.emit()

func _on_title():
	close()
	title_requested.emit()
