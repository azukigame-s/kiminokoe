extends Node

# ノベルシステムへの参照
var novel_system

# シナリオマネージャーへの参照
var scenario_manager

# トロフィーマネージャーへの参照（オートロードとして設定されている場合）
var trophy_manager = null

# 現在のシナリオデータ（シナリオマネージャーから取得）
var scenario = []

# 現在のシナリオパス（エピソードIDの抽出に使用）
var current_scenario_path: String = ""

# シナリオスタック（元のシナリオに戻るために使用）
var scenario_stack: Array = []  # [{scenario: Array, path: String, index: int, new_page_after_return: bool}]

# 初期シナリオファイル
const INITIAL_SCENARIO = "main"

var current_index = 0
var waiting_for_click = false
var last_choice_index = -1  # 最後に表示した選択肢のインデックスを記録
var waiting_for_subtitle = false  # サブタイトル表示待ちフラグ
var waiting_for_background_fade = false  # 背景フェードイン待ちフラグ

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
	
	# トロフィーマネージャーの参照を取得（オートロードとして設定されている場合）
	if has_node("/root/TrophyManager"):
		trophy_manager = get_node("/root/TrophyManager")
		log_message("TrophyManager found", LogLevel.INFO)
	else:
		log_message("WARNING: TrophyManager not found (not set as autoload). Trophy system will not work!", LogLevel.ERROR)
	
	if novel_system:
		novel_system.initialized.connect(_on_novel_system_initialized)
		novel_system.text_click_processed.connect(_on_click_processed)
		novel_system.text_completed.connect(_on_text_completed)
		novel_system.choice_selected.connect(_on_choice_selected)
		novel_system.subtitle_completed.connect(_on_subtitle_completed)
		novel_system.background_fade_in_completed.connect(_on_background_fade_in_completed)
		log_message("Signals connected", LogLevel.DEBUG)
	else:
		log_message("Error: Novel system not found", LogLevel.ERROR)

func _on_novel_system_initialized():
	log_message("Novel system initialized, loading initial scenario", LogLevel.INFO)
	# 初期シナリオを読み込む
	load_scenario(INITIAL_SCENARIO)

# シナリオを読み込む
func load_scenario(scenario_path: String, save_current: bool = true, new_page_after_return: bool = true, return_index: int = -1):
	if not scenario_manager:
		log_message("ERROR: Scenario manager not found", LogLevel.ERROR)
		return
	
	# 現在のシナリオの状態をスタックに保存（元のシナリオに戻るため）
	if save_current and current_scenario_path != "":
		# return_indexが指定されている場合はそれを使用、そうでない場合はcurrent_index + 1を使用
		var saved_index = return_index if return_index >= 0 else current_index + 1
		scenario_stack.push_back({
			"scenario": scenario.duplicate(true),
			"path": current_scenario_path,
			"index": saved_index,
			"new_page_after_return": new_page_after_return
		})
		log_message("Saved current scenario to stack: " + current_scenario_path + " at index " + str(saved_index) + " (new_page_after_return: " + str(new_page_after_return) + ")", LogLevel.DEBUG)
	
	if scenario_manager.load_scenario(scenario_path):
		scenario = scenario_manager.get_current_scenario()
		current_scenario_path = scenario_manager.get_current_scenario_path()
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
		# シナリオ終了時にエピソードをクリア済みとして記録
		_check_and_clear_episode()
		
		# スタックに元のシナリオがある場合は戻る
		if scenario_stack.size() > 0:
			_return_to_previous_scenario()
		return
	
	var command = scenario[current_index]
	log_message("Executing command: " + command.type + " at index " + str(current_index), LogLevel.DEBUG)
	
	match command.type:
		"background":
			var effect = command.get("effect", "normal")  # "normal", "sepia", "grayscale"
			await novel_system.change_background(command.path, true, 0.5, effect)
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
			# 直前のコマンドが背景変更かどうかを確認
			var previous_was_background = false
			if current_index > 0:
				var previous_command = scenario[current_index - 1]
				if previous_command.type == "background":
					previous_was_background = true
					log_message("Previous command was background change, waiting for fade in...", LogLevel.DEBUG)
			
			# 背景のフェードインが完了するまで待つ
			if previous_was_background or novel_system.background_fade_in_progress:
				# フェードイン完了シグナルを待つ
				while novel_system.background_fade_in_progress:
					log_message("Waiting for background fade in to complete...", LogLevel.DEBUG)
					waiting_for_background_fade = true
					await novel_system.background_fade_in_completed
					waiting_for_background_fade = false
				# さらに少し待ってからサブタイトルを表示（フェードイン完了を確実にする）
				await get_tree().create_timer(0.2).timeout
			
			# サブタイトル表示を開始
			novel_system.show_subtitle(subtitle_text, fade_time, display_time)
			
			# 次のコマンドが background タイプかどうかを確認
			var next_is_background = false
			if current_index + 1 < scenario.size():
				var next_command = scenario[current_index + 1]
				if next_command.type == "background":
					next_is_background = true
					log_message("Next command is background, executing in parallel", LogLevel.DEBUG)
			
			if next_is_background:
				# 次のコマンドが background の場合は並列実行
				# サブタイトル完了を待たずに次のコマンドを実行
				waiting_for_subtitle = true  # フラグは設定するが、完了を待たない
				waiting_for_click = true
				# 次のコマンドを並列で実行
				current_index += 1
				execute_current_command()
			else:
				# それ以外の場合は従来通りサブタイトル完了を待つ
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
			var new_page_after_return = command.get("new_page_after_return", true)  # デフォルトでtrue
			if scenario_path != "":
				log_message("Loading scenario: " + scenario_path + " (new_page_after_return: " + str(new_page_after_return) + ")", LogLevel.INFO)
				waiting_for_click = false
				# 次のインデックス（load_scenarioコマンドの次のコマンド）を保存するため、current_index + 1を渡す
				load_scenario(scenario_path, true, new_page_after_return, current_index + 1)
			else:
				log_message("ERROR: load_scenario command missing 'path' parameter", LogLevel.ERROR)
				proceed_to_next()
		"episode_clear":
			# エピソードをクリア済みとして記録（明示的なコマンド）
			var episode_id = command.get("episode_id", "")
			if episode_id == "":
				# episode_idが指定されていない場合は、現在のシナリオパスから自動抽出
				episode_id = _extract_episode_id_from_path(current_scenario_path)
			
			if episode_id != "":
				_clear_episode(episode_id)
			else:
				log_message("ERROR: episode_clear command: Could not determine episode_id", LogLevel.ERROR)
			proceed_to_next()
		"flashback_start":
			# 回想モード開始
			var effect_type = command.get("effect", "sepia")  # "sepia" または "grayscale"
			novel_system.start_flashback(effect_type)
			proceed_to_next()
		"flashback_end":
			# 回想モード終了
			novel_system.end_flashback()
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
	
	# サブタイトル表示中は次のコマンドに進まない
	if waiting_for_subtitle:
		log_message("Waiting for subtitle to complete", LogLevel.DEBUG)
		return
	
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
	
	# 次のコマンドが既に実行されているかどうかを確認
	# (background の場合は既に実行されているため、current_index を進めない)
	var should_advance = true
	if current_index < scenario.size():
		var current_command = scenario[current_index]
		# 現在のコマンドが background で、まだ実行中の場合（フェードイン中）は待つ
		if current_command.type == "background" and novel_system.background_fade_in_progress:
			should_advance = false
			log_message("Background fade in still in progress, waiting...", LogLevel.DEBUG)
			# 背景フェードイン完了を待つ
			while novel_system.background_fade_in_progress:
				await novel_system.background_fade_in_completed
	
	if should_advance:
		current_index += 1
		execute_current_command()
	else:
		# 背景フェードイン完了後に次のコマンドに進む
		current_index += 1
		execute_current_command()

