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
var poem_display  # PoemDisplay

# シグナル
signal command_completed

# スキップコントローラ参照（スキップモード変更検知用）
var _skip_controller_ref: SkipController = null

# バックログマネージャ参照
var backlog_manager: BacklogManager

func _ready():
	pass

## スキップコントローラとの連携を設定
func connect_skip_controller(skip_controller: SkipController) -> void:
	if _skip_controller_ref:
		_skip_controller_ref.skip_mode_changed.disconnect(_on_skip_mode_changed)

	_skip_controller_ref = skip_controller
	skip_controller.skip_mode_changed.connect(_on_skip_mode_changed)

## スキップモード変更時のコールバック
func _on_skip_mode_changed(is_skipping: bool) -> void:
	if not text_display:
		return

	if is_skipping:
		# スキップON: 現在の状態（アニメーション or クリック待機）を強制完了
		text_display.force_complete()
		text_display.set_instant_display(true)
	else:
		# スキップOFF: 即座表示モードを無効化
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
			execute_sfx(command, skip_controller)
		"choice":
			# choice は ScenarioEngine で処理（フロー制御が必要なため）
			pass
		"load_scenario":
			# load_scenario は ScenarioEngine で処理
			pass
		"subtitle":
			await execute_subtitle(command, skip_controller)
		"poem":
			await execute_poem(command, skip_controller)
		"visit_location":
			execute_visit_location(command)
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
	# 主人公名プレースホルダーの置換
	var _scene_mgr = get_node_or_null("/root/SceneManager")
	if _scene_mgr:
		text = text.replace("[主人公]", _scene_mgr.protagonist_name)
	var new_page = command.get("new_page", false)
	var go_next = command.get("go_next", false)

	text_display.set_instant_display(skip_controller.is_skipping)
	text_display.set_go_next(go_next)

	# テキスト表示（アニメーション完了まで待機）
	await text_display.show_text(text, new_page)

	# バックログに記録
	if backlog_manager:
		backlog_manager.add_entry(text)

	# go_next フラグはインディケーター制御のみに使用（text_display.set_go_next()で設定済み）
	# クリック待機は go_next に関わらず常に行う

	# クリック待機
	if skip_controller.is_skipping:
		await get_tree().create_timer(skip_controller.skip_wait_time).timeout
	else:
		await text_display.wait_for_advance()

## background コマンドを実行
func execute_background(command: Dictionary, skip_controller: SkipController) -> void:
	var path = command.get("path", "")
	var effect = command.get("effect", "normal")

	if background_display:
		var use_fade = not skip_controller.is_skipping
		await background_display.set_background(path, effect, use_fade)
	else:
		push_warning("[CommandExecutor] BackgroundDisplay が設定されていません")

## bgm コマンドを実行（フェードはバックグラウンドで実行、シナリオはブロックしない）
func execute_bgm(command: Dictionary, skip_controller: SkipController) -> void:
	# "name" キー（エイリアス）優先、なければ "path" キー（後方互換）
	var path: String
	if command.has("name"):
		path = audio_manager.resolve_bgm_alias(command.get("name", "")) if audio_manager else ""
	else:
		path = command.get("path", "")

	if audio_manager:
		if path.is_empty():
			var use_fade = not skip_controller.is_skipping
			audio_manager.stop_bgm(use_fade)
		else:
			var use_fade = not skip_controller.is_skipping
			audio_manager.play_bgm(path, use_fade)
	else:
		push_warning("[CommandExecutor] AudioManager が設定されていません")

## sfx コマンドを実行
func execute_sfx(command: Dictionary, _skip_controller: SkipController) -> void:
	var path = command.get("path", "")

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
	var next_bg = command.get("next_background", "")

	# スキップモード中はサブタイトルをスキップ
	if skip_controller.is_skipping:
		# スキップ中でも背景は即時切り替え
		if not next_bg.is_empty() and background_display:
			await background_display.set_background(next_bg, "normal", false)
		return

	# サブタイトル表示前にテキストをクリア（終了後に前のテキストがちらつくのを防止）
	if text_display:
		text_display.clear()

	if subtitle_display:
		# フェードアウト開始時に背景を即時切り替え（旧背景がちらつくのを防止）
		if not next_bg.is_empty() and background_display:
			subtitle_display.subtitle_fadeout_started.connect(
				func(): background_display.set_background(next_bg, "normal", false),
				CONNECT_ONE_SHOT
			)
		subtitle_display.show_subtitle(text, fade_time, display_time)
		await subtitle_display.subtitle_completed
	else:
		push_warning("[CommandExecutor] SubtitleDisplay が設定されていません")

## poem コマンドを実行（童歌・詩のフルスクリーン表示）
func execute_poem(command: Dictionary, skip_controller: SkipController) -> void:
	# スキップモード中は詩表示をスキップ
	if skip_controller.is_skipping:
		return

	var lines: Array = command.get("lines", [])
	if lines.is_empty():
		return

	if poem_display:
		poem_display.show_poem(lines)
		await poem_display.poem_completed
		# 童歌を最後まで聴いた場合にトロフィーを付与（スキップ時はここに到達しない）
		TrophyManager.unlock_trophy("warabeuta", "童歌")
		# 体験版コンプリートチェック（全条件が揃っていればこの瞬間に付与）
		TrophyManager.check_demo_complete(SceneManager.play_time)
	else:
		push_warning("[CommandExecutor] PoemDisplay が設定されていません")

## visit_location コマンドを実行（場所訪問記録 → トロフィーチェック）
func execute_visit_location(command: Dictionary) -> void:
	var location_id = command.get("id", "")
	if location_id.is_empty():
		push_warning("[CommandExecutor] visit_location に id がありません")
		return
	var trophy_manager = get_node_or_null("/root/TrophyManager")
	if trophy_manager:
		trophy_manager.visit_location(location_id)
	else:
		push_warning("[CommandExecutor] TrophyManager が見つかりません")

## flashback_start コマンドを実行（回想モード開始）
func execute_flashback_start(command: Dictionary, skip_controller: SkipController) -> void:
	var effect = command.get("effect", "grayscale")
	var gradual = command.get("gradual", false)
	var duration = command.get("duration", 4.5)

	if background_display:
		if gradual and not skip_controller.is_skipping:
			background_display.begin_gradual_effect(effect, duration)
		else:
			var use_fade = not skip_controller.is_skipping
			await background_display.set_effect(effect, use_fade)
	else:
		push_warning("[CommandExecutor] BackgroundDisplay が設定されていません")

## flashback_end コマンドを実行（回想モード終了）
func execute_flashback_end(command: Dictionary, skip_controller: SkipController) -> void:
	var gradual = command.get("gradual", false)
	var duration = command.get("duration", 4.5)

	if background_display:
		if gradual and not skip_controller.is_skipping:
			background_display.begin_gradual_effect("normal", duration)
		else:
			var use_fade = not skip_controller.is_skipping
			await background_display.set_effect("normal", use_fade)
	else:
		push_warning("[CommandExecutor] BackgroundDisplay が設定されていません")