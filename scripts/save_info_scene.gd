extends Control

## セーブ情報画面
## タイトルから「ゲームを始める」で遷移。セーブデータの情報を表示し、
## 「つづきからはじめる」/「はじめる」の選択、データリセット機能を提供。

var _start_button: Button
var _new_game_button: Button
var _reset_button: Button
var _info_container: VBoxContainer
var _no_save_label: Label
var _confirm_overlay: ColorRect
var _confirm_mode: String = ""  # "new_game" or "reset"

func _ready():
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var theme_path = "res://themes/novel_theme.tres"
	if ResourceLoader.exists(theme_path):
		theme = load(theme_path)
	_build_ui()
	# 続行可能なら「つづきから」、不可なら「はじめから」にフォーカス
	if _start_button and _start_button.focus_mode != Control.FOCUS_NONE:
		_start_button.grab_focus()
	elif _new_game_button:
		_new_game_button.grab_focus()
	elif _start_button:
		_start_button.grab_focus()

func _build_ui():
	# 背景（墨色 95%）
	var bg = ColorRect.new()
	bg.color = Color(UIConstants.COLOR_BASE_DARK, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# タイトルエリア
	_build_title_area()

	# 中央コンテナ
	var center = VBoxContainer.new()
	center.anchor_left = 0.1
	center.anchor_top = 0.1
	center.anchor_right = 0.9
	center.anchor_bottom = 0.9
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 16)
	add_child(center)

	var has_save = SceneManager.has_save_data()
	var can_continue = SceneManager.can_continue()

	if has_save:
		_build_save_info(center)
	else:
		_build_no_save_info(center)

	# スペーサー
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 16
	center.add_child(spacer)

	if has_save:
		# つづきからはじめる（シナリオ進行がない場合は非活性）
		_start_button = Button.new()
		_start_button.text = "つづきからはじめる"
		UIStyleHelper.style_title_button(_start_button)
		_start_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		if can_continue:
			_start_button.pressed.connect(_on_continue_pressed)
		else:
			# disabled は背景色が変わるので使わず、色とマウスで非活性を表現
			_start_button.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_DISABLED)
			_start_button.add_theme_color_override("font_hover_color", UIConstants.COLOR_TEXT_DISABLED)
			_start_button.add_theme_color_override("font_pressed_color", UIConstants.COLOR_TEXT_DISABLED)
			_start_button.add_theme_color_override("font_focus_color", UIConstants.COLOR_TEXT_DISABLED)
			_start_button.mouse_default_cursor_shape = Control.CURSOR_ARROW
			_start_button.focus_mode = Control.FOCUS_NONE
		center.add_child(_start_button)

		# はじめからはじめる（サブアクション）
		_new_game_button = Button.new()
		_new_game_button.text = "はじめからはじめる"
		UIStyleHelper.style_title_button(_new_game_button)
		_new_game_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		_new_game_button.pressed.connect(_on_new_game_pressed)
		center.add_child(_new_game_button)

		# データをリセット（最下部、控えめ）
		_reset_button = Button.new()
		_reset_button.text = "記憶を忘れる"
		_reset_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		_style_reset_button(_reset_button)
		_reset_button.pressed.connect(_on_reset_pressed)
		center.add_child(_reset_button)
	else:
		# セーブなし: はじめるのみ
		_start_button = Button.new()
		_start_button.text = "はじめる"
		UIStyleHelper.style_title_button(_start_button)
		_start_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		_start_button.pressed.connect(_on_new_game_start)
		center.add_child(_start_button)

	# もどるボタン
	var back_button = Button.new()
	back_button.text = "もどる"
	back_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyleHelper.style_back_button(back_button)
	back_button.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	back_button.offset_top = -35
	back_button.offset_bottom = -12
	back_button.pressed.connect(func(): SceneManager.goto_title())
	add_child(back_button)

