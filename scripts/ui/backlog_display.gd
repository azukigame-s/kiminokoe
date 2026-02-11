extends Control
class_name BacklogDisplay

## バックログ（テキスト履歴）表示画面
## CanvasLayer 内に配置され、ゲーム画面の上に別画面として描画される
## process_mode は親の CanvasLayer から継承（WHEN_PAUSED）

signal closed

var is_open: bool = false

var _background: ColorRect
var _scroll_container: ScrollContainer
var _text_container: VBoxContainer
var _title_label: Label
var _close_hint: Label

func _ready():
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

	# CanvasLayer 内では anchors がビューポートサイズを参照する
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# 明示的にオフセットもリセット（確実にフルスクリーン化）
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0

	_build_ui()

func _build_ui():
	# 不透明背景（別画面風）
	_background = ColorRect.new()
	_background.color = Color(UIConstants.COLOR_BASE_DARK, 1.0)  # 完全不透明
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_background)

	# タイトル
	_title_label = Label.new()
	_title_label.text = "バックログ"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_HEADING)
	_title_label.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_PRIMARY)
	_title_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
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
	_scroll_container.offset_bottom = -60
	_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll_container)

	# テキストコンテナ
	_text_container = VBoxContainer.new()
	_text_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text_container.add_theme_constant_override("separation", 12)
	_scroll_container.add_child(_text_container)

	# 閉じるヒント
	_close_hint = Label.new()
	_close_hint.text = "Escで閉じる"
	_close_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_close_hint.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_CAPTION)
	_close_hint.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_SECONDARY)
	_close_hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_close_hint.offset_top = -40
	_close_hint.offset_bottom = -10
	add_child(_close_hint)

## バックログを開く
func open(history: Array) -> void:
	if is_open:
		return
	is_open = true
	_populate(history)
	visible = true

	# レイアウト完了後に最下部にスクロール
	await get_tree().process_frame
	await get_tree().process_frame  # 2フレーム待ってレイアウト確定
	var scrollbar = _scroll_container.get_v_scroll_bar()
	if scrollbar:
		_scroll_container.scroll_vertical = int(scrollbar.max_value)

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
		var text = entry.get("text", "") if entry is Dictionary else str(entry)
		if text.is_empty():
			continue

		var label = Label.new()
		label.text = text
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_BODY)
		label.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_PRIMARY)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_text_container.add_child(label)

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

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_L:
			close()
			get_viewport().set_input_as_handled()