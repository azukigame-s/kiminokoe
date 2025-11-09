extends Node

# ノベルシステムへの参照
var novel_system

# シナリオマネージャーへの参照
var scenario_manager

# 現在のシナリオデータ（シナリオマネージャーから取得）
var scenario = []

# 初期シナリオファイル
const INITIAL_SCENARIO = "main"

var current_index = 0
var waiting_for_click = false
var last_choice_index = -1  # 最後に表示した選択肢のインデックスを記録
var waiting_for_subtitle = false  # サブタイトル表示待ちフラグ

# 現在のシナリオインデックスをフォローする辞書
var index_map = {}

# シグナルのエイリアス定義
enum LogLevel {INFO, DEBUG, ERROR}

func _ready():
	novel_system = get_parent()
	log_message("Scenario ready - NovelSystem: " + str(novel_system), LogLevel.INFO)
	
	# シナリオマネージャーの作成
	scenario_manager = Node.new()
	scenario_manager.set_script(load("res://scripts/scenario_manager.gd"))
	add_child(scenario_manager)
	
	if novel_system:
		novel_system.initialized.connect(_on_novel_system_initialized)
		novel_system.text_click_processed.connect(_on_click_processed)
		novel_system.text_completed.connect(_on_text_completed)
		novel_system.choice_selected.connect(_on_choice_selected)
		novel_system.subtitle_completed.connect(_on_subtitle_completed)
		log_message("Signals connected", LogLevel.DEBUG)
	else:
		log_message("Error: Novel system not found", LogLevel.ERROR)

func _on_novel_system_initialized():
	log_message("Novel system initialized, loading initial scenario", LogLevel.INFO)
	# 初期シナリオを読み込む
	load_scenario(INITIAL_SCENARIO)

# シナリオを読み込む
func load_scenario(scenario_path: String):
	if not scenario_manager:
		log_message("ERROR: Scenario manager not found", LogLevel.ERROR)
		return
	
	if scenario_manager.load_scenario(scenario_path):
		scenario = scenario_manager.get_current_scenario()
		current_index = 0
		_initialize_index_map()
		log_message("Scenario loaded: " + scenario_path, LogLevel.INFO)
		execute_current_command()
	else:
		log_message("ERROR: Failed to load scenario: " + scenario_path, LogLevel.ERROR)

# シナリオインデックスの初期化
func _initialize_index_map():
	index_map.clear()
	for i in range(scenario.size()):
		var command = scenario[i]
		if command is Dictionary and command.has("type") and command.type == "index":
			if command.has("index"):
				index_map[command.index] = i
				log_message("Mapped index " + str(command.index) + " to scenario position " + str(i), LogLevel.DEBUG)

# 選択肢が選ばれた時の処理
func _on_choice_selected(choice_id):
	log_message("Choice selected: " + choice_id, LogLevel.INFO)
	
	# 最後に表示した選択肢コマンドを使用
	if last_choice_index >= 0 and last_choice_index < scenario.size():
		var choice_command = scenario[last_choice_index]
		
		if choice_command.type == "choice":
			for choice in choice_command.choices:
				if choice.id == choice_id:
					# シナリオファイルへの分岐をサポート
					if choice.has("scenario"):
						var scenario_path = choice.scenario
						log_message("Loading scenario from choice: " + scenario_path, LogLevel.INFO)
						waiting_for_click = false
						novel_system.clear_text_buffers()
						load_scenario(scenario_path)
						return
					# 従来のnext_indexもサポート（後方互換性）
					elif choice.has("next_index") and index_map.has(choice.next_index):
						current_index = index_map[choice.next_index]
						log_message("Jumping to choice branch index " + str(choice.next_index) + " (scenario position " + str(current_index) + ")", LogLevel.DEBUG)
						waiting_for_click = false
						novel_system.clear_text_buffers()
						execute_current_command()
						return
					else:
						log_message("ERROR: Choice has neither 'scenario' nor valid 'next_index': " + str(choice), LogLevel.ERROR)
		else:
			log_message("ERROR: Last choice command is not of type 'choice': " + choice_command.type, LogLevel.ERROR)
	else:
		log_message("ERROR: Invalid last_choice_index: " + str(last_choice_index), LogLevel.ERROR)
	
	# 選択肢が見つからない場合は次のコマンドに進む
	waiting_for_click = false
	novel_system.clear_text_buffers()
	current_index += 1
	execute_current_command()
	
