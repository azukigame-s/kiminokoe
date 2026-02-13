extends Control

## トロフィー閲覧画面
## タイトル画面からシーン遷移でアクセス。Escでタイトルに戻る。
## メニュー / 足跡と統一した和風デザイン。

func _ready():
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()

func _build_ui():
	# 背景（墨色 95%）
	var bg = ColorRect.new()
	bg.color = Color(UIConstants.COLOR_BASE_DARK, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# ── タイトルエリア ──
	_build_title_area()

	# TrophyManager からデータ取得
	var trophy_manager = _get_trophy_manager()
	if not trophy_manager:
		var error_label = Label.new()
		error_label.text = "トロフィーデータを取得できません"
		error_label.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_DISABLED)
		error_label.set_anchors_preset(Control.PRESET_CENTER)
		add_child(error_label)
		return

	var data = trophy_manager.get_trophy_display_data()

	# スクロールコンテナ（進行度の上まで）
	var scroll = ScrollContainer.new()
	scroll.name = "ScrollContainer"
	scroll.anchor_left = 0.12
	scroll.anchor_top = 0.0
	scroll.anchor_right = 0.88
	scroll.anchor_bottom = 1.0
	scroll.offset_top = 70
	scroll.offset_bottom = -80
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var content = VBoxContainer.new()
	content.name = "Content"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 4)
	scroll.add_child(content)

	# 通常トロフィー
	for trophy in data.normal:
		content.add_child(_create_trophy_entry(trophy))

	# 区切り線
	content.add_child(_create_separator())

	# シークレットトロフィー
	for trophy in data.secret:
		content.add_child(_create_trophy_entry(trophy))

	# 進行度（スクロール外、常に画面下部に固定表示）
	var unlocked = data.unlocked_count
	var total = data.total_count
	var percent = int(float(unlocked) / float(total) * 100) if total > 0 else 0
	var progress = Label.new()
	progress.text = "進行度: %d/%d (%d%%)" % [unlocked, total, percent]
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_BUTTON_NORMAL)
	progress.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_SECONDARY)
	progress.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	progress.offset_top = -68
	progress.offset_bottom = -48
	add_child(progress)

	# 閉じるヒント
	var hint = Label.new()
	hint.text = "Esc"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_CAPTION)
	hint.add_theme_color_override("font_color", Color(UIConstants.COLOR_ACCENT, 0.5))
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -35
	hint.offset_bottom = -12
	add_child(hint)

## タイトルエリア（装飾線 ── トロフィー ── の形）
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
	title.text = "トロフィー"
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

## 区切り線を作成
func _create_separator() -> ColorRect:
	var sep = ColorRect.new()
	sep.color = UIConstants.COLOR_SEPARATOR
	sep.custom_minimum_size = Vector2(0, 1)
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return sep

## トロフィーエントリを作成
func _create_trophy_entry(trophy: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style = StyleBoxFlat.new()
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_right = 2

	if trophy.unlocked:
		style.bg_color = UIConstants.COLOR_ENTRY_BG
		style.border_width_left = 3
		style.border_color = UIConstants.COLOR_ENTRY_BORDER
	else:
		style.bg_color = Color(UIConstants.COLOR_BASE_DARK, 0.3)
		style.border_width_left = 3
		style.border_color = Color.TRANSPARENT

	panel.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)

	var font_size = UIConstants.FONT_SIZE_BUTTON_NORMAL

	if trophy.unlocked:
		# 取得済み: ■ + 名前 + 「説明文」
		var icon = Label.new()
		icon.text = "■"
		icon.add_theme_font_size_override("font_size", font_size)
		icon.add_theme_color_override("font_color", UIConstants.COLOR_ACCENT)
		hbox.add_child(icon)

		var name_label = Label.new()
		name_label.text = trophy.name
		name_label.add_theme_font_size_override("font_size", font_size)
		name_label.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_PRIMARY)
		hbox.add_child(name_label)

		if trophy.description != "":
			var desc_label = Label.new()
			desc_label.text = "「%s」" % trophy.description
			desc_label.add_theme_font_size_override("font_size", font_size)
			desc_label.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_SECONDARY)
			hbox.add_child(desc_label)
	elif trophy.is_secret:
		# 未取得シークレット: □ + ？？？
		var icon = Label.new()
		icon.text = "□"
		icon.add_theme_font_size_override("font_size", font_size)
		icon.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_DISABLED)
		hbox.add_child(icon)

		var name_label = Label.new()
		name_label.text = "？？？"
		name_label.add_theme_font_size_override("font_size", font_size)
		name_label.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_DISABLED)
		hbox.add_child(name_label)
	else:
		# 未取得通常: □ + 名前（グレー）
		var icon = Label.new()
		icon.text = "□"
		icon.add_theme_font_size_override("font_size", font_size)
		icon.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_DISABLED)
		hbox.add_child(icon)

		var name_label = Label.new()
		name_label.text = trophy.name
		name_label.add_theme_font_size_override("font_size", font_size)
		name_label.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_DISABLED)
		hbox.add_child(name_label)

	return panel

## TrophyManager の参照を取得
func _get_trophy_manager():
	return get_node_or_null("/root/TrophyManager")

## 入力処理
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		SceneManager.goto_title()
