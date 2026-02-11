extends Control
class_name BacklogDisplay

## バックログ（テキスト履歴）表示オーバーレイ
## ポーズメニューから開く場合にも対応（PROCESS_MODE_WHEN_PAUSED）

signal closed

var is_open: bool = false

var _background: ColorRect
var _scroll_container: ScrollContainer
var _text_container: VBoxContainer
var _title_label: Label

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	z_index = 110
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()

func _build_ui():
	# 半透明背景
	_background = ColorRect.new()
	_background.color = UIConstants.COLOR_BG_DARK
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_background)

	# タイトル
	_title_label = Label.new()
	_title_label.text = "バックログ"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_HEADING)
	_title_label.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_PRIMARY)
	_title_label.anchor_left = 0.0
	_title_label.anchor_top = 0.0
	_title_label.anchor_right = 1.0
	_title_label.anchor_bottom = 0.0
	_title_label.offset_top = 20
	_title_label.offset_bottom = 60
	add_child(_title_label)

	# スクロールコンテナ
	_scroll_container = ScrollContainer.new()
	_scroll_container.anchor_left = 0.1
	_scroll_container.anchor_top = 0.0
	_scroll_container.anchor_right = 0.9
	_scroll_container.anchor_bottom = 1.0
	_scroll_container.offset_top = 70
	_scroll_container.offset_bottom = -40
	_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll_container)

	# テキストコンテナ
	_text_container = VBoxContainer.new()
	_text_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text_container.add_theme_constant_override("separation", 8)
	_scroll_container.add_child(_text_container)

## バックログを開く
func open(history: Array) -> void:
	if is_open:
		return
	is_open = true
	_populate(history)
	visible = true

	# レイアウト完了後に最下部にスクロール
	await get_tree().process_frame
	_scroll_container.scroll_vertical = _scroll_container.get_v_scroll_bar().max_value

## バックログを閉じる
func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	_clear_entries()
	closed.emit()

## 履歴エントリを表示
func _populate(history: Array) -> void:
	_clear_entries()

	if history.is_empty():
		var empty_label = Label.new()
		empty_label.text = "（ログはまだありません）"
		empty_label.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_BODY)
		empty_label.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_SECONDARY)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_text_container.add_child(empty_label)
		return

	for entry in history:
		var rtl = RichTextLabel.new()
		rtl.text = entry.get("text", "")
		rtl.fit_content = true
		rtl.scroll_active = false
		rtl.bbcode_enabled = false
		rtl.add_theme_font_size_override("normal_font_size", UIConstants.FONT_SIZE_BODY)
		rtl.add_theme_color_override("default_color", UIConstants.COLOR_TEXT_PRIMARY)
		rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_text_container.add_child(rtl)

		# エントリ間の区切り線
		var sep = HSeparator.new()
		sep.add_theme_constant_override("separation", 4)
		sep.modulate = Color(1, 1, 1, 0.15)
		_text_container.add_child(sep)

## エントリをクリア
func _clear_entries() -> void:
	for child in _text_container.get_children():
		child.queue_free()

## 入力処理
func _input(event):
	if not is_open:
		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()
