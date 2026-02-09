extends Control
class_name TextDisplay

## テキスト表示クラス（ステートマシン版）
## show_text() / wait_for_advance() の async API を提供

# 状態定義
enum State { IDLE, ANIMATING, WAITING }

# 内部シグナル（await 解決用）
signal _animation_finished
signal _advance_requested

# テキスト表示設定
var text_speed: float = 0.05
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

# WAITING状態のクリック検出用
# _input() イベントベースではなく、_process() ポーリングベースで検出
# 幽霊クリック（_input に届くが物理的でないイベント）を防ぐため
var _waiting_mouse_was_down: bool = false    # 前フレームのマウスボタン状態
var _waiting_key_was_down: bool = false      # 前フレームのキーボード状態（Enter/Space）
var _waiting_needs_release: bool = false     # WAITING開始時にマウスが押されていたらリリースを待つ
var _waiting_frame_count: int = 0            # WAITING開始からのフレーム数
var _waiting_start_msec: int = 0             # WAITING開始時のミリ秒
const WAITING_PROTECTION_FRAMES: int = 5    # WAITING開始直後の保護フレーム数

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
	print("[TextDisplay] 準備完了")
	if has_node("TextLabel"):
		text_label = get_node("TextLabel")

func _input(event):
	# デバッグ: クリック/キーイベントのみログ出力（MouseMotionは除外）
	if event is InputEventMouseButton:
		var btn_info = "MouseButton(button=%s, pressed=%s)" % [event.button_index, event.pressed]
		var msec = Time.get_ticks_msec()
		print("[TextDisplay] _input() %s, state=%s, msec=%d" % [btn_info, State.keys()[_state], msec])
	elif event is InputEventKey:
		if event.pressed:  # キーはpressedのみログ
			var key_info = "Key(keycode=%s)" % event.keycode
			print("[TextDisplay] _input() %s, state=%s" % [key_info, State.keys()[_state]])
	
	# ANIMATING 状態のみ: クリックでアニメーション即完了
	# WAITING のクリック検出は _process() のポーリングで行う
	if _state == State.ANIMATING:
		var is_click = false
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				is_click = true
		elif event is InputEventKey:
			if (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE) and event.pressed:
				is_click = true
		
		if is_click:
			_complete_animation()
			accept_event()

func _process(delta):
	match _state:
		State.ANIMATING:
			_process_animation(delta)
		State.WAITING:
			_process_indicator_blink(delta)
			_process_waiting_click(delta)

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

