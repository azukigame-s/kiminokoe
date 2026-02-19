# scene_manager.gd
# 保存先: res://scripts/scene_manager.gd
# オートロード（シングルトン）として設定する

extends Node

# シーン定数
const SPLASH_SCENE = "res://scenes/splash_scene.tscn"
const TITLE_SCENE = "res://scenes/title_scene.tscn"
const GAME_SCENE = "res://scenes/game_scene.tscn"
const SETTINGS_SCENE = "res://scenes/settings_scene.tscn"
const TROPHY_SCENE = "res://scenes/trophy_screen.tscn"
const NAME_INPUT_SCENE = "res://scenes/name_input_scene.tscn"
const SAVE_INFO_SCENE = "res://scenes/save_info_scene.tscn"

# セーブデータ
const SAVE_FILE_PATH = "user://save_data.cfg"

# 主人公名（デフォルト: コウ）
var protagonist_name: String = "コウ"

# ゲーム開始モード（"new_game" / "continue"）
var game_start_mode: String = "new_game"

# プレイ時間（秒）
var play_time: float = 0.0

# 設定画面からの戻り先（"title" or "game"）
var settings_return_to: String = "title"

# シグナル定義
signal scene_changed(scene_name)
signal scene_change_started(from_scene, to_scene)

# 現在のシーン管理
var current_scene_name: String = ""
var scene_transition_in_progress: bool = false

# フェード効果用
var fade_overlay: ColorRect
var fade_duration: float = 0.5

func _ready():
	# 保存済み設定の読み込みと適用
	_load_and_apply_settings()

	# フェードオーバーレイの作成
	_create_fade_overlay()

	# 現在のシーンがテストシーンの場合はスキップ
	await get_tree().process_frame
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.name == "TestScene":
		print("[SceneManager] Test scene detected, skipping auto scene change")
		return

	# ゲーム開始時はスプラッシュ画面へ（フェード無し）
	change_scene_instant(SPLASH_SCENE)

# フェードオーバーレイの作成
func _create_fade_overlay():
	fade_overlay = ColorRect.new()
	fade_overlay.name = "FadeOverlay"
	fade_overlay.color = Color.BLACK
	fade_overlay.anchor_left = 0.0
	fade_overlay.anchor_top = 0.0
	fade_overlay.anchor_right = 1.0
	fade_overlay.anchor_bottom = 1.0
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_overlay.modulate.a = 0.0
	
	# 最前面に配置するためにCanvasLayerに追加
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "FadeLayer"
	canvas_layer.layer = 1000  # 最前面
	canvas_layer.add_child(fade_overlay)
	add_child(canvas_layer)

# シーン変更（フェード効果付き）
func change_scene(scene_path: String, use_fade: bool = true):
	if scene_transition_in_progress:
		print("[SceneManager] Scene transition already in progress")
		return
	
	# シーンツリーが利用可能かチェック
	if not is_inside_tree():
		print("[SceneManager] Not inside tree, deferring scene change")
		call_deferred("change_scene", scene_path, use_fade)
		return
	
	scene_transition_in_progress = true
	var from_scene = current_scene_name
	current_scene_name = scene_path
	
	scene_change_started.emit(from_scene, scene_path)
	print("[SceneManager] Changing scene from " + from_scene + " to " + scene_path)
	
	if use_fade:
		await _fade_out()
	
	# シーン変更実行
	var error = get_tree().change_scene_to_file(scene_path)
	if error != OK:
		print("[SceneManager] ERROR: Failed to change scene: " + str(error))
		scene_transition_in_progress = false
		return
	
	# シーン変更後、新しいシーンツリーが構築されるまで待つ
	await get_tree().process_frame
	
	if use_fade:
		await _fade_in()
	
	scene_transition_in_progress = false
	scene_changed.emit(current_scene_name)
	print("[SceneManager] Scene change completed: " + current_scene_name)

# フェードアウト
func _fade_out():
	if not is_inside_tree() or not fade_overlay:
		print("[SceneManager] Cannot fade out: not ready")
		return
	
	fade_overlay.modulate.a = 0.0
	fade_overlay.visible = true
	
	var tween = create_tween()
	if tween:
		tween.tween_property(fade_overlay, "modulate:a", 1.0, fade_duration)
		await tween.finished
	else:
		print("[SceneManager] WARNING: Failed to create tween for fade out")

# フェードイン
func _fade_in():
	if not is_inside_tree() or not fade_overlay:
		print("[SceneManager] Cannot fade in: not ready")
		return
	
	fade_overlay.modulate.a = 1.0
	fade_overlay.visible = true
	
	var tween = create_tween()
	if tween:
		tween.tween_property(fade_overlay, "modulate:a", 0.0, fade_duration)
		await tween.finished
		fade_overlay.visible = false
	else:
		print("[SceneManager] WARNING: Failed to create tween for fade in")
		fade_overlay.visible = false

# 即座にシーン変更（フェード無し）
func change_scene_instant(scene_path: String):
	change_scene(scene_path, false)

# タイトルシーンへ
func goto_title():
	change_scene(TITLE_SCENE)

# ゲームシーンへ（ノベルシステム）
func goto_game():
	change_scene(GAME_SCENE)

# 名前入力画面へ
func goto_name_input():
	change_scene(NAME_INPUT_SCENE)

