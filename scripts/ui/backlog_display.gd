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

# デザイン定数
const ENTRY_BG_COLOR = Color(0.05, 0.11, 0.07, 0.6)       # エントリ背景（漆黒緑系、微透過）
const ENTRY_BORDER_COLOR = Color(0.725, 0.165, 0.31, 0.4)  # 左ボーダー（深紅、控えめ）
const SEPARATOR_COLOR = Color(0.725, 0.165, 0.31, 0.15)    # 区切り線（深紅、極薄）
const TITLE_RULE_COLOR = Color(0.725, 0.165, 0.31, 0.5)    # タイトル装飾線（深紅）

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
	# 不透明背景
	_background = ColorRect.new()
	_background.color = Color(UIConstants.COLOR_BASE_DARK, 0.85)
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_background)

	# ── タイトルエリア ──
	_build_title_area()

	# スクロールコンテナ
	_scroll_container = ScrollContainer.new()
	_scroll_container.anchor_left = 0.08
	_scroll_container.anchor_top = 0.0
	_scroll_container.anchor_right = 0.92
	_scroll_container.anchor_bottom = 1.0
	_scroll_container.offset_top = 80
	_scroll_container.offset_bottom = -50
	_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll_container)

	# テキストコンテナ
	_text_container = VBoxContainer.new()
	_text_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text_container.add_theme_constant_override("separation", 4)
	_scroll_container.add_child(_text_container)

	# ── 閉じるヒント ──
	var hint = Label.new()
	hint.text = "Esc / L"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_CAPTION)
	hint.add_theme_color_override("font_color", Color(UIConstants.COLOR_ACCENT, 0.5))
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -35
	hint.offset_bottom = -12
	add_child(hint)

## タイトルエリア（装飾線 ── バックログ ── の形）
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
	var left_rule = _create_rule()
	title_container.add_child(left_rule)

	# タイトルテキスト
	var title = Label.new()
	title.text = "足跡"
	title.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_HEADING)
	title.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_PRIMARY)
	title_container.add_child(title)

	# 右装飾線
	var right_rule = _create_rule()
	title_container.add_child(right_rule)

## 装飾線（horizontal rule）を作成
func _create_rule() -> Control:
	var rule_wrapper = Control.new()
	rule_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rule_wrapper.custom_minimum_size.y = 1

	var rule = ColorRect.new()
	rule.color = TITLE_RULE_COLOR
	rule.set_anchors_preset(Control.PRESET_CENTER)
	rule.anchor_left = 0.0
	rule.anchor_right = 1.0
	rule.offset_top = -0.5
	rule.offset_bottom = 0.5
	rule.offset_left = 0
	rule.offset_right = 0
	rule_wrapper.add_child(rule)

	return rule_wrapper

## バックログを開く
func open(history: Array) -> void:
	if is_open:
		return
	is_open = true
	_populate(history)
	visible = true

	# レイアウト完了後に最下部にスクロール
	await get_tree().process_frame
	await get_tree().process_frame
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
		_text_container.add_child(_create_entry(text))

## エントリ1件分のUIを作成（左ボーダー + テキスト）
func _create_entry(text: String) -> PanelContainer:
	# 外枠パネル（左ボーダー付き背景）
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style = StyleBoxFlat.new()
	style.bg_color = ENTRY_BG_COLOR
	style.border_width_left = 3
	style.border_color = ENTRY_BORDER_COLOR
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_right = 2
	style.content_margin_left = 16
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)

	# テキスト
	var label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_PRIMARY)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(label)

	return panel

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