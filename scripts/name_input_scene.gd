extends Control

## 主人公名入力画面
## はじめから選択時に表示。名前を入力してゲームを開始する。
## トロフィー画面と統一した和風デザイン。

var _name_input: LineEdit
var _start_button: Button
var _default_name: String = "コウ"

func _ready():
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	if _name_input:
		_name_input.grab_focus()

func _build_ui():
	# 背景（墨色 95%）
	var bg = ColorRect.new()
	bg.color = Color(UIConstants.COLOR_BASE_DARK, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# ── タイトルエリア ──
	_build_title_area()

	# 中央コンテナ
	var center = VBoxContainer.new()
	center.anchor_left = 0.25
	center.anchor_top = 0.3
	center.anchor_right = 0.75
	center.anchor_bottom = 0.7
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 20)
	add_child(center)

	# 説明ラベル
	var instruction = Label.new()
	instruction.text = "主人公の名前を入力してください"
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_BODY)
	instruction.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_PRIMARY)
	center.add_child(instruction)

	# 名前入力欄
	_name_input = LineEdit.new()
	_name_input.text = _default_name
	_name_input.placeholder_text = _default_name
	_name_input.max_length = 8
	_name_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_input.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_BODY)
	_name_input.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_PRIMARY)
	_name_input.add_theme_color_override("font_placeholder_color", UIConstants.COLOR_TEXT_DISABLED)
	_name_input.add_theme_color_override("caret_color", UIConstants.COLOR_TEXT_ACCENT)
	_name_input.select_all_on_focus = true

	var input_style = StyleBoxFlat.new()
	input_style.bg_color = UIConstants.COLOR_ENTRY_BG
	input_style.border_width_bottom = 2
	input_style.border_color = UIConstants.COLOR_BORDER_NORMAL
	input_style.content_margin_left = 12
	input_style.content_margin_right = 12
	input_style.content_margin_top = 8
	input_style.content_margin_bottom = 8
	_name_input.add_theme_stylebox_override("normal", input_style)

	var input_focus_style = input_style.duplicate()
	input_focus_style.border_color = UIConstants.COLOR_BORDER_HOVER
	_name_input.add_theme_stylebox_override("focus", input_focus_style)

	_name_input.text_submitted.connect(_on_text_submitted)
	center.add_child(_name_input)

	# ゲームを始めるボタン
	_start_button = Button.new()
	_start_button.text = "ゲームを始める"
	UIStyleHelper.style_title_button(_start_button)
	_start_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_start_button.pressed.connect(_on_start_pressed)
	center.add_child(_start_button)

	# もどるボタン（設定画面・一息メニューと同じスタイル）
	var back_button = Button.new()
	back_button.text = "もどる"
	back_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyleHelper.style_back_button(back_button)
	back_button.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	back_button.offset_top = -35
	back_button.offset_bottom = -12
	back_button.pressed.connect(func(): SceneManager.goto_title())
	add_child(back_button)

## タイトルエリア（装飾線 ── 名前の入力 ── の形）
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
	title.text = "名前の入力"
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

func _on_text_submitted(_text: String):
	_on_start_pressed()

func _on_start_pressed():
	var name_text = _name_input.text.strip_edges()
	if name_text.is_empty():
		name_text = _default_name
	SceneManager.protagonist_name = name_text
	SceneManager.game_start_mode = "new_game"
	SceneManager.clear_save_data()
	SceneManager.goto_game()

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			SceneManager.goto_title()
