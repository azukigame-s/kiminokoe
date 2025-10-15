extends Control

# サブタイトル表示システム
# 真っ黒背景でテキストをスライドアニメーション表示

# シグナル定義
signal subtitle_completed

# アニメーション設定
var fade_time: float = 1.0
var display_time: float = 2.0
var slide_distance: float = 100.0
var slide_duration: float = 0.8

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
		subtitle_label.add_theme_font_size_override("font_size", 36)
		subtitle_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		
		# フォントをロード（プロジェクトにフォントがある場合）
		var font_path = "res://themes/novel_theme.tres"
		if ResourceLoader.exists(font_path):
			var theme = load(font_path)
			if theme and theme.has_font("normal_font", "Label"):
				subtitle_label.add_theme_font_override("font", theme.get_font("normal_font", "Label"))

# サブタイトル表示
func show_subtitle(text: String, fade_time: float = 1.0, display_time: float = 2.0):
	if is_showing_subtitle:
		return
	
	# 必要なノードが存在しない場合は即座に完了
	if not background or not subtitle_label:
		log_message("ERROR: Required nodes not found - skipping subtitle: " + text)
		subtitle_completed.emit()
		return
	
	self.fade_time = fade_time
	self.display_time = display_time
	is_showing_subtitle = true
	
	log_message("Showing subtitle: " + text)
	
	# テキスト設定
	subtitle_label.text = text
	
	# 初期状態設定
	visible = true
	modulate = Color(1, 1, 1, 0)
	subtitle_label.position.y = get_viewport_rect().size.y + slide_distance
	
	# アニメーション開始
	_start_subtitle_animation()

# サブタイトルアニメーション
func _start_subtitle_animation():
	if current_animation:
		current_animation.kill()
	
	current_animation = create_tween()
	current_animation.set_parallel(true)
	
	# フェードイン
	current_animation.tween_property(self, "modulate", Color(1, 1, 1, 1), fade_time)
	
	# スライドイン
	if subtitle_label:
		var target_y = get_viewport_rect().size.y * 0.5
		current_animation.tween_property(subtitle_label, "position:y", target_y, slide_duration)
		current_animation.tween_callback(_on_slide_in_complete).set_delay(slide_duration)
	
	# 表示時間後にフェードアウト
	current_animation.tween_callback(_start_fade_out).set_delay(display_time)

# スライドイン完了
func _on_slide_in_complete():
	log_message("Subtitle slide in completed")

# フェードアウト開始
func _start_fade_out():
	if current_animation:
		current_animation.kill()
	
	current_animation = create_tween()
	current_animation.set_parallel(true)
	
	# フェードアウト
	current_animation.tween_property(self, "modulate", Color(1, 1, 1, 0), fade_time)
	
	# スライドアウト
	if subtitle_label:
		var target_y = -slide_distance
		current_animation.tween_property(subtitle_label, "position:y", target_y, slide_duration)
	
	# アニメーション完了
	current_animation.tween_callback(_on_subtitle_completed).set_delay(fade_time)

# サブタイトル完了
func _on_subtitle_completed():
	log_message("Subtitle completed")
	is_showing_subtitle = false
	visible = false
	subtitle_completed.emit()

# サブタイトルを即座に終了
func skip_subtitle():
	if is_showing_subtitle:
		_on_subtitle_completed()

# ログメッセージ
func log_message(message: String):
	print("[SubtitleScene] " + message)
