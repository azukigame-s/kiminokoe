extends Control
class_name TextDisplay

## テキスト表示クラス（ステートマシン版）
## show_text() / wait_for_advance() の async API を提供

# 状態定義
enum State { IDLE, ANIMATING, WAITING }

# 内部シグナル（await 解決用）
signal _animation_finished
signal _advance_requested

# テキスト表示設定（ProjectSettings から読み込み、設定画面で変更可能）
var text_speed: float = 0.06:
	get:
		return ProjectSettings.get_setting("visual_novel/text_speed", 0.06)
var instant_display: bool = false

# 状態
var _state: State = State.IDLE
var _current_text: String = ""
var _displayed_text: String = ""
var _full_page_text: String = ""  # ページ内の過去テキスト
var _char_index: int = 0
var _animation_timer: float = 0.0

# go_next フラグ（インジケータ表示用）
var _go_next: bool = false

# インジケータ
var _indicator_blink_timer: float = 0.0
var _indicator_blink_speed: float = 0.5
var _indicator_visible: bool = true

# ノード参照
var text_label: RichTextLabel = null

# 後方互換プロパティ（外部から状態を確認する場合用）
var is_animating: bool:
	get:
		return _state == State.ANIMATING

func _ready():
	if has_node("TextLabel"):
		text_label = get_node("TextLabel")

func _input(event):
	var is_click = false

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			is_click = true
	elif event is InputEventKey:
		if (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE) and event.pressed:
			is_click = true

	if not is_click:
		return

	match _state:
		State.ANIMATING:
			_complete_animation()
		State.WAITING:
			_state = State.IDLE
			_advance_requested.emit()

func _process(delta):
	match _state:
		State.ANIMATING:
			_process_animation(delta)
		State.WAITING:
			_process_indicator_blink(delta)

## アニメーション処理
func _process_animation(delta: float) -> void:
	if not text_label:
		return

	_animation_timer += delta

	while _animation_timer >= text_speed and _char_index < _current_text.length():
		_char_index += 1
		_displayed_text = _current_text.substr(0, _char_index)
		_update_display()
		_animation_timer -= text_speed

	# 全文字表示完了
	if _char_index >= _current_text.length():
		_complete_animation()

## インジケータ点滅処理
func _process_indicator_blink(delta: float) -> void:
	_indicator_blink_timer += delta
	if _indicator_blink_timer >= _indicator_blink_speed:
		_indicator_blink_timer = 0.0
		_indicator_visible = not _indicator_visible
		_update_display()

# ===== Public API =====

## テキストを表示（async: アニメーション完了まで待機）
func show_text(text: String, new_page: bool = false) -> void:
	if not text_label:
		push_error("[TextDisplay] text_label が設定されていません")
		return

	if new_page:
		_clear_internal()

	_current_text = text
	_char_index = 0
	_displayed_text = ""
	_animation_timer = 0.0

	if instant_display:
		# 即座に全文表示して返る
		_displayed_text = _current_text
		_char_index = _current_text.length()
		_finalize_text()
		_state = State.IDLE
		_animation_finished.emit()
		return

	# アニメーション開始 → 完了まで待機
	_state = State.ANIMATING
	await _animation_finished

## クリック待機（async: ユーザーのクリックまで待機）
func wait_for_advance() -> void:
	_state = State.WAITING
	_indicator_visible = true
	_indicator_blink_timer = 0.0
	_update_display()

	await _advance_requested

## 強制完了（スキップモードから呼ばれる同期メソッド）
## ANIMATING → アニメーション完了、WAITING → クリック待機解除
func force_complete() -> void:
	match _state:
		State.ANIMATING:
			_complete_animation()
		State.WAITING:
			_state = State.IDLE
			_advance_requested.emit()

## go_next フラグを設定（インジケータ種別の切り替え用）
func set_go_next(value: bool) -> void:
	_go_next = value

## テキストをクリア
func clear() -> void:
	_clear_internal()

## 即座表示モードの設定
func set_instant_display(enabled: bool) -> void:
	instant_display = enabled

# ===== Internal =====

func _clear_internal() -> void:
	# WAITING状態の場合は、待機中のwait_for_advance()をキャンセル
	# ただし、_advance_requestedは発行しない（wait_for_advance()が呼ばれる前に発行されると、awaitが即座に解決されてしまうため）
	# 代わりに、wait_for_advance()の最初で状態を確認する
	_state = State.IDLE
	_current_text = ""
	_displayed_text = ""
	_full_page_text = ""
	_char_index = 0
	_animation_timer = 0.0
	_go_next = false
	if text_label:
		text_label.text = ""

func _complete_animation() -> void:
	_displayed_text = _current_text
	_char_index = _current_text.length()
	_state = State.IDLE
	_finalize_text()
	_animation_finished.emit()

func _finalize_text() -> void:
	if _full_page_text != "":
		_full_page_text += "\n\n" + _displayed_text
	else:
		_full_page_text = _displayed_text
	_update_display()

func _update_display() -> void:
	if not text_label:
		return

	# BBCodeモードを有効化（インジケータの色制御に使用）
	if not text_label.bbcode_enabled:
		text_label.bbcode_enabled = true

	var display_text = ""
	var indicator_char = " [font_size=19]⎘[/font_size]" if _go_next else " [font_size=19]⏎[/font_size]"
	var transparent_indicator = "[color=#00000000]" + indicator_char + "[/color]"

	match _state:
		State.ANIMATING:
			# アニメーション中: 過去テキスト + アニメーション中テキスト
			if _full_page_text != "":
				display_text = _escape_bbcode(_full_page_text) + "\n\n" + _escape_bbcode(_displayed_text)
			else:
				display_text = _escape_bbcode(_displayed_text)
			# レイアウト安定化のため透明インジケータを常に配置
			display_text += transparent_indicator
		_:
			# IDLE / WAITING: 確定済みテキスト + インジケータ
			display_text = _escape_bbcode(_full_page_text)
			if _state == State.WAITING:
				if _indicator_visible:
					display_text += indicator_char
				else:
					display_text += transparent_indicator
			elif _full_page_text != "":
				# IDLE状態でもレイアウト安定化のため透明インジケータを配置
				display_text += transparent_indicator

	text_label.text = display_text

## BBCodeタグのエスケープ（テキスト内の [ をリテラルとして表示）
func _escape_bbcode(text: String) -> String:
	return text.replace("[", "[lb]")
