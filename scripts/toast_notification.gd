# toast_notification.gd
# トースト通知システム

extends Control

# シグナル定義
signal toast_completed

# ログレベル定義
enum LogLevel {INFO, DEBUG, ERROR}

# UI要素
var toast_panel: Panel
var toast_label: Label
var toast_icon: TextureRect

# アニメーション用
var tween: Tween
var is_showing: bool = false

# 設定
var show_duration: float = 3.0
var fade_duration: float = 0.3
var slide_distance: float = 200.0

func _ready():
	_setup_toast_ui()
	visible = false

# トーストUIのセットアップ
func _setup_toast_ui():
	# メインパネル
	toast_panel = Panel.new()
	toast_panel.name = "toast_panel"
	
	# スタイル設定（半透明の黒背景）
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0, 0, 0, 0.8)
	style_box.border_width_left = 2
	style_box.border_width_top = 2
	style_box.border_width_right = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(1, 0.8, 0, 1)  # 金色の枠
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	toast_panel.add_theme_stylebox_override("panel", style_box)
	
	# 位置とサイズ（右上）
	var viewport_size = get_viewport_rect().size
	toast_panel.anchor_left = 1.0
	toast_panel.anchor_top = 0.0
	toast_panel.anchor_right = 1.0
	toast_panel.anchor_bottom = 0.0
	toast_panel.offset_left = -350  # パネルの幅
	toast_panel.offset_top = 20
	toast_panel.offset_right = -20
	toast_panel.offset_bottom = 100  # パネルの高さ
	
	add_child(toast_panel)
	
	# アイコン（トロフィーアイコン用、オプション）
	toast_icon = TextureRect.new()
	toast_icon.name = "toast_icon"
	toast_icon.position = Vector2(15, 15)
	toast_icon.size = Vector2(50, 50)
	toast_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	toast_panel.add_child(toast_icon)
	
	# ラベル
	toast_label = Label.new()
	toast_label.name = "toast_label"
	toast_label.position = Vector2(80, 15)
	toast_label.size = Vector2(250, 70)
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_size_override("font_size", 18)
	toast_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	toast_panel.add_child(toast_label)
	
	# 最前面に表示
	z_index = 1000
	mouse_filter = Control.MOUSE_FILTER_IGNORE

# トーストを表示
func show_toast(text: String, icon_path: String = ""):
	if is_showing:
		# 既に表示中の場合は待機してから表示
		await toast_completed
		await get_tree().create_timer(0.5).timeout
	
	is_showing = true
	
	# テキストを設定
	toast_label.text = text
	
	# アイコンを設定（オプション）
	if icon_path != "":
		var icon_texture = load(icon_path)
		if icon_texture:
			toast_icon.texture = icon_texture
			toast_icon.visible = true
		else:
			toast_icon.visible = false
	else:
		toast_icon.visible = false
	
	# 初期位置（画面外）
	var viewport_size = get_viewport_rect().size
	toast_panel.position.x = viewport_size.x
	toast_panel.position.y = 20
	modulate.a = 0.0
	visible = true
	
	# スライドインアニメーション
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_parallel(true)
	
	# フェードイン
	tween.tween_property(self, "modulate:a", 1.0, fade_duration)
	# スライドイン
	tween.tween_property(toast_panel, "position:x", viewport_size.x - toast_panel.size.x - 20, fade_duration)
	
	await tween.finished
	
	# 表示時間待機
	await get_tree().create_timer(show_duration).timeout
	
	# スライドアウトアニメーション
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_parallel(true)
	
	# フェードアウト
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	# スライドアウト
	tween.tween_property(toast_panel, "position:x", viewport_size.x, fade_duration)
	
	await tween.finished
	
	visible = false
	is_showing = false
	toast_completed.emit()

# ログメッセージの出力
func log_message(message: String, level: LogLevel = LogLevel.INFO):
	var prefix = ""
	match level:
		LogLevel.INFO:
			prefix = "[INFO] "
		LogLevel.DEBUG:
			prefix = "[DEBUG] "
		LogLevel.ERROR:
			prefix = "[ERROR] "
	
	print(prefix + "[ToastNotification] " + message)

