extends CanvasLayer
class_name StaffRollDisplay

## スタッフロール表示
## 5枚の画像（16:9）とクレジットテキストを交互レイアウトで表示する
## BGM「儚きは花なれど」（175秒）に合わせた構成:
##   イントロ 5秒 → スライド×5（30秒×5） → アウトロ 20秒

signal finished

# ─── タイミング定数 ──────────────────────���────────
const INTRO_DURATION  := 5.0    ## 冒頭の余白（黒からフェードイン込み）
const SLIDE_DURATION  := 30.0   ## 1スライドあたりの表示時間
const SLIDE_FADE      := 1.5    ## スライドのフェードイン・アウト時間
const OUTRO_DURATION  := 20.0   ## 最終テキストの表示時間
const OUTRO_FADE_IN   := 5.0    ## アウトロフェードイン
const OUTRO_FADE_OUT  := 5.0    ## アウトロフェードアウト
const IMG_WIDTH_RATIO := 0.88   ## パネル幅に対する画像幅の割合

# ─── スライドデータ ────────────────────────────────
## lines の各エントリは ["テキスト", "header" or "value" or "spacer"]
## image_left: true = 画像が左・テキストが右 / false = テキストが左・画像が右
const SLIDE_DATA := [
	{
		"image": "res://assets/staff_roll/slide_01.png",
		"image_left": true,
		"lines": [
			["シナリオ", "header"],
			["あずきしろもち", "value"],
			["", "spacer"],
			["プログラム", "header"],
			["あずきしろもち", "value"],
		]
	},
	{
		"image": "res://assets/staff_roll/slide_02.png",
		"image_left": false,
		"lines": [
			["グラフィック・背景", "header"],
			["あずきしろもち", "value"],
		]
	},
	{
		"image": "res://assets/staff_roll/slide_03.png",
		"image_left": true,
		"lines": [
			["音　楽", "header"],
			["", "spacer"],
			["BGM提供", "header"],
			["DOVA-SYNDROME", "value"],
			["", "spacer"],
			["全楽曲　のる", "value"],
			["", "spacer"],
			["効果音", "header"],
			["DOVA-SYNDROME", "value"],
			["効果音ラボ", "value"],
		]
	},
	{
		"image": "res://assets/staff_roll/slide_04.png",
		"image_left": false,
		"lines": [
			["フォント", "header"],
			["Shippori Mincho / FONTWORKS", "value"],
			["", "spacer"],
			["制作ツール", "header"],
			["Godot Engine", "value"],
		]
	},
	{
		"image": "res://assets/staff_roll/slide_05.png",
		"image_left": true,
		"lines": [
			["制　作", "header"],
			["あずきげーむ's", "value"],
		]
	},
]

const OUTRO_TEXT := "――そして、この声を聴いてくれた、あなたへ。"

# ─── 内部ノード ────────────────────────────────────
var _background: ColorRect
var _content_layer: Control

# キャッシュ
var _custom_theme: Theme = null


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	_custom_theme = _load_theme()

	# 全画面背景（墨色）
	_background = ColorRect.new()
	_background.color = UIConstants.COLOR_BASE_DARK
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background.offset_left   = 0
	_background.offset_top    = 0
	_background.offset_right  = 0
	_background.offset_bottom = 0
	_background.mouse_filter  = Control.MOUSE_FILTER_STOP
	add_child(_background)

	# コンテンツ用 Control（背景の上）
	_content_layer = Control.new()
	_content_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content_layer.offset_left   = 0
	_content_layer.offset_top    = 0
	_content_layer.offset_right  = 0
	_content_layer.offset_bottom = 0
	_content_layer.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	add_child(_content_layer)


## スタッフロールを再生する（await 可能）
## bgm_alias: 使用するBGMエイリアス（デフォルト "staff_roll"）
func play(bgm_alias: String = "staff_roll") -> void:
	visible = true

	# BGM再生（エイリアスをパスに解決してから渡す）
	var path = AudioManager.resolve_bgm_alias(bgm_alias)
	if not path.is_empty():
		AudioManager.play_bgm(path, true)

	# イントロ：黒→フェードイン
	_background.modulate.a = 0.0
	await _fade_node(_background, 1.0, 1.5)
	await _wait(INTRO_DURATION - 1.5)

	# スライド5枚
	for i in SLIDE_DATA.size():
		await _show_slide(i)

	# アウトロ
	await _outro()

	visible = false
	finished.emit()


# ─── スライド処理 ──────────────────────────────────

func _show_slide(index: int) -> void:
	var data: Dictionary = SLIDE_DATA[index]
	var slide_node := _build_slide(data)
	slide_node.modulate.a = 0.0
	_content_layer.add_child(slide_node)

	await _fade_node(slide_node, 1.0, SLIDE_FADE)
	await _wait(SLIDE_DURATION - SLIDE_FADE * 2.0)
	await _fade_node(slide_node, 0.0, SLIDE_FADE)

	slide_node.queue_free()


