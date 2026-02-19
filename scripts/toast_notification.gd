# toast_notification.gd
# トースト通知システム（和風テーマ）

extends Control

# シグナル定義
signal toast_completed

# UI要素
var toast_panel: Panel
var title_label: Label
var desc_label: Label
var accent_bar: ColorRect

# アニメーション用
var tween: Tween
var is_showing: bool = false

# 設定
var show_duration: float = 3.0
var fade_duration: float = 0.4
var panel_width: float = 380.0
var panel_height: float = 80.0

func _ready():
	_setup_toast_ui()
	visible = false

# トーストUIのセットアップ
func _setup_toast_ui():
	# メインパネル
	toast_panel = Panel.new()
	toast_panel.name = "toast_panel"

	var style_box = StyleBoxFlat.new()
	style_box.bg_color = UIConstants.COLOR_BG_PANEL
	style_box.corner_radius_top_left = UIConstants.CORNER_RADIUS
	style_box.corner_radius_top_right = UIConstants.CORNER_RADIUS
	style_box.corner_radius_bottom_left = UIConstants.CORNER_RADIUS
	style_box.corner_radius_bottom_right = UIConstants.CORNER_RADIUS
	# 深紅の外枠（上下左右）
	style_box.border_color = UIConstants.COLOR_ENTRY_BORDER
	style_box.border_width_top = 1
	style_box.border_width_bottom = 1
	style_box.border_width_left = 1
	style_box.border_width_right = 1
	toast_panel.add_theme_stylebox_override("panel", style_box)

	toast_panel.size = Vector2(panel_width, panel_height)
	add_child(toast_panel)

	# 左側の深紅アクセントバー
	accent_bar = ColorRect.new()
	accent_bar.name = "accent_bar"
	accent_bar.color = UIConstants.COLOR_ACCENT
	accent_bar.position = Vector2(0, 0)
	accent_bar.size = Vector2(4, panel_height)
	toast_panel.add_child(accent_bar)

	# タイトルラベル（トロフィー名）
	title_label = Label.new()
	title_label.name = "title_label"
	title_label.position = Vector2(16, 12)
	title_label.size = Vector2(panel_width - 32, 28)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_label.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_BUTTON_NORMAL)
	title_label.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_PRIMARY)
	toast_panel.add_child(title_label)

	# 説明ラベル（トロフィー説明）
	desc_label = Label.new()
	desc_label.name = "desc_label"
	desc_label.position = Vector2(16, 42)
	desc_label.size = Vector2(panel_width - 32, 26)
	desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	desc_label.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_CAPTION)
	desc_label.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_SECONDARY)
	toast_panel.add_child(desc_label)

	# 最前面に表示
	z_index = 1000
	mouse_filter = Control.MOUSE_FILTER_IGNORE

# トーストを表示
func show_toast(text: String, _icon_path: String = ""):
	if is_showing:
		await toast_completed
		await get_tree().create_timer(0.5).timeout

	is_showing = true

	# テキストを解析（"トロフィー名\n説明" の形式を想定）
	var lines = text.split("\n")
	if lines.size() >= 2:
		title_label.text = lines[0]
		desc_label.text = lines[1]
		desc_label.visible = true
	else:
		title_label.text = text
		desc_label.visible = false

	# 初期位置（画面右外）
	var viewport_size = get_viewport_rect().size
	toast_panel.position = Vector2(viewport_size.x, 20)
	modulate.a = 0.0
	visible = true

	# スライドインアニメーション
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 1.0, fade_duration)
	tween.tween_property(toast_panel, "position:x", viewport_size.x - panel_width - 20, fade_duration)

	await tween.finished

	# 表示時間待機
	await get_tree().create_timer(show_duration).timeout

	# スライドアウトアニメーション
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	tween.tween_property(toast_panel, "position:x", viewport_size.x, fade_duration)

	await tween.finished

	visible = false
	is_showing = false
	toast_completed.emit()
