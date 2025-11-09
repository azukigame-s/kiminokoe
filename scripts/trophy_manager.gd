# trophy_manager.gd
# トロフィー/称号システムのマネージャー
# オートロード（シングルトン）として設定することを推奨

extends Node

# シグナル定義
signal episode_cleared(episode_id)
signal trophy_unlocked(trophy_id)

# ログレベル定義
enum LogLevel {INFO, DEBUG, ERROR}

# セーブファイルのパス
const SAVE_FILE_PATH = "user://trophy_data.cfg"

# エピソードのクリア状態
var cleared_episodes: Dictionary = {}

# トロフィーの解除状態
var unlocked_trophies: Dictionary = {}

# エピソードIDの定義（シナリオファイル名から自動判定も可能）
var episode_ids: Array[String] = [
	"episode_01",
	"episode_02",
	"episode_03"
]

# エピソードごとの称号名の定義
var episode_trophy_names: Dictionary = {
	"episode_01": "エピソード#1 カード",
	"episode_02": "エピソード#2 海",
	"episode_03": "エピソード#3 バス停",
	"all_episodes_clear": "全エピソードクリア"
}

# トースト通知への参照
var toast_notification: Control = null

func _ready():
	_load_trophy_data()
	_setup_toast_notification()
	log_message("TrophyManager initialized", LogLevel.INFO)

# トースト通知のセットアップ
func _setup_toast_notification():
	# ノベルシステムシーンを探す（複数の方法で試行）
	var novel_system_scene = null
	
	# 方法1: シーンツリーから探す
	var root = get_tree().root
	for child in root.get_children():
		if child.name == "NovelSystem" or child.has_method("change_background"):
			novel_system_scene = child
			break
	
	# 方法2: まだ見つからない場合は、シーン変更後に再試行
	if not novel_system_scene:
		call_deferred("_setup_toast_notification")
		return
	
	# トースト通知が既に存在する場合は参照を取得
	if novel_system_scene.has_node("ToastNotification"):
		toast_notification = novel_system_scene.get_node("ToastNotification")
		log_message("Toast notification already exists", LogLevel.DEBUG)
		return
	
	# トースト通知を作成
	toast_notification = Control.new()
	toast_notification.set_script(load("res://scripts/toast_notification.gd"))
	toast_notification.name = "ToastNotification"
	novel_system_scene.add_child(toast_notification)
	log_message("Toast notification added to novel system", LogLevel.DEBUG)

# エピソードがクリア済みかどうかを判定
func is_episode_cleared(episode_id: String) -> bool:
	return cleared_episodes.get(episode_id, false)

# エピソードをクリア済みとして記録
func clear_episode(episode_id: String):
	if not is_episode_cleared(episode_id):
		cleared_episodes[episode_id] = true
		_save_trophy_data()
		episode_cleared.emit(episode_id)
		log_message("Episode cleared: " + episode_id, LogLevel.INFO)
		
		# エピソードクリアに応じたトロフィーのチェック
		_check_episode_trophies(episode_id)
	else:
		log_message("Episode already cleared: " + episode_id, LogLevel.DEBUG)

# シナリオファイル名からエピソードIDを抽出
func extract_episode_id(scenario_path: String) -> String:
	# パスからファイル名を取得（例: "res://scenarios/episode_01.json" → "episode_01"）
	var file_name = scenario_path.get_file()
	# 拡張子を削除
	if file_name.ends_with(".json"):
		file_name = file_name.substr(0, file_name.length() - 5)
	
	# episode_で始まる場合はエピソードIDとして扱う
	if file_name.begins_with("episode_"):
		return file_name
	
	# エピソードIDとして認識できない場合は空文字列を返す
	return ""

# トロフィーが解除済みかどうかを判定
func is_trophy_unlocked(trophy_id: String) -> bool:
	return unlocked_trophies.get(trophy_id, false)

# トロフィーを解除
func unlock_trophy(trophy_id: String, trophy_name: String = ""):
	if not is_trophy_unlocked(trophy_id):
		unlocked_trophies[trophy_id] = {
			"unlocked": true,
			"unlocked_at": Time.get_unix_time_from_system(),
			"name": trophy_name
		}
		_save_trophy_data()
		trophy_unlocked.emit(trophy_id)
		log_message("Trophy unlocked: " + trophy_id + " (" + trophy_name + ")", LogLevel.INFO)
		
		# 初回取得時にトースト通知を表示
		_show_trophy_toast(trophy_name)

# エピソードクリアに応じたトロフィーのチェック
func _check_episode_trophies(episode_id: String):
	# エピソードごとのトロフィーIDを生成
	var trophy_id = episode_id + "_clear"
	var trophy_name = episode_trophy_names.get(episode_id, "エピソードクリア")
	
	unlock_trophy(trophy_id, trophy_name)
	
	# 全エピソードクリアのチェック
	if _are_all_episodes_cleared():
		unlock_trophy("all_episodes_clear", episode_trophy_names.get("all_episodes_clear", "全エピソードクリア"))

# 全エピソードがクリア済みかどうかを判定
func _are_all_episodes_cleared() -> bool:
	for episode_id in episode_ids:
		if not is_episode_cleared(episode_id):
			return false
	return true

# クリア済みエピソードの数を取得
func get_cleared_episode_count() -> int:
	var count = 0
	for episode_id in episode_ids:
		if is_episode_cleared(episode_id):
			count += 1
	return count