## セーブデータ情報を表示
func _build_save_info(parent: VBoxContainer):
	var save_data = SceneManager.load_save_data()

	# 栞画像をベースにした情報パネル
	var bookmark_container = Control.new()
	bookmark_container.custom_minimum_size = Vector2(600, 200)
	bookmark_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	parent.add_child(bookmark_container)

	# 栞背景画像
	var texture_rect = TextureRect.new()
	var texture_path = "res://assets/ui/bookmark.png"
	if ResourceLoader.exists(texture_path):
		texture_rect.texture = load(texture_path)
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bookmark_container.add_child(texture_rect)

	# テキストを重ねるコンテナ（位置はbookmark.pngのレイアウトに合わせて調整）
	_info_container = VBoxContainer.new()
	_info_container.add_theme_constant_override("separation", 12)
	_info_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_info_container.offset_left = 200
	_info_container.offset_top = 20
	_info_container.offset_right = -20
	_info_container.offset_bottom = -20
	_info_container.alignment = BoxContainer.ALIGNMENT_CENTER
	bookmark_container.add_child(_info_container)

	# 栞カードは明るい地色なので丁子茶テキスト・アウトラインなしでコントラストを確保
	var text_color = UIConstants.COLOR_SUB_ACCENT

	# 主人公名
	var name_label = Label.new()
	name_label.text = "主人公: %s" % save_data.get("protagonist_name", "コウ")
	name_label.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_BODY)
	name_label.add_theme_color_override("font_color", text_color)
	name_label.add_theme_constant_override("outline_size", 0)
	_info_container.add_child(name_label)

	# プレイ時間
	var play_time_label = Label.new()
	var play_time_sec = save_data.get("play_time", 0.0)
	play_time_label.text = "プレイ時間: %s" % _format_play_time(play_time_sec)
	play_time_label.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_BODY)
	play_time_label.add_theme_color_override("font_color", text_color)
	play_time_label.add_theme_constant_override("outline_size", 0)
	_info_container.add_child(play_time_label)

	# 軌跡（トロフィー）進捗
	var trophy_label = Label.new()
	var trophy_mgr = get_node_or_null("/root/TrophyManager")
	if trophy_mgr:
		var unlocked = trophy_mgr.get_unlocked_trophy_count()
		var total = trophy_mgr.get_total_trophy_count()
		trophy_label.text = "軌跡: %d/%d" % [unlocked, total]
	else:
		trophy_label.text = "軌跡: ---"
	trophy_label.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_BODY)
	trophy_label.add_theme_color_override("font_color", text_color)
	trophy_label.add_theme_constant_override("outline_size", 0)
	_info_container.add_child(trophy_label)

## セーブなし時の表示
func _build_no_save_info(parent: VBoxContainer):
	_no_save_label = Label.new()
	_no_save_label.text = "挟んでいる栞はありません"
	_no_save_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_no_save_label.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_BODY)
	_no_save_label.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_SECONDARY)
	parent.add_child(_no_save_label)

## リセットボタンのスタイル
func _style_reset_button(button: Button):
	button.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_BUTTON_NORMAL)
	button.custom_minimum_size = UIConstants.BUTTON_MIN_SIZE_NORMAL
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color.TRANSPARENT
	normal_style.border_width_bottom = 1
	normal_style.border_color = Color(UIConstants.COLOR_ACCENT, 0.3)
	normal_style.content_margin_left = 16
	normal_style.content_margin_right = 16
	normal_style.content_margin_top = 8
	normal_style.content_margin_bottom = 8
	button.add_theme_stylebox_override("normal", normal_style)

	var hover_style = normal_style.duplicate()
	hover_style.border_color = UIConstants.COLOR_ACCENT
	button.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = normal_style.duplicate()
	button.add_theme_stylebox_override("pressed", pressed_style)

	var focus_style = normal_style.duplicate()
	button.add_theme_stylebox_override("focus", focus_style)

	button.add_theme_color_override("font_color", Color(UIConstants.COLOR_ACCENT, 0.6))
	button.add_theme_color_override("font_hover_color", UIConstants.COLOR_ACCENT)
	button.add_theme_color_override("font_pressed_color", UIConstants.COLOR_ACCENT)

## プレイ時間のフォーマット
func _format_play_time(seconds: float) -> String:
	var total_sec: int = int(seconds)
	var hours: int = total_sec / 3600
	var minutes: int = (total_sec % 3600) / 60
	var secs: int = total_sec % 60
	return "%02d:%02d:%02d" % [hours, minutes, secs]

## つづきからはじめる
func _on_continue_pressed():
	print("[SaveInfoScene] Continue game")
	SceneManager.game_start_mode = "continue"
	SceneManager.goto_game()

## はじめからはじめる（セーブあり時）
func _on_new_game_pressed():
	if SceneManager.can_continue():
		# シナリオ進行がある場合は確認ダイアログ
		_show_confirm_dialog("new_game")
	else:
		# シナリオ進行がない場合は消すデータがないので直接開始
		SceneManager.game_start_mode = "new"
		SceneManager.goto_game()

## はじめる（セーブなし時）
func _on_new_game_start():
	print("[SaveInfoScene] New game")
	SceneManager.goto_name_input()

## リセットボタン
func _on_reset_pressed():
	_show_confirm_dialog("reset")

