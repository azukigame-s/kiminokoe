class_name UIStyleHelper

## 再利用可能なスタイリングユーティリティ
## UIConstants の定数を使ってコントロールにスタイルを適用する

# === StyleBox 生成 ===

static func create_panel_style(
	bg_color: Color = UIConstants.COLOR_BG_PANEL,
	corner_radius: int = UIConstants.CORNER_RADIUS,
	border_width: int = 0,
	border_color: Color = Color.TRANSPARENT
) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	if border_width > 0:
		style.border_width_left = border_width
		style.border_width_right = border_width
		style.border_width_top = border_width
		style.border_width_bottom = border_width
		style.border_color = border_color
	return style

# === アウトライン（縁取り） ===

## Label にアウトラインを適用
static func apply_outline_to_label(label: Label) -> void:
	if not label:
		return
	label.add_theme_constant_override("outline_size", UIConstants.OUTLINE_SIZE)
	label.add_theme_color_override("font_outline_color", UIConstants.COLOR_OUTLINE)

## RichTextLabel にアウトラインを適用
static func apply_outline_to_rich_text(rtl: RichTextLabel) -> void:
	if not rtl:
		return
	rtl.add_theme_constant_override("outline_size", UIConstants.OUTLINE_SIZE)
	rtl.add_theme_color_override("font_outline_color", UIConstants.COLOR_OUTLINE)

## Button にアウトラインを適用
static func apply_outline_to_button(button: Button) -> void:
	if not button:
		return
	button.add_theme_constant_override("outline_size", UIConstants.OUTLINE_SIZE)
	button.add_theme_color_override("font_outline_color", UIConstants.COLOR_OUTLINE)

# === ボタンスタイル ===

## 設定/メニュー用ボタン（ボーダー付き、白文字）
static func style_menu_button(button: Button) -> void:
	if not button:
		return

	button.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_BUTTON_NORMAL)
	button.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_PRIMARY)
	button.add_theme_color_override("font_hover_color", UIConstants.COLOR_TEXT_ACCENT)
	button.custom_minimum_size = UIConstants.BUTTON_MIN_SIZE_NORMAL

	var normal_style = create_panel_style(
		UIConstants.COLOR_BG_BUTTON,
		UIConstants.CORNER_RADIUS,
		UIConstants.BORDER_WIDTH,
		UIConstants.COLOR_BORDER_NORMAL
	)
	var hover_style = create_panel_style(
		UIConstants.COLOR_BG_BUTTON_HOVER,
		UIConstants.CORNER_RADIUS,
		UIConstants.BORDER_WIDTH,
		UIConstants.COLOR_BORDER_HOVER
	)

	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)
	button.add_theme_stylebox_override("focus", normal_style)

## ゲーム画面下部メニュー用ボタン（透明背景、グレー文字、ホバーで薄紅）
static func style_bottom_menu_button(button: Button) -> void:
	if not button:
		return

	button.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_CAPTION)
	button.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_SECONDARY)
	button.add_theme_color_override("font_hover_color", UIConstants.COLOR_TEXT_ACCENT)
	button.add_theme_color_override("font_pressed_color", UIConstants.COLOR_TEXT_ACCENT)
	button.add_theme_color_override("font_focus_color", UIConstants.COLOR_TEXT_SECONDARY)
	apply_outline_to_button(button)

	var transparent = StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", transparent)
	button.add_theme_stylebox_override("hover", transparent)
	button.add_theme_stylebox_override("pressed", transparent)
	button.add_theme_stylebox_override("focus", transparent)

## 「もどる」ボタン（画面下部に配置、控えめなテキストボタン）
static func style_back_button(button: Button) -> void:
	if not button:
		return

	button.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_CAPTION)
	button.add_theme_color_override("font_color", Color(UIConstants.COLOR_ACCENT, 0.5))
	button.add_theme_color_override("font_hover_color", UIConstants.COLOR_ACCENT)
	button.add_theme_color_override("font_pressed_color", UIConstants.COLOR_ACCENT)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.focus_mode = Control.FOCUS_NONE  # マウス専用、キーボードフォーカスは不要（Escで戻れる）

	var transparent = StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", transparent)
	button.add_theme_stylebox_override("hover", transparent)
	button.add_theme_stylebox_override("pressed", transparent)

## タイトル用ボタン（透明背景、ダーク文字、ホバーで白）
static func style_title_button(button: Button) -> void:
	if not button:
		return

	button.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_BUTTON_LARGE)
	button.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_TITLE_DARK)
	button.add_theme_color_override("font_hover_color", UIConstants.COLOR_TEXT_PRIMARY)
	button.add_theme_color_override("font_pressed_color", UIConstants.COLOR_TEXT_PRIMARY)
	button.add_theme_color_override("font_focus_color", UIConstants.COLOR_TEXT_TITLE_DARK)
	button.add_theme_color_override("font_disabled_color", UIConstants.COLOR_TEXT_DISABLED)
	button.custom_minimum_size = UIConstants.BUTTON_MIN_SIZE_LARGE
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.theme = null

	var transparent_style = create_panel_style(Color.TRANSPARENT, UIConstants.CORNER_RADIUS)
	button.add_theme_stylebox_override("normal", transparent_style)
	button.add_theme_stylebox_override("hover", transparent_style)
	button.add_theme_stylebox_override("pressed", transparent_style)
	button.add_theme_stylebox_override("focus", transparent_style)