# 全エピソード数を取得
func get_total_episode_count() -> int:
	return episode_ids.size()

# トロフィーデータの保存
func _save_trophy_data():
	var config = ConfigFile.new()
	
	# エピソードのクリア状態を保存
	for episode_id in cleared_episodes.keys():
		config.set_value("episodes", episode_id, cleared_episodes[episode_id])
	
	# トロフィーの解除状態を保存
	for trophy_id in unlocked_trophies.keys():
		config.set_value("trophies", trophy_id, unlocked_trophies[trophy_id])
	
	var error = config.save(SAVE_FILE_PATH)
	if error == OK:
		log_message("Trophy data saved successfully", LogLevel.DEBUG)
	else:
		log_message("Failed to save trophy data: " + str(error), LogLevel.ERROR)

# トロフィーデータの読み込み
func _load_trophy_data():
	var config = ConfigFile.new()
	var error = config.load(SAVE_FILE_PATH)
	
	if error == OK:
		# エピソードのクリア状態を読み込み
		if config.has_section("episodes"):
			for episode_id in config.get_section_keys("episodes"):
				cleared_episodes[episode_id] = config.get_value("episodes", episode_id, false)
		
		# トロフィーの解除状態を読み込み
		if config.has_section("trophies"):
			for trophy_id in config.get_section_keys("trophies"):
				unlocked_trophies[trophy_id] = config.get_value("trophies", trophy_id, {})
		
		log_message("Trophy data loaded successfully", LogLevel.DEBUG)
	else:
		log_message("Trophy data file not found, using defaults", LogLevel.INFO)

# トロフィー取得時のトースト通知を表示
func _show_trophy_toast(trophy_name: String):
	# トースト通知への参照を取得（確実に取得するため、毎回探す）
	var toast_node = null
	
	# ノベルシステムシーンを探す
	var root = get_tree().root
	for child in root.get_children():
		if child.name == "NovelSystem" or child.has_method("change_background"):
			# トースト通知が既に存在する場合は取得（シーンファイルに追加されている場合）
			if child.has_node("toast_notification"):
				toast_node = child.get_node("toast_notification")
				break
			# 後方互換性のため、大文字小文字を区別しない検索も試行
			elif child.has_node("ToastNotification"):
				toast_node = child.get_node("ToastNotification")
				break
	
	# トースト通知が利用可能な場合のみ表示
	if toast_node and toast_node.has_method("show_toast"):
		var toast_text = "🏆 " + trophy_name + " を獲得しました！"
		toast_node.show_toast(toast_text)
		log_message("Showing trophy toast: " + trophy_name, LogLevel.DEBUG)
		# 参照を保存
		toast_notification = toast_node
	else:
		log_message("Toast notification not available (toast_node: " + str(toast_node) + ")", LogLevel.DEBUG)

# エピソードの称号名を取得
func get_episode_trophy_name(episode_id: String) -> String:
	return episode_trophy_names.get(episode_id, "エピソードクリア")

# エピソードの称号名を設定
func set_episode_trophy_name(episode_id: String, trophy_name: String):
	episode_trophy_names[episode_id] = trophy_name
	log_message("Set trophy name for " + episode_id + ": " + trophy_name, LogLevel.DEBUG)

# トロフィーデータのリセット（デバッグ用）
func reset_trophy_data():
	cleared_episodes.clear()
	unlocked_trophies.clear()
	_save_trophy_data()
	log_message("Trophy data reset", LogLevel.INFO)

# 現在のトロフィー獲得状況を表示（デバッグ用）
func print_trophy_status():
	log_message("=== Trophy Status ===", LogLevel.INFO)
	log_message("Episodes cleared:", LogLevel.INFO)
	for episode_id in episode_ids:
		var cleared = is_episode_cleared(episode_id)
		var status = "✓" if cleared else "✗"
		log_message("  " + status + " " + episode_id + " (" + get_episode_trophy_name(episode_id) + ")", LogLevel.INFO)
	
	log_message("Trophies unlocked:", LogLevel.INFO)
	for trophy_id in unlocked_trophies.keys():
		var trophy_data = unlocked_trophies[trophy_id]
		var trophy_name = trophy_data.get("name", "Unknown")
		var unlocked_at = trophy_data.get("unlocked_at", 0)
		log_message("  ✓ " + trophy_id + ": " + trophy_name, LogLevel.INFO)
	
	log_message("Progress: " + str(get_cleared_episode_count()) + " / " + str(get_total_episode_count()) + " episodes", LogLevel.INFO)
	log_message("Save file: " + SAVE_FILE_PATH, LogLevel.INFO)
	log_message("===================", LogLevel.INFO)

# セーブファイルのパスを取得（OSの実際のパス）
func get_save_file_path() -> String:
	return OS.get_user_data_dir() + "/" + SAVE_FILE_PATH.trim_prefix("user://")

# ログメッセージの出力
func log_message(message: String, level: LogLevel = LogLevel.INFO):
	var prefix = ""
	match level:
		LogLevel.INFO:
			prefix = "[INFO] "
		LogLevel.DEBUG:
			prefix = "[DEBUG] "
		LogLevel.ERROR:
			prefix = "[ERROR] "
	
	print(prefix + "[TrophyManager] " + message)

