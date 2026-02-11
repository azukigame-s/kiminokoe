extends Control
class_name BottomMenu

## ゲーム画面下部メニュー
## ログ / スキップ / メニュー の3ボタンを常設表示する

signal log_pressed
signal skip_pressed
signal menu_pressed

var _log_button: Button
var _skip_button: Button
var _menu_button: Button
var _container: HBoxContainer
var _is_skip_active: bool = false

func _ready():
	# 画面最下部に配置
	anchor_left = 0.0
	anchor_top = 1.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_top = -40
	offset_bottom = 0
	z_index = 10
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_build_ui()

func _build_ui():
	_container = HBoxContainer.new()
	_container.name = "ButtonContainer"
	_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_container.add_theme_constant_override("separation", 32)
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_container)

	_log_button = _create_button("ログ")
	_log_button.pressed.connect(func(): log_pressed.emit())
	_container.add_child(_log_button)

	_skip_button = _create_button("スキップ")
	_skip_button.pressed.connect(func(): skip_pressed.emit())
	_container.add_child(_skip_button)

	_menu_button = _create_button("メニュー")
	_menu_button.pressed.connect(func(): menu_pressed.emit())
	_container.add_child(_menu_button)

func _create_button(text: String) -> Button:
	var button = Button.new()
	button.text = text
	button.flat = true
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.focus_mode = Control.FOCUS_NONE
	UIStyleHelper.style_bottom_menu_button(button)
	return button

## スキップボタンのアクティブ状態を更新
func set_skip_active(active: bool) -> void:
	_is_skip_active = active
	if active:
		_skip_button.add_theme_color_override("font_color", UIConstants.COLOR_SKIP_ACTIVE)
	else:
		_skip_button.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_SECONDARY)