# 背景フェードイン完了時の処理
func _on_background_fade_in_completed():
	log_message("Background fade in completed signal received", LogLevel.DEBUG)
	waiting_for_background_fade = false

# エピソードIDをパスから抽出
func _extract_episode_id_from_path(scenario_path: String) -> String:
	if not trophy_manager:
		return ""
	return trophy_manager.extract_episode_id(scenario_path)

# エピソードをクリア済みとして記録
func _clear_episode(episode_id: String):
	if trophy_manager:
		log_message("Calling TrophyManager.clear_episode(" + episode_id + ")", LogLevel.INFO)
		trophy_manager.clear_episode(episode_id)
	else:
		log_message("ERROR: TrophyManager not available, cannot clear episode: " + episode_id, LogLevel.ERROR)

# 元のシナリオに戻る
func _return_to_previous_scenario():
	if scenario_stack.size() == 0:
		log_message("No previous scenario to return to", LogLevel.DEBUG)
		return
	
	var previous = scenario_stack.pop_back()
	scenario = previous.scenario
	current_scenario_path = previous.path
	current_index = previous.index
	var new_page_after_return = previous.get("new_page_after_return", true)
	_initialize_index_map()
	
	log_message("Returned to previous scenario: " + current_scenario_path + " at index " + str(current_index), LogLevel.INFO)
	
	# ページ区切りが必要な場合は、次のコマンドにnew_pageを適用
	if new_page_after_return and current_index < scenario.size():
		var next_command = scenario[current_index]
		if next_command is Dictionary and next_command.has("type"):
			# 次のコマンドがdialogueの場合、new_pageを追加
			if next_command.type == "dialogue":
				# new_pageが既に設定されていない場合のみ追加
				if not next_command.has("new_page") or not next_command.new_page:
					next_command["new_page"] = true
					log_message("Applied new_page to next command after returning from episode", LogLevel.DEBUG)
			# テキストバッファをクリア（新しいページの開始）
			novel_system.clear_text_buffers()
	
	# 次のコマンドを実行
	execute_current_command()

# シナリオ終了時にエピソードをクリア済みとして記録（自動判定）
func _check_and_clear_episode():
	log_message("Checking episode clear status...", LogLevel.INFO)
	log_message("Current scenario path: " + current_scenario_path, LogLevel.INFO)
	log_message("TrophyManager available: " + str(trophy_manager != null), LogLevel.INFO)
	
	if not trophy_manager:
		log_message("ERROR: TrophyManager not available, cannot clear episode", LogLevel.ERROR)
		return
	
	# 現在のシナリオパスからエピソードIDを抽出
	var episode_id = _extract_episode_id_from_path(current_scenario_path)
	log_message("Extracted episode_id: " + episode_id, LogLevel.INFO)
	
	if episode_id != "":
		log_message("Clearing episode: " + episode_id, LogLevel.INFO)
		_clear_episode(episode_id)
	else:
		log_message("Could not determine episode_id from scenario path: " + current_scenario_path, LogLevel.ERROR)

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
