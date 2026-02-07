extends Control
class_name ChoiceDisplay

## 選択肢表示コンポーネント
## 弟切草風のテキスト選択肢UI

# シグナル
signal choice_selected(choice_data: Dictionary)

# スタイリング
var text_color = Color(1, 1, 1, 1)
var hover_color = Color(1, 0.8, 0, 1)  # 弟切草風の黄色いハイライト
var text_size = 22

# 内部状態
var _choice_container: Control
var _choice_background: ColorRect
var _choice_labels: Array = []
var _current_choices: Array = []
var _selected_index: int = 0
var _is_active: bool = false

func _ready():
	# フルスクリーン設定
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

	_setup_container()
	print("[ChoiceDisplay] 準備完了")

## コンテナの初期化
func _setup_container():
	_choice_container = Control.new()
	_choice_container.name = "ChoiceContainer"
	_choice_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_choice_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_choice_container)

	# 半透明背景
	_choice_background = ColorRect.new()
	_choice_background.name = "ChoiceBG"
	_choice_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_choice_background.color = Color(0, 0, 0, 0)
	_choice_container.add_child(_choice_background)

## 選択肢を表示
func show_choices(choices: Array) -> void:
	_clear_choices()
	_current_choices = choices
	_is_active = true
	visible = true

	var prefixes = ["Ａ", "Ｂ", "Ｃ", "Ｄ", "Ｅ"]
	var total = mini(choices.size(), prefixes.size())
	var viewport_size = get_viewport_rect().size

	# タイトル
	var title = Label.new()
	title.name = "ChoiceTitle"
	title.text = "どうする？"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.position.x = viewport_size.x * 0.1
	title.position.y = viewport_size.y * 0.1
	title.size.x = viewport_size.x * 0.8
	title.size.y = 40
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color.WHITE)
	_choice_container.add_child(title)

	# 選択肢を配置
	var spacing = 50
	var start_y = viewport_size.y * 0.1 + 80

	for i in range(total):
		var choice_data = choices[i]
		var choice_text = choice_data.get("text", "選択肢 " + str(i + 1))

		# 選択肢パネル
		var panel = Control.new()
		panel.position.x = viewport_size.x * 0.1
		panel.position.y = start_y + (spacing * i)
		panel.size.x = viewport_size.x * 0.8
		panel.size.y = 40
		_choice_container.add_child(panel)

		# 透明ボタン（クリック検出用）
		var button = Button.new()
		button.name = "ChoiceBtn_%d" % i
		button.text = ""
		button.flat = true
		button.focus_mode = Control.FOCUS_NONE
		button.position = Vector2.ZERO
		button.size = panel.size
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		var empty_style = StyleBoxEmpty.new()
		button.add_theme_stylebox_override("normal", empty_style)
		button.add_theme_stylebox_override("hover", empty_style)
		button.add_theme_stylebox_override("pressed", empty_style)

		button.pressed.connect(_on_button_pressed.bind(i))
		button.mouse_entered.connect(_on_button_hover.bind(i))
		panel.add_child(button)

		# ラベル（表示用）
		var label = Label.new()
		label.name = "ChoiceLabel_%d" % i
		label.text = prefixes[i] + "　" + choice_text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.position = Vector2.ZERO
		label.size = panel.size
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_size_override("font_size", text_size)
		label.add_theme_color_override("font_color", text_color)
		panel.add_child(label)

		_choice_labels.append(label)

	_selected_index = 0
	_update_highlight()
	print("[ChoiceDisplay] %d 個の選択肢を表示" % total)

## 選択肢をクリア
func _clear_choices():
	for child in _choice_container.get_children():
		if child != _choice_background:
			child.queue_free()
	_choice_labels.clear()
	_current_choices.clear()
	_selected_index = 0

## ボタンクリック時
func _on_button_pressed(index: int):
	_select(index)

## ボタンホバー時
func _on_button_hover(index: int):
	if _selected_index != index:
		_selected_index = index
		_update_highlight()

## 選択を確定
func _select(index: int):
	if index < 0 or index >= _current_choices.size():
		return

	var selected = _current_choices[index]
	print("[ChoiceDisplay] 選択: %s" % selected.get("text", ""))

	_is_active = false
	visible = false
	_clear_choices()

	choice_selected.emit(selected)

## ハイライト更新
func _update_highlight():
	for i in range(_choice_labels.size()):
		var color = hover_color if i == _selected_index else text_color
		_choice_labels[i].add_theme_color_override("font_color", color)

## キーボード入力処理
func _input(event):
	if not _is_active or _choice_labels.is_empty():
		return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP:
				if _selected_index > 0:
					_selected_index -= 1
					_update_highlight()
			KEY_DOWN:
				if _selected_index < _choice_labels.size() - 1:
					_selected_index += 1
					_update_highlight()
			KEY_ENTER, KEY_SPACE:
				_select(_selected_index)
			KEY_A:
				if _choice_labels.size() >= 1:
					_select(0)
			KEY_B:
				if _choice_labels.size() >= 2:
					_select(1)
			KEY_C:
				if _choice_labels.size() >= 3:
					_select(2)
			KEY_D:
				if _choice_labels.size() >= 4:
					_select(3)
			KEY_E:
				if _choice_labels.size() >= 5:
					_select(4)
			_:
				return

		get_viewport().set_input_as_handled()
