extends Control
class_name TextDisplay

## テキスト表示クラス
## テキストバッファ、ページ送り、アニメーション表示をサポート

# シグナル
signal clicked
signal text_animation_completed

# テキスト表示設定
var text_speed: float = 0.05  # 1文字あたりの表示時間（秒）
var instant_display: bool = false  # 即座に全文表示

# テキストバッファ
var page_buffer: Array = []  # [{text: String, go_next: bool}, ...]
var current_buffer_index: int = 0

# 現在の状態
var current_text: String = ""
var displayed_text: String = ""
var full_page_text: String = ""  # ページ全体のテキスト（過去のテキストを含む）
var is_animating: bool = false
var animation_timer: float = 0.0
var current_char_index: int = 0

# 次のコマンドに自動進行するかどうか
var should_go_next: bool = false

# インジケータ設定
var indicator_symbol: String = "▼"
var page_indicator_symbol: String = "▽"
var show_indicator: bool = true
var indicator_visible: bool = true
var indicator_blink_timer: float = 0.0
var indicator_blink_speed: float = 0.5

# ノード参照
var text_label: RichTextLabel = null

func _ready():
	print("[TextDisplay] 準備完了")

	# クリック検知のための入力設定
	set_process_input(true)

	# TextLabel を探す（子ノードとして追加されている場合）
	if has_node("TextLabel"):
		text_label = get_node("TextLabel")
		print("[TextDisplay] TextLabel を検出")
	else:
		print("[TextDisplay] TextLabel は後で設定されます")

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_on_clicked()
	elif event is InputEventKey:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			if event.pressed:
				_on_clicked()

func _process(delta):
	# テキストアニメーション処理
	if is_animating and text_label:
		animation_timer += delta

		# 次の文字を表示するタイミング
		while animation_timer >= text_speed and current_char_index < current_text.length():
			current_char_index += 1
			displayed_text = current_text.substr(0, current_char_index)
			_update_display()
			animation_timer -= text_speed

		# アニメーション完了チェック
		if current_char_index >= current_text.length():
			is_animating = false
			_finalize_text()
			text_animation_completed.emit()

	# インジケータの点滅処理
	if not is_animating and show_indicator:
		indicator_blink_timer += delta
		if indicator_blink_timer >= indicator_blink_speed:
			indicator_blink_timer = 0.0
			indicator_visible = not indicator_visible
			_update_display()

## テキストを表示（バッファに追加）
func show_text(text: String, new_page: bool = false, go_next: bool = false) -> void:
	if not text_label:
		push_error("[TextDisplay] text_label が設定されていません")
		return

	print("[TextDisplay] テキスト表示: %s (new_page: %s, go_next: %s)" % [text, new_page, go_next])

	should_go_next = go_next

	if new_page:
		# 新しいページ: バッファをクリアして開始
		clear()

	# バッファに追加
	page_buffer.append({
		"text": text,
		"go_next": go_next
	})

	# テキストを設定してアニメーション開始
	current_text = text
	current_char_index = 0
	displayed_text = ""
	animation_timer = 0.0
	indicator_visible = true

	if instant_display:
		# 即座に全文表示
		displayed_text = current_text
		current_char_index = current_text.length()
		_finalize_text()
		text_animation_completed.emit()
	else:
		# アニメーション開始
		is_animating = true

## テキストをクリア（新しいページ開始）
func clear() -> void:
	page_buffer.clear()
	current_buffer_index = 0
	current_text = ""
	displayed_text = ""
	full_page_text = ""
	current_char_index = 0
	is_animating = false
	should_go_next = false

	if text_label:
		text_label.text = ""

	print("[TextDisplay] クリア")

## アニメーションを完了（即座に全文表示）
func complete_animation() -> void:
	if is_animating and text_label:
		displayed_text = current_text
		current_char_index = current_text.length()
		is_animating = false
		_finalize_text()
		text_animation_completed.emit()
		print("[TextDisplay] アニメーション完了")

## テキスト表示を確定
func _finalize_text() -> void:
	# 過去のテキストがあれば改行して追加
	if full_page_text != "":
		full_page_text += "\n\n" + displayed_text
	else:
		full_page_text = displayed_text

	_update_display()

## 表示を更新
func _update_display() -> void:
	if not text_label:
		return

	var display_text = ""

	if is_animating:
		# アニメーション中: 過去テキスト + 現在のアニメーション中テキスト
		if full_page_text != "":
			display_text = full_page_text + "\n\n" + displayed_text
		else:
			display_text = displayed_text
	else:
		# アニメーション完了: 全テキスト + インジケータ
		display_text = full_page_text
		if show_indicator and indicator_visible:
			display_text += _get_indicator()

	text_label.text = display_text

## インジケータを取得
func _get_indicator() -> String:
	if should_go_next:
		return " " + page_indicator_symbol
	else:
		return " " + indicator_symbol

## クリックされた時の処理
func _on_clicked() -> void:
	if is_animating:
		# アニメーション中ならアニメーションを完了
		complete_animation()
	else:
		# アニメーション完了後
		if should_go_next:
			# go_next フラグがある場合は自動的に次へ
			clicked.emit()
		else:
			# 通常のクリック待機完了
			clicked.emit()
		print("[TextDisplay] クリック")

## バッファに次のテキストがあるかチェック
func has_more_in_buffer() -> bool:
	return current_buffer_index < page_buffer.size() - 1

## 次のテキストをバッファから表示
func show_next_from_buffer() -> bool:
	if has_more_in_buffer():
		current_buffer_index += 1
		var item = page_buffer[current_buffer_index]
		show_text(item.text, false, item.go_next)
		return true
	return false

## 即座表示モードの設定
func set_instant_display(enabled: bool) -> void:
	instant_display = enabled

## go_next フラグを取得
func is_go_next() -> bool:
	return should_go_next