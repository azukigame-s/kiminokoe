# scene_manager.gd
# 保存先: res://scripts/scene_manager.gd
# オートロード（シングルトン）として設定する

extends Node

# シーン定数
const TITLE_SCENE = "res://scenes/title_scene.tscn"
const GAME_SCENE = "res://scenes/game_scene.tscn"
const SETTINGS_SCENE = "res://scenes/settings_scene.tscn"
const TROPHY_SCENE = "res://scenes/trophy_screen.tscn"
const NAME_INPUT_SCENE = "res://scenes/name_input_scene.tscn"

# セーブデータ
const SAVE_FILE_PATH = "user://save_data.cfg"

# 主人公名（デフォルト: コウ）
var protagonist_name: String = "コウ"

# ゲーム開始モード（"new_game" / "continue"）
var game_start_mode: String = "new_game"

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
	# フェードオーバーレイの作成
	_create_fade_overlay()

	# 現在のシーンがテストシーンの場合はスキップ
	await get_tree().process_frame
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.name == "TestScene":
		print("[SceneManager] Test scene detected, skipping auto scene change")
		return

	# ゲーム開始時はタイトルシーンへ（フェード無し、遅延実行）
	change_scene_instant(TITLE_SCENE)

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

# 設定シーンへ
func goto_settings():
	change_scene(SETTINGS_SCENE)

# トロフィー画面へ
func goto_trophy():
	change_scene(TROPHY_SCENE)

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
	}

# セーブデータの削除
func clear_save_data() -> void:
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(
			OS.get_user_data_dir() + "/" + SAVE_FILE_PATH.trim_prefix("user://")
		)
