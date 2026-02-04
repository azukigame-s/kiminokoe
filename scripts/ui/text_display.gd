extends Control
class_name TextDisplay

## テキスト表示クラス
## シンプルなテキスト表示とクリック待機

# シグナル
signal clicked
signal text_animation_completed

# テキスト表示設定
var text_speed: float = 0.05  # 1文字あたりの表示時間（秒）
var instant_display: bool = false  # 即座に全文表示

# 現在の状態
var current_text: String = ""
var displayed_text: String = ""
var is_animating: bool = false
var animation_timer: float = 0.0
var current_char_index: int = 0

# ノード参照
var text_label: RichTextLabel = null

func _ready():
	print("[TextDisplay] Ready")

	# クリック検知のための入力設定
	set_process_input(true)

	# TextLabel を探す（子ノードとして追加されている場合）
	if has_node("TextLabel"):
		text_label = get_node("TextLabel")
		print("[TextDisplay] TextLabel found")
	else:
		print("[TextDisplay] TextLabel not found, will be set later")

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_on_clicked()
	elif event is InputEventKey:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			if event.pressed:
				_on_clicked()

func _process(delta):
	if is_animating and text_label:
		animation_timer += delta

		# 次の文字を表示するタイミング
		while animation_timer >= text_speed and current_char_index < current_text.length():
			current_char_index += 1
			displayed_text = current_text.substr(0, current_char_index)
			text_label.text = displayed_text
			animation_timer -= text_speed

		# アニメーション完了チェック
		if current_char_index >= current_text.length():
			is_animating = false
			text_animation_completed.emit()

## テキストを表示
func show_text(text: String) -> void:
	if not text_label:
		push_error("[TextDisplay] text_label is null")
		return

	current_text = text
	current_char_index = 0
	displayed_text = ""
	animation_timer = 0.0

	if instant_display:
		# 即座に全文表示
		displayed_text = current_text
		current_char_index = current_text.length()
		text_label.text = displayed_text
		is_animating = false
		text_animation_completed.emit()
	else:
		# アニメーション開始
		is_animating = true
		text_label.text = ""

	print("[TextDisplay] Showing text: %s" % text)

## テキストをクリア
func clear() -> void:
	current_text = ""
	displayed_text = ""
	current_char_index = 0
	is_animating = false
	if text_label:
		text_label.text = ""
	print("[TextDisplay] Cleared")

## アニメーションを完了（即座に全文表示）
func complete_animation() -> void:
	if is_animating and text_label:
		displayed_text = current_text
		current_char_index = current_text.length()
		text_label.text = displayed_text
		is_animating = false
		text_animation_completed.emit()
		print("[TextDisplay] Animation completed")

## クリックされた時の処理
func _on_clicked() -> void:
	if is_animating:
		# アニメーション中ならアニメーションを完了
		complete_animation()
	else:
		# アニメーション完了後ならクリックシグナルを発行
		clicked.emit()
		print("[TextDisplay] Clicked")

## 即座表示モードの設定
func set_instant_display(enabled: bool) -> void:
	instant_display = enabled
