extends Control

# サブタイトル表示システム
# 真っ黒背景でテキストをタイプエフェクト表示

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

# タイプエフェクト用
var full_text: String = ""
var displayed_text: String = ""
var type_timer: float = 0.0
var type_speed: float = 0.05  # 1文字あたりの表示時間（秒）
var is_typing: bool = false

func _ready():
	# 初期設定
	visible = false
	z_index = 1000  # 最前面に表示
	
	# サブタイトルシーン自体のレイアウト設定
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	# マウスフィルターを通過に設定（クリックでスキップ可能にする）
	mouse_filter = Control.MOUSE_FILTER_PASS
	
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
		background.visible = false  # 初期状態では非表示
	
	# サブタイトルラベルの設定
	if subtitle_label:
		# 左揃えにして、文字が左から右に順番に表示されるようにする
		subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		# 中央基準で配置（anchor を中央に設定）
		subtitle_label.anchor_left = 0.5
		subtitle_label.anchor_top = 0.5
		subtitle_label.anchor_right = 0.5
		subtitle_label.anchor_bottom = 0.5
		# offset は後で画面サイズに応じて設定
		subtitle_label.add_theme_font_size_override("font_size", 48)  # 少し大きく
		subtitle_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		subtitle_label.modulate = Color(1, 1, 1, 1)  # 常に不透明（タイプエフェクトで制御）
		subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # ラベル自体はクリックを無視
		
		# 画面サイズに応じて offset を設定
		await get_tree().process_frame
		_update_label_position()
		
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
	
	# タイプエフェクト用のテキスト設定
	full_text = text
	displayed_text = ""
	subtitle_label.text = ""  # 初期状態では空
	
	# タイプ速度を計算（fade_timeを文字数で割る）
	if text.length() > 0:
		type_speed = fade_time / text.length()
	else:
		type_speed = 0.05
	
	# 初期状態設定
	# 背景は即座に黒く表示（フェードインはしない）
	if background:
		background.visible = true
		background.modulate = Color(1, 1, 1, 1)  # 背景は即座に表示
	subtitle_label.modulate = Color(1, 1, 1, 1)  # テキストは常に不透明
	visible = true
	modulate = Color(1, 1, 1, 1)  # サブタイトルシーン自体は即座に表示
	
	# z_indexを最前面に設定
	z_index = 1000
	
	# タイプエフェクトを開始
	_start_type_effect()

# ラベルの位置を更新（画面サイズに応じて）
func _update_label_position():
	if not subtitle_label:
		return
	
	var screen_width = get_viewport_rect().size.x
	var label_width = screen_width * 0.8  # 画面幅の80%
	var font_size = 48
	
	subtitle_label.offset_left = -label_width / 2.0
	subtitle_label.offset_top = -font_size / 2.0
	subtitle_label.offset_right = label_width / 2.0
	subtitle_label.offset_bottom = font_size / 2.0

# タイプエフェクト開始
func _start_type_effect():
	log_message("Starting type effect")
	
	# ラベルの位置を更新
	_update_label_position()
	
	# タイプエフェクトを開始
	is_typing = true
	type_timer = 0.0


# タイプエフェクト処理（_process で呼び出される）
func _process(delta):
	if is_typing and is_showing_subtitle:
		type_timer += delta
		if type_timer >= type_speed:
			type_timer = 0.0
			if displayed_text.length() < full_text.length():
				displayed_text += full_text[displayed_text.length()]
				subtitle_label.text = displayed_text
			else:
				# タイプエフェクト完了
				is_typing = false
				_on_type_complete()

# タイプエフェクト完了
func _on_type_complete():
	log_message("Type effect completed")
	
	# 表示時間後に完了
	await get_tree().create_timer(display_time).timeout
	_finish_subtitle()


# サブタイトル完了
func _finish_subtitle():
	log_message("Subtitle finished")
	
	# アニメーションを停止
	if current_animation:
		current_animation.kill()
		current_animation = null
	
	# タイプエフェクトを停止
	is_typing = false
	is_showing_subtitle = false
	
	# フェードアウトアニメーション
	var fade_out_tween = create_tween()
	fade_out_tween.set_parallel(true)
	
	if background:
		fade_out_tween.tween_property(background, "modulate", Color(1, 1, 1, 0), fade_time)
	if subtitle_label:
		fade_out_tween.tween_property(subtitle_label, "modulate", Color(1, 1, 1, 0), fade_time)
	
	await fade_out_tween.finished
	
	# 非表示にする
	visible = false
	if background:
		background.visible = false  # 背景も非表示にする
	
	
	# z_indexを下げて背景が表示されるようにする
	z_index = -1
	
	subtitle_completed.emit()

# サブタイトルを即座に終了
func skip_subtitle():
	if is_showing_subtitle:
		log_message("Subtitle skipped by user")
		# タイプエフェクトを即座に完了させる
		if is_typing:
			displayed_text = full_text
			subtitle_label.text = full_text
			is_typing = false
		_finish_subtitle()

# クリックイベント処理
func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if is_showing_subtitle:
				skip_subtitle()

# ログメッセージ
func log_message(message: String):
	print("[SubtitleScene] " + message)
