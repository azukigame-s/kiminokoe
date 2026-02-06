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

# エピソードIDの定義
var episode_ids: Array[String] = [
	"ep_1",   # カード
	"ep_2",   # 海
	"ep_3",   # バス停
	"ep_4",   # キャッチボール
	"ep_5",   # 捨て猫
	"ep_6",   # 沢蟹
	"ep_7",   # 神社
]

# エピソードごとの称号名の定義
var episode_trophy_names: Dictionary = {
	"ep_1": "カード",
	"ep_2": "海",
	"ep_3": "バス停",
	"ep_4": "キャッチボール",
	"ep_5": "捨て猫",
	"ep_6": "沢蟹",
	"ep_7": "神社",
	"all_episodes_clear": "全エピソードクリア"
}

# シークレットトロフィーの定義
var secret_trophy_ids: Array[String] = [
	"secret_base",    # 秘密基地
	"futako_jizo",    # ふたこじぞう（全地蔵発見）
	"takiba",         # 焚き場
	"kiminokoe",      # キミノコエ（トゥルーエンド）
	"iro_story",      # イロの想い（マル秘ストーリー）
]

# シークレットトロフィーの名称
var secret_trophy_names: Dictionary = {
	"secret_base": "秘密基地",
	"futako_jizo": "ふたこじぞう",
	"takiba": "焚き場",
	"kiminokoe": "キミノコエ",
	"iro_story": "イロの想い",
}

# 訪問済み場所（シークレットトロフィー用）
var visited_locations: Dictionary = {}

# トースト通知への参照
var toast_notification: Control = null

func _ready():
	# オートロードの場合は_ready()が呼ばれた時点で既にシーンツリーに追加されている
	# ただし、ファイルシステムへのアクセスは安全に実行できる
	_load_trophy_data()
	# トースト通知のセットアップは遅延実行（シーンが読み込まれた後に実行）
	# 最初のシーンが読み込まれるまで待つため、複数フレーム待つ
	call_deferred("_delayed_setup")
	log_message("TrophyManager initialized", LogLevel.INFO)

# 遅延セットアップ（複数フレーム待ってから実行）
func _delayed_setup():
	await get_tree().process_frame
	await get_tree().process_frame
	_setup_toast_notification()

# トースト通知のセットアップ
func _setup_toast_notification():
	# シーンツリーが利用可能かチェック
	if not is_inside_tree():
		call_deferred("_setup_toast_notification")
		return
	
	# ノベルシステムシーンを探す（複数の方法で試行）
	var novel_system_scene = null
	
	# 方法1: シーンツリーから探す
	var root = get_tree().root
	if root:
		for child in root.get_children():
			if child and (child.name == "NovelSystem" or child.has_method("change_background")):
				novel_system_scene = child
				break
	
	# 方法2: まだ見つからない場合は、シーン変更後に再試行
	if not novel_system_scene:
		# タイトルシーンが読み込まれている場合は、ノベルシステムシーンはまだ存在しない
		log_message("NovelSystem scene not found yet, will retry when needed", LogLevel.DEBUG)
		return
	
	# トースト通知が既に存在する場合は参照を取得
	if novel_system_scene.has_node("toast_notification"):
		toast_notification = novel_system_scene.get_node("toast_notification")
		log_message("Toast notification already exists", LogLevel.DEBUG)
		return
	elif novel_system_scene.has_node("ToastNotification"):
		toast_notification = novel_system_scene.get_node("ToastNotification")
		log_message("Toast notification already exists (capitalized)", LogLevel.DEBUG)
		return
	
	# トースト通知はシーンファイルに追加されているため、ここでは作成しない
	log_message("Toast notification will be found when needed", LogLevel.DEBUG)

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
	# パスからファイル名を取得（例: "res://scenarios/episodes/ep_01.json" → "ep_01"）
	var file_name = scenario_path.get_file()
	# 拡張子を削除
	if file_name.ends_with(".json"):
		file_name = file_name.substr(0, file_name.length() - 5)

	# ep_で始まる場合はエピソードIDとして扱う
	if file_name.begins_with("ep_"):
		return file_name

	# エピソードIDとして認識できない場合は空文字列を返す
	return ""

## 場所を訪問済みとして記録
func visit_location(location_id: String) -> void:
	if not visited_locations.get(location_id, false):
		visited_locations[location_id] = true
		_save_trophy_data()
		log_message("Location visited: " + location_id, LogLevel.INFO)

		# 場所に応じたシークレットトロフィーのチェック
		_check_location_trophies(location_id)

