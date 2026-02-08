extends Node
class_name CommandExecutor

## コマンド実行クラス
## 各コマンドタイプの処理を実装

# UI コンポーネント（後で設定）
var text_display: TextDisplay
var background_display: BackgroundDisplay
var audio_manager: AudioManager
var choice_display: ChoiceDisplay
var subtitle_display: SubtitleDisplay

# シグナル
signal command_completed

# スキップコントローラ参照（スキップモード変更検知用）
var _skip_controller_ref: SkipController = null

func _ready():
	print("[CommandExecutor] 準備完了")

## スキップコントローラとの連携を設定
func connect_skip_controller(skip_controller: SkipController) -> void:
	if _skip_controller_ref:
		_skip_controller_ref.skip_mode_changed.disconnect(_on_skip_mode_changed)

	_skip_controller_ref = skip_controller
	skip_controller.skip_mode_changed.connect(_on_skip_mode_changed)

## スキップモード変更時のコールバック
func _on_skip_mode_changed(is_skipping: bool) -> void:
	if is_skipping and text_display:
		# スキップモードがONになったら、アニメーション中のテキストを即座に完了
		if text_display.is_animating:
			text_display.complete_animation()
		# 即座表示モードを有効化
		text_display.set_instant_display(true)
	elif text_display:
		# スキップモードがOFFになったら、即座表示モードを無効化
		text_display.set_instant_display(false)

## コマンドを実行
func execute(command: Dictionary, skip_controller: SkipController) -> void:
	if not command.has("type"):
		push_error("[CommandExecutor] コマンドにtypeがありません")
		return

	var command_type = command.type

	match command_type:
		"dialogue":
			await execute_dialogue(command, skip_controller)
		"background":
			await execute_background(command, skip_controller)
		"bgm":
			await execute_bgm(command, skip_controller)
		"sfx":
			await execute_sfx(command, skip_controller)
		"choice":
			# choice は ScenarioEngine で処理（フロー制御が必要なため）
			pass
		"load_scenario":
			# load_scenario は ScenarioEngine で処理
			pass
		"subtitle":
			await execute_subtitle(command, skip_controller)
		"index":
			# インデックスマーカーはスキップ
			pass
		"jump":
			# ジャンプは ScenarioEngine で処理
			pass
		"flashback_start":
			await execute_flashback_start(command, skip_controller)
		"flashback_end":
			await execute_flashback_end(command, skip_controller)
		_:
			push_warning("[CommandExecutor] 不明なコマンドタイプ: %s" % command_type)

	command_completed.emit()

## dialogue コマンドを実行
func execute_dialogue(command: Dictionary, skip_controller: SkipController) -> void:
	if not text_display:
		push_error("[CommandExecutor] TextDisplay が設定されていません")
		return

	var text = command.get("text", "")
	var new_page = command.get("new_page", false)
	var go_next = command.get("go_next", false)

	print("[CommandExecutor] dialogue: %s (new_page: %s, go_next: %s, skip: %s)" % [text, new_page, go_next, skip_controller.is_skipping])

	# スキップモード中は即座表示モードを有効化
	text_display.set_instant_display(skip_controller.is_skipping)

	# テキストを表示
	text_display.show_text(text, new_page, go_next)

	# スキップモード中でアニメーションが開始された場合、即座に完了
	if skip_controller.is_skipping and text_display.is_animating:
		text_display.complete_animation()

	# go_next の場合は入力待機をスキップ
	if go_next:
		return

	# 入力待機（スキップモード対応）
	await wait_for_input(skip_controller)

## background コマンドを実行
func execute_background(command: Dictionary, skip_controller: SkipController) -> void:
	var path = command.get("path", "")
	var effect = command.get("effect", "normal")

	print("[CommandExecutor] background: %s (effect: %s)" % [path, effect])

	if background_display:
		# スキップモード中はフェードなしで即座に変更
		var use_fade = not skip_controller.is_skipping
		await background_display.set_background(path, effect, use_fade)
	else:
		push_warning("[CommandExecutor] BackgroundDisplay が設定されていません")

## bgm コマンドを実行
func execute_bgm(command: Dictionary, skip_controller: SkipController) -> void:
	var path = command.get("path", "")

	print("[CommandExecutor] bgm: %s" % path)

	if audio_manager:
		# スキップモード中はフェードなしで即座に再生
		var use_fade = not skip_controller.is_skipping
		await audio_manager.play_bgm(path, use_fade)
	else:
		push_warning("[CommandExecutor] AudioManager が設定されていません")

## sfx コマンドを実行
func execute_sfx(command: Dictionary, skip_controller: SkipController) -> void:
	var path = command.get("path", "")

	print("[CommandExecutor] sfx: %s" % path)

	if audio_manager:
		audio_manager.play_sfx(path)
	else:
		push_warning("[CommandExecutor] AudioManager が設定されていません")

## 選択肢表示時にテキストを隠す
func hide_text_for_choice() -> void:
	if text_display:
		text_display.visible = false

## 選択肢終了後にテキストを再表示
func show_text_after_choice() -> void:
	if text_display:
		text_display.visible = true

## subtitle コマンドを実行
func execute_subtitle(command: Dictionary, skip_controller: SkipController) -> void:
	var text = command.get("text", "")
	var fade_time = command.get("fade_time", 1.0)
	var display_time = command.get("display_time", 2.0)

	print("[CommandExecutor] subtitle: %s" % text)

	# スキップモード中はサブタイトルをスキップ
	if skip_controller.is_skipping:
		return

	if subtitle_display:
		subtitle_display.show_subtitle(text, fade_time, display_time)
		await subtitle_display.subtitle_completed
	else:
		push_warning("[CommandExecutor] SubtitleDisplay が設定されていません")

## flashback_start コマンドを実行（回想モード開始）
func execute_flashback_start(command: Dictionary, skip_controller: SkipController) -> void:
	var effect = command.get("effect", "grayscale")

	print("[CommandExecutor] flashback_start (effect: %s)" % effect)

	if background_display:
		var use_fade = not skip_controller.is_skipping
		await background_display.set_effect(effect, use_fade)
	else:
		push_warning("[CommandExecutor] BackgroundDisplay が設定されていません")

## flashback_end コマンドを実行（回想モード終了）
func execute_flashback_end(command: Dictionary, skip_controller: SkipController) -> void:
	print("[CommandExecutor] flashback_end")

	if background_display:
		var use_fade = not skip_controller.is_skipping
		await background_display.set_effect("normal", use_fade)
	else:
		push_warning("[CommandExecutor] BackgroundDisplay が設定されていません")

## 入力待機（スキップモード対応）
func wait_for_input(skip_controller: SkipController) -> void:
	if skip_controller.is_skipping:
		# スキップモード: 短い待機時間
		await get_tree().create_timer(skip_controller.skip_wait_time).timeout
	else:
		# 通常モード: クリック待機
		if text_display:
			await text_display.clicked
		else:
			# text_display が未設定の場合は短い待機
			await get_tree().create_timer(0.1).timeout