extends Node
class_name CommandExecutor

## コマンド実行クラス
## 各コマンドタイプの処理を実装

# UI コンポーネント（後で設定）
var text_display: TextDisplay
var background_display: Control
var audio_manager: Node

# シグナル
signal command_completed

func _ready():
	print("[CommandExecutor] Ready")

## コマンドを実行
func execute(command: Dictionary, skip_controller: SkipController) -> void:
	if not command.has("type"):
		push_error("[CommandExecutor] Command has no type")
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
			await execute_choice(command, skip_controller)
		"load_scenario":
			# load_scenario は ScenarioEngine で処理
			pass
		"subtitle":
			await execute_subtitle(command, skip_controller)
		_:
			push_warning("[CommandExecutor] Unknown command type: %s" % command_type)

	command_completed.emit()

## dialogue コマンドを実行
func execute_dialogue(command: Dictionary, skip_controller: SkipController) -> void:
	if not text_display:
		push_error("[CommandExecutor] TextDisplay not set")
		return

	var text = command.get("text", "")
	var new_page = command.get("new_page", false)

	print("[CommandExecutor] Dialogue: %s (new_page: %s)" % [text, new_page])

	# 新しいページの場合はクリア
	if new_page:
		text_display.clear()

	# テキストを表示
	text_display.show_text(text)

	# 入力待機（スキップモード対応）
	await wait_for_input(skip_controller)

## background コマンドを実行
func execute_background(command: Dictionary, skip_controller: SkipController) -> void:
	if not background_display:
		push_warning("[CommandExecutor] BackgroundDisplay not set")
		return

	var path = command.get("path", "")
	var effect = command.get("effect", "normal")

	print("[CommandExecutor] Background: %s (effect: %s)" % [path, effect])

	# TODO: 背景表示の実装
	# background_display.set_background(path, effect)

## bgm コマンドを実行
func execute_bgm(command: Dictionary, skip_controller: SkipController) -> void:
	var path = command.get("path", "")

	print("[CommandExecutor] BGM: %s" % path)

	# TODO: BGM再生の実装
	# audio_manager.play_bgm(path)

## sfx コマンドを実行
func execute_sfx(command: Dictionary, skip_controller: SkipController) -> void:
	var path = command.get("path", "")

	print("[CommandExecutor] SFX: %s" % path)

	# TODO: SFX再生の実装
	# audio_manager.play_sfx(path)

## choice コマンドを実行
func execute_choice(command: Dictionary, skip_controller: SkipController) -> void:
	print("[CommandExecutor] Choice")

	# TODO: 選択肢表示の実装
	# choice_display.show_choices(command.choices)
	# await choice_display.choice_selected

## subtitle コマンドを実行
func execute_subtitle(command: Dictionary, skip_controller: SkipController) -> void:
	var text = command.get("text", "")

	print("[CommandExecutor] Subtitle: %s" % text)

	# TODO: サブタイトル表示の実装
	# subtitle_display.show_subtitle(text)
	# await subtitle_display.subtitle_completed

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