## 場所が訪問済みかどうかを判定
func is_location_visited(location_id: String) -> bool:
	return visited_locations.get(location_id, false)

## 場所訪問に応じたシークレットトロフィーのチェック
func _check_location_trophies(location_id: String) -> void:
	match location_id:
		"secret_base":
			unlock_trophy("secret_base", secret_trophy_names.get("secret_base", "秘密基地"))
		"takiba":
			unlock_trophy("takiba", secret_trophy_names.get("takiba", "焚き場"))

	# ふたこじぞうのチェック（4箇所すべて訪問）
	_check_futako_jizo()

## ふたこじぞうトロフィーのチェック
func _check_futako_jizo() -> void:
	var jizo_locations = ["jizo_north", "jizo_east", "jizo_south", "jizo_west"]
	for loc in jizo_locations:
		if not is_location_visited(loc):
			return
	# 全地蔵発見
	unlock_trophy("futako_jizo", secret_trophy_names.get("futako_jizo", "ふたこじぞう"))

## トゥルーエンド条件をチェック
func check_true_ending_condition() -> bool:
	# 秘密基地 AND (ep_1 AND ep_2 AND ep_3)
	if not is_location_visited("secret_base"):
		return false
	if not is_episode_cleared("ep_1"):
		return false
	if not is_episode_cleared("ep_2"):
		return false
	if not is_episode_cleared("ep_3"):
		return false
	return true

## トゥルーエンドトロフィーを解除
func unlock_true_ending_trophy() -> void:
	unlock_trophy("kiminokoe", secret_trophy_names.get("kiminokoe", "キミノコエ"))

## エピソード回収数を取得
func get_episode_count() -> int:
	var count = 0
	for episode_id in episode_ids:
		if is_episode_cleared(episode_id):
			count += 1
	return count

## 10月10日エンド分岐の判定
func get_day_1010_ending_type() -> String:
	var episode_count = get_episode_count()
	var has_true_condition = check_true_ending_condition()

	if has_true_condition:
		return "true_ready"
	elif episode_count >= 5:
		return "high"
	elif episode_count >= 3:
		return "medium"
	elif episode_count >= 1:
		return "low"
	else:
		return "minimum"

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

	# 訪問済み場所を保存
	for location_id in visited_locations.keys():
		config.set_value("locations", location_id, visited_locations[location_id])

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

		# 訪問済み場所を読み込み
		if config.has_section("locations"):
			for location_id in config.get_section_keys("locations"):
				visited_locations[location_id] = config.get_value("locations", location_id, false)

		log_message("Trophy data loaded successfully", LogLevel.DEBUG)
	elif error == ERR_FILE_NOT_FOUND:
		log_message("Trophy data file not found, using defaults", LogLevel.INFO)
	else:
		log_message("ERROR: Failed to load trophy data: " + str(error), LogLevel.ERROR)

# トロフィー取得時のトースト通知を表示
func _show_trophy_toast(trophy_name: String):
	# シーンツリーが利用可能かチェック
	if not is_inside_tree():
		log_message("Cannot show toast: not inside tree", LogLevel.DEBUG)
		return
	
	# トースト通知への参照を取得（確実に取得するため、毎回探す）
	var toast_node = null
	
	# ノベルシステムシーンを探す
	var root = get_tree().root
	if root:
		for child in root.get_children():
			if child and (child.name == "NovelSystem" or child.has_method("change_background")):
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
		# 「を獲得しました！」を2行目に固定（中央揃えなのでスペースは不要）
		var toast_text = "🔖 " + trophy_name + "\nを獲得しました！"
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
	visited_locations.clear()
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

	log_message("Secret Trophies:", LogLevel.INFO)
	for trophy_id in secret_trophy_ids:
		var unlocked = is_trophy_unlocked(trophy_id)
		var status = "✓" if unlocked else "?"
		var name = secret_trophy_names.get(trophy_id, "???")
		log_message("  " + status + " " + (name if unlocked else "???"), LogLevel.INFO)

	log_message("Locations visited:", LogLevel.INFO)
	for location_id in visited_locations.keys():
		if visited_locations[location_id]:
			log_message("  ✓ " + location_id, LogLevel.INFO)

	log_message("Progress: " + str(get_cleared_episode_count()) + " / " + str(get_total_episode_count()) + " episodes", LogLevel.INFO)
	log_message("True Ending Condition: " + str(check_true_ending_condition()), LogLevel.INFO)
	log_message("Day 1010 Ending Type: " + get_day_1010_ending_type(), LogLevel.INFO)
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