func _outro() -> void:
	var outro_node := _build_outro()
	outro_node.modulate.a = 0.0
	_content_layer.add_child(outro_node)

	await _fade_node(outro_node, 1.0, OUTRO_FADE_IN)
	await _wait(OUTRO_DURATION - OUTRO_FADE_IN - OUTRO_FADE_OUT)
	await _fade_node(outro_node, 0.0, OUTRO_FADE_OUT)

	outro_node.queue_free()


# ─── ノード構築 ────────────────────────────────────

func _build_slide(data: Dictionary) -> Control:
	var vp_size := get_viewport().get_visible_rect().size
	var half_w  := vp_size.x / 2.0

	# 全画面 HBoxContainer（左右50:50）
	var root := HBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left   = 0
	root.offset_top    = 0
	root.offset_right  = 0
	root.offset_bottom = 0
	root.mouse_filter  = Control.MOUSE_FILTER_IGNORE

	var left_panel  := _make_half_panel()
	var right_panel := _make_half_panel()
	root.add_child(left_panel)
	root.add_child(right_panel)

	var img_node := _build_image(data["image"], half_w)
	var txt_node := _build_text(data["lines"])

	if data["image_left"]:
		left_panel.add_child(img_node)
		right_panel.add_child(txt_node)
	else:
		left_panel.add_child(txt_node)
		right_panel.add_child(img_node)

	return root


## 左右パネル（50%幅・高さ100%）
func _make_half_panel() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	c.mouse_filter          = Control.MOUSE_FILTER_IGNORE
	return c


## 画像ノード（16:9、パネル幅の IMG_WIDTH_RATIO 倍、センタリング）
func _build_image(path: String, half_w: float) -> CenterContainer:
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.offset_left   = 0
	cc.offset_top    = 0
	cc.offset_right  = 0
	cc.offset_bottom = 0
	cc.mouse_filter  = Control.MOUSE_FILTER_IGNORE

	var img_w := half_w * IMG_WIDTH_RATIO
	var img_h := img_w * 9.0 / 16.0

	if ResourceLoader.exists(path):
		var tex_rect := TextureRect.new()
		tex_rect.custom_minimum_size = Vector2(img_w, img_h)
		tex_rect.expand_mode         = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.mouse_filter        = Control.MOUSE_FILTER_IGNORE
		tex_rect.texture             = load(path)
		cc.add_child(tex_rect)
	else:
		# 画像未作成時のプレースホルダー（やや明るい墨色の矩形）
		var ph := ColorRect.new()
		ph.custom_minimum_size = Vector2(img_w, img_h)
		ph.color        = UIConstants.COLOR_BASE_DARK.lightened(0.06)
		ph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cc.add_child(ph)

	return cc


## テキストノード（ヘッダー + 値のペア、センタリング）
func _build_text(lines: Array) -> CenterContainer:
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.offset_left   = 0
	cc.offset_top    = 0
	cc.offset_right  = 0
	cc.offset_bottom = 0
	cc.mouse_filter  = Control.MOUSE_FILTER_IGNORE

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(vbox)

	for entry: Array in lines:
		var text: String  = entry[0]
		var style: String = entry[1]

		if style == "spacer" or text.is_empty():
			var sp := Control.new()
			sp.custom_minimum_size = Vector2(0, 16)
			vbox.add_child(sp)
			continue

		var label := Label.new()
		label.text                       = text
		label.horizontal_alignment       = HORIZONTAL_ALIGNMENT_CENTER
		label.mouse_filter               = Control.MOUSE_FILTER_IGNORE
		if _custom_theme:
			label.theme = _custom_theme

		if style == "header":
			label.add_theme_font_size_override("font_size",  UIConstants.FONT_SIZE_CAPTION)
			label.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_SECONDARY)
		else:  # "value"
			label.add_theme_font_size_override("font_size",  UIConstants.FONT_SIZE_BODY)
			label.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_PRIMARY)

		vbox.add_child(label)

	return cc


## アウトロテキスト（画面中央に1行）
func _build_outro() -> CenterContainer:
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.offset_left   = 0
	cc.offset_top    = 0
	cc.offset_right  = 0
	cc.offset_bottom = 0
	cc.mouse_filter  = Control.MOUSE_FILTER_IGNORE

	var label := Label.new()
	label.text                 = OUTRO_TEXT
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size",  UIConstants.FONT_SIZE_BODY)
	label.add_theme_color_override("font_color", UIConstants.COLOR_TEXT_PRIMARY)
	label.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	if _custom_theme:
		label.theme = _custom_theme
	cc.add_child(label)

	return cc


# ─── タイミング・アニメーション ────────────────────

## ノードをフェードさせる
func _fade_node(node: CanvasItem, target: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(node, "modulate:a", target, duration)
	await tween.finished


## 指定秒待機
func _wait(duration: float) -> void:
	await get_tree().create_timer(duration).timeout


# ─── 入力遮断 ──────────────────────────────────────

## スタッフロール中はすべての入力を飲み込む
func _input(event: InputEvent) -> void:
	if visible:
		get_viewport().set_input_as_handled()


# ─── ユーティリティ ────────────────────────────────

func _load_theme() -> Theme:
	var path := "res://themes/novel_theme.tres"
	if ResourceLoader.exists(path):
		return load(path) as Theme
	return null