## 確認ダイアログ表示
func _show_confirm_dialog(mode: String):
	if _confirm_overlay:
		return
	_confirm_mode = mode

	# オーバーレイ背景
	_confirm_overlay = ColorRect.new()
	_confirm_overlay.color = Color(0, 0, 0, 0.7)
	_confirm_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm_overlay.offset_left = 0
	_confirm_overlay.offset_top = 0
	_confirm_overlay.offset_right = 0
	_confirm_overlay.offset_bottom = 0
	add_child(_confirm_overlay)

	# ダイアログパネル
	var dialog = PanelContainer.new()
	var dialog_style = StyleBoxFlat.new()
	dialog_style.bg_color = UIConstants.COLOR_BASE_DARK
	dialog_style.border_width_left = 2
	dialog_style.border_width_right = 2
	dialog_style.border_width_top = 2
	dialog_style.border_width_bottom = 2
	dialog_style.border_color = UIConstants.COLOR_ACCENT
	dialog_style.corner_radius_top_left = UIConstants.CORNER_RADIUS
	dialog_style.corner_radius_top_right = UIConstants.CORNER_RADIUS
	dialog_style.corner_radius_bottom_left = UIConstants.CORNER_RADIUS
	dialog_style.corner_radius_bottom_right = UIConstants.CORNER_RADIUS
	dialog_style.content_margin_left = 32
	dialog_style.content_margin_right = 32
	dialog_style.content_margin_top = 24
	dialog_style.content_margin_bottom = 24
	dialog.add_theme_stylebox_override("panel", dialog_style)
	dialog.set_anchors_preset(Control.PRESET_CENTER)
	dialog.offset_left = -200
	dialog.offset_right = 200
	dialog.offset_top = -80
	dialog.offset_bottom = 80
	_confirm_overlay.add_child(dialog)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	dialog.add_child(vbox)

	# メッセージ（モードで切り替え）
	var msg = Label.new()
	if mode == "new_game":
		msg.text = "栞を外して\n最初から読み直しますか？"
	else:
		msg.text = "すべての記憶を忘れますか？\n栞と軌跡が消去されます"
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", UIConstants.FONT_SIZE_BODY)
	msg.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_PRIMARY)
	vbox.add_child(msg)

	# ボタン行
	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 24)
	vbox.add_child(btn_row)

	var yes_btn = Button.new()
	yes_btn.text = "はい" if mode == "new_game" else "忘れる"
	yes_btn.custom_minimum_size = Vector2(140, 40)
	_style_reset_button(yes_btn)
	yes_btn.pressed.connect(_execute_confirm)
	btn_row.add_child(yes_btn)

	var no_btn = Button.new()
	no_btn.text = "いいえ" if mode == "new_game" else "やめる"
	no_btn.custom_minimum_size = Vector2(140, 40)
	UIStyleHelper.style_menu_button(no_btn)
	no_btn.pressed.connect(_close_confirm_dialog)
	btn_row.add_child(no_btn)

	no_btn.grab_focus()

## 確認ダイアログを閉じる
func _close_confirm_dialog():
	if _confirm_overlay:
		_confirm_overlay.queue_free()
		_confirm_overlay = null
	if _start_button:
		_start_button.grab_focus()

## 確認ダイアログの「はい」ボタン
func _execute_confirm():
	if _confirm_mode == "new_game":
		_execute_new_game()
	else:
		_execute_reset()

## はじめからはじめる実行（セーブデータのみ消去、名前・軌跡・プレー時間は保持）
func _execute_new_game():
	print("[SaveInfoScene] New game from beginning (save data cleared)")
	SceneManager.clear_save_data()
	SceneManager.initialize_save()
	_close_confirm_dialog()
	SceneManager.game_start_mode = "new"
	SceneManager.goto_game()

## データリセット実行（全データ消去）
func _execute_reset():
	print("[SaveInfoScene] Full data reset executed")
	var trophy_mgr = get_node_or_null("/root/TrophyManager")
	# リセット前に「転生する勇気」条件を確認してフラグを立てる
	if trophy_mgr:
		trophy_mgr.set_tensei_pending()
	SceneManager.clear_save_data()
	SceneManager.protagonist_name = "コウ"
	SceneManager.play_time = 0.0
	if trophy_mgr:
		trophy_mgr.reset_trophy_data()

	_close_confirm_dialog()
	_refresh_display()

## 画面を再構築（リセット後）
func _refresh_display():
	# 既存のUIを削除して再構築
	for child in get_children():
		child.queue_free()
	# 1フレーム待ってから再構築
	await get_tree().process_frame
	_build_ui()
	if _start_button:
		_start_button.grab_focus()

## タイトルエリア（装飾線 ── セーブデータ ── の形）
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
	title.text = "栞"
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

## 入力処理
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			if _confirm_overlay:
				_close_confirm_dialog()
			else:
				SceneManager.goto_title()
