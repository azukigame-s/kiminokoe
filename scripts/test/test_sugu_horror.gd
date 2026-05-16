extends Node

## sugu_horror_display.gd の単体テスト用スクリプト
## Godot エディタで test_sugu_horror.tscn を F6 実行するだけでテストできる

const SuguHorrorDisplayScript = preload("res://scripts/ui/sugu_horror_display.gd")
const TextDisplayScript        = preload("res://scripts/ui/text_display.gd")


func _ready() -> void:
	# ゲーム本体と同じ構成で text_display を組み立てる
	var text_display = _build_text_display()

	var horror: Node = SuguHorrorDisplayScript.new()
	add_child(horror)
	horror.text_display = text_display
	horror.horror_completed.connect(_on_horror_completed)
	horror.start()


func _build_text_display() -> Control:
	# 半透明パネル（ゲームシーンと同じ）
	var panel := ColorRect.new()
	panel.color = UIConstants.COLOR_BG_OVERLAY
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	# TextDisplay 本体
	var td := Control.new()
	td.set_script(TextDisplayScript)
	td.name = "TextDisplay"
	td.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(td)

	# RichTextLabel（ゲームシーンと同じ設定）
	var lbl := RichTextLabel.new()
	lbl.name = "TextLabel"
	lbl.anchor_left   = UIConstants.MARGIN_TEXT
	lbl.anchor_top    = UIConstants.MARGIN_TEXT
	lbl.anchor_right  = 1.0 - UIConstants.MARGIN_TEXT
	lbl.anchor_bottom = 1.0 - UIConstants.MARGIN_TEXT
	lbl.add_theme_font_size_override("normal_font_size", UIConstants.FONT_SIZE_BODY)
	lbl.add_theme_color_override("default_color", UIConstants.COLOR_TEXT_PRIMARY)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIStyleHelper.apply_outline_to_rich_text(lbl)

	var theme_path := "res://themes/novel_theme.tres"
	if ResourceLoader.exists(theme_path):
		lbl.theme = load(theme_path)

	td.add_child(lbl)
	td.text_label = lbl

	return td


func _on_horror_completed() -> void:
	print("[TEST] SuguHorrorDisplay 完了")
