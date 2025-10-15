# SubtitleScene.gd
extends Control

signal subtitle_completed

var subtitle_text = ""
var fade_duration = 1.0
var display_duration = 2.0
var typewriter_speed = 0.05  # 文字表示速度（秒）

@onready var background = $Background
@onready var subtitle_label = $SubtitleLabel

func _ready():
	# フルスクリーン設定
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	# 背景を真っ黒に設定（即座に表示）
	if background:
		background.color = Color.BLACK
		background.modulate = Color.WHITE
	
	# サブタイトルラベルの設定
	if subtitle_label:
		subtitle_label.text = ""
		subtitle_label.add_theme_color_override("font_color", Color.WHITE)
		subtitle_label.add_theme_font_size_override("font_size", 48)
		subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		subtitle_label.anchor_left = 0.1
		subtitle_label.anchor_top = 0.1
		subtitle_label.anchor_right = 0.9
		subtitle_label.anchor_bottom = 0.9
		
		# 他の文章と同じフォントを使用
		var custom_theme = load("res://themes/novel_theme.tres")
		if custom_theme:
			subtitle_label.theme = custom_theme
	
	# 最初は非表示
	modulate = Color.TRANSPARENT

func show_subtitle(text: String, fade_time: float = 1.0, display_time: float = 2.0):
	subtitle_text = text
	fade_duration = fade_time
	display_duration = display_time
	
	if subtitle_label:
		subtitle_label.text = ""
	
	# 背景は即座に表示
	if background:
		background.modulate = Color.WHITE
	
	# サブタイトルシーン自体をフェードイン
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, fade_duration)
	await tween.finished
	
	# タイプライター効果で文字を左から順に表示
	await _typewriter_effect(subtitle_text)
	
	# 表示時間待機
	await get_tree().create_timer(display_duration).timeout
	
	# フェードアウト
	tween = create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, fade_duration)
	await tween.finished
	
	subtitle_completed.emit()

# タイプライター効果
func _typewriter_effect(text: String):
	if not subtitle_label:
		return
	
	var displayed_text = ""
	for i in range(text.length()):
		displayed_text += text[i]
		subtitle_label.text = displayed_text
		await get_tree().create_timer(typewriter_speed).timeout

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# クリックで即座に完了
			var tween = create_tween()
			tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.3)
			await tween.finished
			subtitle_completed.emit()
