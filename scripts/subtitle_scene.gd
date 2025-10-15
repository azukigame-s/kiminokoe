extends Control

# サブタイトル表示システム
# 真っ黒背景でテキストをスライドアニメーション表示

# シグナル定義
signal subtitle_completed

# アニメーション設定
var fade_time: float = 1.0
var display_time: float = 2.0

# ノード参照
var background: ColorRect
var subtitle_label: Label

# アニメーション状態
var is_showing_subtitle = false
var current_animation: Tween

func _ready():
	# 初期設定
	visible = false
	z_index = 1000  # 最前面に表示
	
	# サブタイトルシーン自体のレイアウト設定
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	# マウスフィルターを無視に設定（背景クリックを防ぐ）
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# ノード参照を取得
	background = get_node_or_null("background")
	subtitle_label = get_node_or_null("subtitle_label")
	
	# 背景を真っ黒に設定
	if background:
		background.color = Color(0, 0, 0, 1)
		background.anchor_left = 0.0
		background.anchor_top = 0.0
		background.anchor_right = 1.0
		background.anchor_bottom = 1.0
		background.offset_left = 0
		background.offset_top = 0
		background.offset_right = 0
		background.offset_bottom = 0
	
	# サブタイトルラベルの設定
	if subtitle_label:
		subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		subtitle_label.anchor_left = 0.0
		subtitle_label.anchor_top = 0.0
		subtitle_label.anchor_right = 1.0
		subtitle_label.anchor_bottom = 1.0
		subtitle_label.offset_left = 0
		subtitle_label.offset_top = 0
		subtitle_label.offset_right = 0
		subtitle_label.offset_bottom = 0
		subtitle_label.add_theme_font_size_override("font_size", 48)  # 少し大きく
		subtitle_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		
		# フォントをロード（プロジェクトにフォントがある場合）
		var font_path = "res://themes/novel_theme.tres"
		if ResourceLoader.exists(font_path):
			var custom_theme = load(font_path)
			if custom_theme:
				subtitle_label.theme = custom_theme
				log_message("Custom theme applied to subtitle label")

# サブタイトル表示
func show_subtitle(text: String, p_fade_time: float = 1.0, p_display_time: float = 2.0):
	if is_showing_subtitle:
		return
	
	# 必要なノードが存在しない場合は即座に完了
	if not background or not subtitle_label:
		log_message("ERROR: Required nodes not found - skipping subtitle: " + text)
		subtitle_completed.emit()
		return
	
	fade_time = p_fade_time
	display_time = p_display_time
	is_showing_subtitle = true
	
	log_message("Showing subtitle: " + text)
	
	# テキスト設定
	subtitle_label.text = text
	
	# 初期状態設定
	visible = true
	modulate = Color(1, 1, 1, 0)
	
	# z_indexを最前面に設定
	z_index = 1000
	
	# フェードインアニメーション開始
	_start_fade_in()

# フェードインアニメーション
func _start_fade_in():
	if current_animation:
		current_animation.kill()
	
	current_animation = create_tween()
	current_animation.tween_property(self, "modulate", Color(1, 1, 1, 1), fade_time)
	current_animation.tween_callback(_on_fade_in_complete)

# フェードイン完了
func _on_fade_in_complete():
	log_message("Fade in completed")
	
	# 表示時間後に完了
	await get_tree().create_timer(display_time).timeout
	_finish_subtitle()

# サブタイトル完了
func _finish_subtitle():
	log_message("Subtitle finished")
	is_showing_subtitle = false
	visible = false
	
	# z_indexを下げて背景が表示されるようにする
	z_index = -1
	
	subtitle_completed.emit()

# サブタイトルを即座に終了
func skip_subtitle():
	if is_showing_subtitle:
		_finish_subtitle()

# ログメッセージ
func log_message(message: String):
	print("[SubtitleScene] " + message)