## WAITING状態でのクリック検出（ポーリングベース）
## _input() ではなく _process() で物理的なマウス/キー状態をチェックする
func _process_waiting_click(_delta: float) -> void:
	_waiting_frame_count += 1
	
	var mouse_down = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var key_down = Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_SPACE)
	
	# 保護フレーム中は入力を無視（ただし状態は追跡する）
	if _waiting_frame_count <= WAITING_PROTECTION_FRAMES:
		# マウスの物理状態を追跡（保護中もリリースを検知）
		if not mouse_down:
			_waiting_needs_release = false
		_waiting_mouse_was_down = mouse_down
		_waiting_key_was_down = key_down
		return
	
	# リリース待ちの場合、マウスが離されるのを待つ
	if _waiting_needs_release:
		if not mouse_down:
			_waiting_needs_release = false
			print("[TextDisplay] _process_waiting_click() mouse released, now accepting clicks (frame %d)" % _waiting_frame_count)
		_waiting_mouse_was_down = mouse_down
		_waiting_key_was_down = key_down
		return
	
	# マウスの立ち上がりエッジ検出（押されていない → 押された）
	if mouse_down and not _waiting_mouse_was_down:
		var elapsed_msec = Time.get_ticks_msec() - _waiting_start_msec
		print("[TextDisplay] _process_waiting_click() CLICK at frame %d, elapsed %dms, FPS=%d (mouse)" % [_waiting_frame_count, elapsed_msec, Engine.get_frames_per_second()])
		_waiting_mouse_was_down = mouse_down
		_waiting_key_was_down = key_down
		_state = State.IDLE
		_advance_requested.emit()
		return
	
	# キーボードの立ち上がりエッジ検出（押されていない → 押された）
	if key_down and not _waiting_key_was_down:
		var elapsed_msec = Time.get_ticks_msec() - _waiting_start_msec
		print("[TextDisplay] _process_waiting_click() CLICK at frame %d, elapsed %dms (key)" % [_waiting_frame_count, elapsed_msec])
		_waiting_mouse_was_down = mouse_down
		_waiting_key_was_down = key_down
		_state = State.IDLE
		_advance_requested.emit()
		return
	
	_waiting_mouse_was_down = mouse_down
	_waiting_key_was_down = key_down

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
		print("[TextDisplay] show_text() new_page=true, calling _clear_internal()")
		_clear_internal()
		# 即座にANIMATING状態に設定して、IDLE状態の時間を最小化
		_state = State.ANIMATING
		print("[TextDisplay] show_text() new_page=true, state set to ANIMATING")

	_current_text = text
	_char_index = 0
	_displayed_text = ""
	_animation_timer = 0.0

	if instant_display:
		# 即座に全文表示して返る
		_displayed_text = _current_text
		_char_index = _current_text.length()
		_finalize_text()
		# instant_displayの場合も_animation_finishedを発行して、awaitが正しく解決されるようにする
		_state = State.IDLE
		_animation_finished.emit()
		return

	# アニメーション開始 → 完了まで待機
	# new_page=trueの場合は既にANIMATING状態に設定済み
	if not new_page:
		_state = State.ANIMATING
	await _animation_finished

## クリック待機（async: ユーザーのクリックまで待機）
func wait_for_advance() -> void:
	print("[TextDisplay] wait_for_advance() called, current state: %s" % State.keys()[_state])
	
	# 以前のシグナル接続をクリアするために、一度フレームを待つ
	# これにより、以前に発行された_advance_requestedシグナルがawaitに影響しないようにする
	await get_tree().process_frame
	
	_state = State.WAITING
	_indicator_visible = true
	_indicator_blink_timer = 0.0
	_update_display()
	
	# ポーリングベースのクリック検出を初期化
	_waiting_frame_count = 0
	_waiting_start_msec = Time.get_ticks_msec()
	var mouse_currently_down = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var key_currently_down = Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_SPACE)
	_waiting_mouse_was_down = mouse_currently_down
	_waiting_key_was_down = key_currently_down
	_waiting_needs_release = mouse_currently_down  # マウスが押されている場合はリリースを待つ
	
	print("[TextDisplay] wait_for_advance() WAITING, mouse_down=%s, needs_release=%s, msec=%d, FPS=%d" % [mouse_currently_down, _waiting_needs_release, _waiting_start_msec, Engine.get_frames_per_second()])
	
	await _advance_requested
	print("[TextDisplay] wait_for_advance() received _advance_requested")

## 強制完了（スキップモードから呼ばれる同期メソッド）
## ANIMATING → アニメーション完了、WAITING → クリック待機解除
func force_complete() -> void:
	print("[TextDisplay] force_complete() called, current state: %s" % State.keys()[_state])
	match _state:
		State.ANIMATING:
			_complete_animation()
		State.WAITING:
			print("[TextDisplay] force_complete() WAITING state: emitting _advance_requested")
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

	var display_text = ""

	match _state:
		State.ANIMATING:
			# アニメーション中: 過去テキスト + アニメーション中テキスト
			if _full_page_text != "":
				display_text = _full_page_text + "\n\n" + _displayed_text
			else:
				display_text = _displayed_text
		_:
			# IDLE / WAITING: 確定済みテキスト + インジケータ
			display_text = _full_page_text
			if _state == State.WAITING and _indicator_visible:
				if _go_next:
					display_text += " ▽"
				else:
					display_text += " ▼"

	text_label.text = display_text