func execute_current_command():
	if current_index >= scenario.size():
		log_message("Scenario complete", LogLevel.INFO)
		return
	
	var command = scenario[current_index]
	log_message("Executing command: " + command.type + " at index " + str(current_index), LogLevel.DEBUG)
	
	match command.type:
		"background":
			novel_system.change_background(command.path)
			proceed_to_next()
		"dialogue":
			var current_dialog = command.text
			var new_page = command.get("new_page", false)
			var go_next = command.get("go_next", false)
			
			log_message("Processing dialogue: new_page=" + str(new_page) + ", go_next=" + str(go_next), LogLevel.DEBUG)
			
			if new_page:
				novel_system.clear_text_buffers()
				novel_system.show_text(current_dialog, true, go_next)
				log_message("Started new page with text: " + current_dialog, LogLevel.DEBUG)
			else:
				if novel_system.page_text_buffer.size() == 0:
					novel_system.show_text(current_dialog, true, go_next)
					log_message("First text in buffer: " + current_dialog, LogLevel.DEBUG)
				else:
					novel_system.add_to_page_buffer(current_dialog, go_next)
					log_message("Added text to buffer: " + current_dialog, LogLevel.DEBUG)
			
			waiting_for_click = true
		"bgm":
			novel_system.play_bgm(command.path)
			proceed_to_next()
		"sfx":
			novel_system.play_sfx(command.path)
			proceed_to_next()
		"subtitle":
			var subtitle_text = command.get("text", "")
			var fade_time = command.get("fade_time", 1.0)
			var display_time = command.get("display_time", 2.0)
			log_message("Showing subtitle: " + subtitle_text, LogLevel.INFO)
			novel_system.show_subtitle(subtitle_text, fade_time, display_time)
			waiting_for_subtitle = true
			waiting_for_click = true
		"choice":
			log_message("Showing choices with " + str(command.choices.size()) + " options", LogLevel.INFO)
			last_choice_index = current_index  # 選択肢コマンドのインデックスを記録
			novel_system.show_choices(command.choices)
			# 選択肢表示の確認
			await get_tree().process_frame
			log_message("Choice visibility status: attempting to show choices", LogLevel.INFO)
			waiting_for_click = true
		"index":
			# インデックスマーカーはスキップ
			proceed_to_next()
		"jump":
			if command.has("index") and index_map.has(command.index):
				current_index = index_map[command.index]
				log_message("Jumping to index " + str(command.index) + " (scenario position " + str(current_index) + ")", LogLevel.DEBUG)
				proceed_to_next()
			else:
				log_message("ERROR: Jump target not found: " + str(command.get("index", "unknown")), LogLevel.ERROR)
				proceed_to_next()
		"load_scenario":
			# 別のシナリオファイルを読み込む
			var scenario_path = command.get("path", "")
			if scenario_path != "":
				log_message("Loading scenario: " + scenario_path, LogLevel.INFO)
				waiting_for_click = false
				load_scenario(scenario_path)
			else:
				log_message("ERROR: load_scenario command missing 'path' parameter", LogLevel.ERROR)
				proceed_to_next()
		_:
			log_message("Unknown command type: " + command.type, LogLevel.ERROR)
			proceed_to_next()

func proceed_to_next():
	if waiting_for_click:
		return
		
	current_index += 1
	if current_index < scenario.size():
		execute_current_command()

func _on_text_completed():
	log_message("Text completed signal received", LogLevel.DEBUG)
	# テキスト表示が完了した時の処理（必要に応じて）

func _on_click_processed():
	log_message("Click processed signal received", LogLevel.DEBUG)
	
	# 選択肢が表示されている場合は次のコマンドに進まない
	if last_choice_index >= 0 and last_choice_index < scenario.size():
		var choice_command = scenario[last_choice_index]
		if choice_command.type == "choice" and current_index == last_choice_index:
			log_message("Waiting for choice selection", LogLevel.DEBUG)
			return
	
	if novel_system.is_text_completed and not novel_system.has_more_text_in_buffer():
		log_message("No more text in buffer, proceeding to next command", LogLevel.DEBUG)
		waiting_for_click = false
		current_index += 1
		execute_current_command()

# サブタイトルが完了した時の処理
func _on_subtitle_completed():
	log_message("Subtitle completed signal received", LogLevel.DEBUG)
	waiting_for_subtitle = false
	waiting_for_click = false
	current_index += 1
	execute_current_command()

# ログメッセージの出力（NovelSystemと同様のログ機能）
func log_message(message, level = LogLevel.INFO):
	if novel_system:
		novel_system.log_message("[Scenario] " + message, level)
	else:
		var prefix = ""
		match level:
			LogLevel.INFO:
				prefix = "[INFO] "
			LogLevel.DEBUG:
				prefix = "[DEBUG] "
			LogLevel.ERROR:
				prefix = "[ERROR] "
		
		print(prefix + "[Scenario] " + message)