# 設定シーンへ（return_to: 戻り先 "title" or "game"）
func goto_settings(return_to: String = "title"):
	settings_return_to = return_to
	change_scene(SETTINGS_SCENE)

# 設定画面からの戻り
func goto_return_from_settings():
	if settings_return_to == "game":
		game_start_mode = "continue"
		goto_game()
	else:
		goto_title()

# トロフィー画面へ
func goto_trophy():
	change_scene(TROPHY_SCENE)

# セーブ情報画面へ
func goto_save_info():
	change_scene(SAVE_INFO_SCENE)

# ゲーム終了
func quit_game():
	print("[SceneManager] Quitting game")
	get_tree().quit()

# 現在のシーン名を取得
func get_current_scene_name() -> String:
	return current_scene_name

# シーン遷移中かどうか
func is_transitioning() -> bool:
	return scene_transition_in_progress

# セーブデータが存在するか
func has_save_data() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)

# オートセーブ
func auto_save(save_state: Dictionary) -> void:
	var config = ConfigFile.new()
	config.set_value("save", "protagonist_name", protagonist_name)
	config.set_value("save", "scenario_path", save_state.get("scenario_path", ""))
	config.set_value("save", "index", save_state.get("index", 0))
	config.set_value("save", "stack", save_state.get("stack", []))
	config.set_value("save", "background_path", save_state.get("background_path", ""))
	config.set_value("save", "bgm_path", save_state.get("bgm_path", ""))
	config.set_value("save", "effect", save_state.get("effect", "normal"))
	config.set_value("save", "backlog", save_state.get("backlog", []))
	config.set_value("save", "play_time", save_state.get("play_time", 0.0))
	var error = config.save(SAVE_FILE_PATH)
	if error != OK:
		push_error("[SceneManager] Failed to auto-save: %s" % str(error))

# セーブデータの読み込み
func load_save_data() -> Dictionary:
	var config = ConfigFile.new()
	var error = config.load(SAVE_FILE_PATH)
	if error != OK:
		push_error("[SceneManager] Failed to load save data: %s" % str(error))
		return {}
	return {
		"protagonist_name": config.get_value("save", "protagonist_name", "コウ"),
		"scenario_path": config.get_value("save", "scenario_path", ""),
		"index": config.get_value("save", "index", 0),
		"stack": config.get_value("save", "stack", []),
		"background_path": config.get_value("save", "background_path", ""),
		"bgm_path": config.get_value("save", "bgm_path", ""),
		"effect": config.get_value("save", "effect", "normal"),
		"backlog": config.get_value("save", "backlog", []),
		"play_time": config.get_value("save", "play_time", 0.0),
	}

# つづきからはじめるが可能か（シナリオ進行データがあるか）
func can_continue() -> bool:
	if not has_save_data():
		return false
	var data = load_save_data()
	var scenario_path = data.get("scenario_path", "")
	return scenario_path != ""

# セーブデータの全削除
func clear_save_data() -> void:
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(
			OS.get_user_data_dir() + "/" + SAVE_FILE_PATH.trim_prefix("user://")
		)

# シナリオ進行のみクリア（名前・プレイ時間・軌跡は保持）
func clear_scenario_progress() -> void:
	if not has_save_data():
		return
	var config = ConfigFile.new()
	var error = config.load(SAVE_FILE_PATH)
	if error != OK:
		return
	# シナリオ関連キーを削除
	for key in ["scenario_path", "index", "stack", "background_path", "bgm_path", "effect", "backlog"]:
		if config.has_section_key("save", key):
			config.set_value("save", key, null)
	config.save(SAVE_FILE_PATH)

# 保存済み設定の読み込みと適用（起動時に呼ばれる）
func _load_and_apply_settings() -> void:
	var config = ConfigFile.new()
	var error = config.load("user://settings.cfg")
	if error != OK:
		return

	# テキスト速度
	if config.has_section_key("settings", "text_speed"):
		var text_speed = config.get_value("settings", "text_speed")
		ProjectSettings.set_setting("visual_novel/text_speed", text_speed)

	# マスター音量
	if config.has_section_key("settings", "master_volume"):
		var master_volume = config.get_value("settings", "master_volume")
		AudioServer.set_bus_volume_db(
			AudioServer.get_bus_index("Master"),
			linear_to_db(master_volume))

	# ウィンドウモード
	var window_mode = config.get_value("settings", "window_mode", "")
	# 互換性: 旧fullscreen設定
	if config.has_section_key("settings", "fullscreen"):
		var old_fullscreen = config.get_value("settings", "fullscreen")
		if old_fullscreen is bool and window_mode == "":
			window_mode = "fullscreen" if old_fullscreen else "1280x720"
	# 互換性: windowed → 1280x720
	if window_mode == "windowed":
		window_mode = "1280x720"
	if window_mode == "fullscreen":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif window_mode != "":
		var parts = window_mode.split("x")
		if parts.size() == 2:
			var width = int(parts[0])
			var height = int(parts[1])
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(Vector2i(width, height))
			var screen_size = DisplayServer.screen_get_size()
			var window_pos = (screen_size - Vector2i(width, height)) / 2
			DisplayServer.window_set_position(window_pos)

	print("[SceneManager] Settings loaded and applied")
