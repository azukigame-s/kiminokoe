extends CanvasLayer

## 童歌・詩用フルスクリーン表示オーバーレイ
## 1行ずつフェードイン → クリックで次行へ進む

signal poem_completed
signal _advance_requested  # 内部クリック待機用

var _container: Control
var _overlay: ColorRect
var _label: Label
var _waiting_for_click: bool = false

## 後からフォントを差し替えられるようにする（フォント未設定時はデフォルト使用）
var poem_font: Font = null

func _ready():
	layer = 55  # PauseMenu(40) < PoemDisplay(55) < SceneManagerFade(1000)
	visible = false
	_build_ui()

func _build_ui() -> void:
	_container = Control.new()
	_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_container.offset_left = 0
	_container.offset_top = 0
	_container.offset_right = 0
	_container.offset_bottom = 0
	_container.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_container)

	# 暗いオーバーレイ
	_overlay = ColorRect.new()
	_overlay.color = Color(UIConstants.COLOR_BASE_DARK, 0.92)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.offset_left = 0
	_overlay.offset_top = 0
	_overlay.offset_right = 0
	_overlay.offset_bottom = 0
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(_overlay)

	# 詩テキストラベル（全体に広げてアライメントでセンタリング）
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.offset_left = 0
	_label.offset_top = -24  # フォントのアセンダー分の視覚的ズレを補正
	_label.offset_right = 0
	_label.offset_bottom = 0
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.modulate.a = 0.0
	if poem_font:
		_label.add_theme_font_override("font", poem_font)
	_label.add_theme_font_size_override("font_size", 36)
	_label.add_theme_color_override("font_color", UIConstants.COLOR_ACCENT)
	_container.add_child(_label)

## 詩を1行ずつ表示する（async）
func show_poem(lines: Array) -> void:
	_container.modulate.a = 0.0
	visible = true

	# オーバーレイフェードイン
	var tween = create_tween()
	tween.tween_property(_container, "modulate:a", 1.0, 0.4)
	await tween.finished

	for i in lines.size():
		_label.text = lines[i]

		# 1行フェードイン
		var t_in = create_tween()
		t_in.tween_property(_label, "modulate:a", 1.0, 0.5).from(0.0)
		await t_in.finished

		# クリック待機
		_waiting_for_click = true
		await _advance_requested

		# 次の行があればフェードアウト
		if i < lines.size() - 1:
			var t_out = create_tween()
			t_out.tween_property(_label, "modulate:a", 0.0, 0.3)
			await t_out.finished

	# オーバーレイ全体をフェードアウト
	var t_final = create_tween()
	t_final.tween_property(_container, "modulate:a", 0.0, 0.4)
	await t_final.finished

	visible = false
	poem_completed.emit()

func _input(event: InputEvent) -> void:
	if not visible or not _waiting_for_click:
		return

	var advance := false

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			advance = true
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			advance = true

	if advance:
		_waiting_for_click = false
		_advance_requested.emit()
		get_viewport().set_input_as_handled()
