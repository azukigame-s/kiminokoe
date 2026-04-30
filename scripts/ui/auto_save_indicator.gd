# auto_save_indicator.gd
# オートセーブインジケーター
# new_page タイミングで右上に「自動保存……」を短時間表示する

extends Control

var label: Label
var tween: Tween

const FADE_IN_DURATION  := 0.3
const HOLD_DURATION     := 1.5
const FADE_OUT_DURATION := 0.5

func _ready():
	_setup_ui()
	modulate.a = 0.0
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 500

func _setup_ui():
	# 右上に固定配置
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	offset_left   = -180
	offset_top    = 12
	offset_right  = -16
	offset_bottom = 36

	label = Label.new()
	label.text = "栞を挟む……"
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_CAPTION)
	label.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_SECONDARY)
	label.add_theme_constant_override("outline_size", UIConstants.OUTLINE_SIZE)
	label.add_theme_color_override("font_outline_color", UIConstants.COLOR_OUTLINE)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)

## ページ区切りセーブ時に呼び出す
func show_indicator():
	if tween:
		tween.kill()

	modulate.a = 0.0
	visible = true

	tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, FADE_IN_DURATION)
	tween.tween_interval(HOLD_DURATION)
	tween.tween_property(self, "modulate:a", 0.0, FADE_OUT_DURATION)
	tween.tween_callback(func(): visible = false)
