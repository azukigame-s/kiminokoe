# scenario_manager.gd
# シナリオファイルの読み込みと管理を行うマネージャー

extends Node

# シグナル定義
signal scenario_loaded(scenario_path)
signal scenario_load_failed(scenario_path, error)

# ログレベル定義
enum LogLevel {INFO, DEBUG, ERROR}

# 現在読み込まれているシナリオデータ
var current_scenario: Array = []
var current_scenario_path: String = ""
var scenario_cache: Dictionary = {}  # シナリオファイルのキャッシュ

# シナリオファイルのベースディレクトリ
const SCENARIO_BASE_DIR = "res://scenarios/"

# シナリオファイルを読み込む
func load_scenario(scenario_path: String) -> bool:
	log_message("Loading scenario: " + scenario_path, LogLevel.INFO)
	
	# パスが相対パスの場合はベースディレクトリを追加
	var full_path = scenario_path
	if not scenario_path.begins_with("res://"):
		full_path = SCENARIO_BASE_DIR + scenario_path
	
	# 拡張子がない場合は.jsonを追加
	if not full_path.ends_with(".json"):
		full_path += ".json"
	
	# キャッシュに存在する場合はそれを使用
	if scenario_cache.has(full_path):
		log_message("Using cached scenario: " + full_path, LogLevel.DEBUG)
		current_scenario = scenario_cache[full_path].duplicate(true)
		current_scenario_path = full_path
		scenario_loaded.emit(full_path)
		return true
	
	# ファイルを読み込む
	var file = FileAccess.open(full_path, FileAccess.READ)
	if file == null:
		var error_msg = "Failed to open scenario file: " + full_path
		log_message(error_msg, LogLevel.ERROR)
		scenario_load_failed.emit(full_path, error_msg)
		return false
	
	# JSONをパース
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		var error_msg = "Failed to parse JSON: " + json.get_error_message()
		log_message(error_msg, LogLevel.ERROR)
		scenario_load_failed.emit(full_path, error_msg)
		return false
	
	var scenario_data = json.data
	
	# シナリオデータの検証
	if not scenario_data is Array:
		var error_msg = "Scenario data is not an array: " + full_path
		log_message(error_msg, LogLevel.ERROR)
		scenario_load_failed.emit(full_path, error_msg)
		return false
	
	# シナリオを設定
	current_scenario = scenario_data
	current_scenario_path = full_path
	
	# キャッシュに保存
	scenario_cache[full_path] = scenario_data.duplicate(true)
	
	log_message("Scenario loaded successfully: " + full_path + " (" + str(scenario_data.size()) + " commands)", LogLevel.INFO)
	scenario_loaded.emit(full_path)
	return true

# 現在のシナリオを取得
func get_current_scenario() -> Array:
	return current_scenario

# 現在のシナリオパスを取得
func get_current_scenario_path() -> String:
	return current_scenario_path

# シナリオのインデックスマップを生成
func create_index_map(scenario: Array) -> Dictionary:
	var index_map = {}
	for i in range(scenario.size()):
		var command = scenario[i]
		if command is Dictionary and command.has("type") and command.type == "index":
			if command.has("index"):
				index_map[command.index] = i
				log_message("Mapped index " + str(command.index) + " to scenario position " + str(i), LogLevel.DEBUG)
	return index_map

# キャッシュをクリア
func clear_cache():
	scenario_cache.clear()
	log_message("Scenario cache cleared", LogLevel.DEBUG)

# 特定のシナリオをキャッシュから削除
func remove_from_cache(scenario_path: String):
	if scenario_cache.has(scenario_path):
		scenario_cache.erase(scenario_path)
		log_message("Removed from cache: " + scenario_path, LogLevel.DEBUG)

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
	
	print(prefix + "[ScenarioManager] " + message)

