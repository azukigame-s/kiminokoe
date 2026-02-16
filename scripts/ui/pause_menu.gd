extends Control

## ゲーム中のポーズメニュー
## Escapeキーで開閉。表示中はゲームを一時停止する。
## 足跡（バックログ）と統一した和風デザイン

signal resumed
signal title_requested
signal settings_requested
signal backlog_requested

var is_open: bool = false

# UI要素
var _background: ColorRect
var _menu_container: VBoxContainer
var resume_button: Button
var backlog_button: Button
var settings_button: Button
var title_button: Button

# デザイン定数（UIConstants から参照）

func _ready():
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

	# CanvasLayer 内では anchors がビューポートサイズを参照する
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0

	_build_ui()

func _build_ui():
	# 半透明背景（足跡と同じ不透明度）
	_background = ColorRect.new()
	_background.color = Color(UIConstants.COLOR_BASE_DARK, 0.95)
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_background)

	# ── タイトルエリア ──
	_build_title_area()

	# メニューコンテナ（中央寄せ）
	_menu_container = VBoxContainer.new()
	_menu_container.name = "MenuContainer"
	_menu_container.anchor_left = 0.3
	_menu_container.anchor_top = 0.0
	_menu_container.anchor_right = 0.7
	_menu_container.anchor_bottom = 1.0
	_menu_container.offset_top = 80
	_menu_container.offset_bottom = -50
	_menu_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_menu_container.add_theme_constant_override("separation", 6)
	add_child(_menu_container)

	# ボタン生成
	resume_button = _create_menu_button("ゲームに戻る")
	resume_button.pressed.connect(_on_resume)
	_menu_container.add_child(resume_button)

	backlog_button = _create_menu_button("足跡")
	backlog_button.pressed.connect(_on_backlog)
	_menu_container.add_child(backlog_button)

	# 区切り線
	_menu_container.add_child(_create_separator())

	settings_button = _create_menu_button("設定")
	settings_button.pressed.connect(_on_settings)
	_menu_container.add_child(settings_button)

	# 区切り線
	_menu_container.add_child(_create_separator())

	title_button = _create_menu_button("タイトルへ戻る")
	title_button.pressed.connect(_on_title)
	_menu_container.add_child(title_button)

	# ── 閉じるヒント ──
	var hint = Label.new()
	hint.text = "Esc"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_CAPTION)
	hint.add_theme_color_override("font_color", Color(UIConstants.COLOR_ACCENT, 0.5))
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -35
	hint.offset_bottom = -12
	add_child(hint)

## タイトルエリア（装飾線 ── 一息 ── の形）
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

	# 左装飾線
	title_container.add_child(_create_rule())

	# タイトルテキスト
	var title = Label.new()
	title.text = "一息"
	title.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_HEADING)
	title.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_PRIMARY)
	title_container.add_child(title)

	# 右装飾線
	title_container.add_child(_create_rule())

## 装飾線（horizontal rule）を作成
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

## メニューボタンを作成（フラットスタイル、左ボーダーアクセント）
func _create_menu_button(text: String) -> Button:
	var button = Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.custom_minimum_size = Vector2(200, 44)

	button.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_BODY)
	button.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_PRIMARY)
	button.add_theme_color_override("font_hover_color", UIConstants.COLOR_TEXT_ACCENT)
	button.add_theme_color_override("font_pressed_color", UIConstants.COLOR_ACCENT)
	button.add_theme_color_override("font_focus_color", UIConstants.COLOR_TEXT_PRIMARY)
	button.add_theme_color_override("font_disabled_color", UIConstants.COLOR_TEXT_DISABLED)

	# ノーマル: 透明背景、左ボーダーなし
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color.TRANSPARENT
	normal_style.border_width_left = 3
	normal_style.border_color = Color.TRANSPARENT
	normal_style.content_margin_left = 16
	normal_style.content_margin_right = 16
	normal_style.content_margin_top = 8
	normal_style.content_margin_bottom = 8

	# ホバー: 微かな背景 + 深紅の左ボーダー
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = UIConstants.COLOR_BUTTON_HOVER_TINT
	hover_style.border_width_left = 3
	hover_style.border_color = UIConstants.COLOR_ENTRY_BORDER
	hover_style.corner_radius_top_right = 2
	hover_style.corner_radius_bottom_right = 2
	hover_style.content_margin_left = 16
	hover_style.content_margin_right = 16
	hover_style.content_margin_top = 8
	hover_style.content_margin_bottom = 8

	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)
	button.add_theme_stylebox_override("focus", normal_style)
	button.add_theme_stylebox_override("disabled", normal_style)

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

func _on_backlog():
	backlog_requested.emit()

func _on_settings():
	settings_requested.emit()

func _on_title():
	close()
	title_requested.emit()
