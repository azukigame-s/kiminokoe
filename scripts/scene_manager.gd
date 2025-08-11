# scene_manager.gd
# 保存先: res://scripts/scene_manager.gd
# オートロード（シングルトン）として設定する

extends Node

# シーン定数
const TITLE_SCENE = "res://scenes/title_scene.tscn"
const GAME_SCENE = "res://scenes/novel_system.tscn"  # 既存のノベルシステム
const SETTINGS_SCENE = "res://scenes/settings_scene.tscn"

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
	
	# ゲーム開始時はタイトルシーンへ
	call_deferred("change_scene", TITLE_SCENE)

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
	
	scene_transition_in_progress = true
	var from_scene = current_scene_name
	current_scene_name = scene_path
	
	scene_change_started.emit(from_scene, scene_path)
	print("[SceneManager] Changing scene from " + from_scene + " to " + scene_path)
	
	if use_fade:
		await _fade_out()
	
	# シーン変更実行
	get_tree().change_scene_to_file(scene_path)
	
	if use_fade:
		await _fade_in()
	
	scene_transition_in_progress = false
	scene_changed.emit(current_scene_name)
	print("[SceneManager] Scene change completed: " + current_scene_name)

# フェードアウト
func _fade_out():
	fade_overlay.modulate.a = 0.0
	fade_overlay.visible = true
	
	var tween = create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 1.0, fade_duration)
	await tween.finished

# フェードイン
func _fade_in():
	fade_overlay.modulate.a = 1.0
	fade_overlay.visible = true
	
	var tween = create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 0.0, fade_duration)
	await tween.finished
	
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

# 設定シーンへ
func goto_settings():
	change_scene(SETTINGS_SCENE)

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
