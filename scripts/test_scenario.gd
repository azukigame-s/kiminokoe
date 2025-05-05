extends Node

# ノベルシステムへの参照
var novel_system

# テストシナリオデータ
var scenario = [
	{
		"type": "background",
		"path": "res://assets/backgrounds/sea.jpg"
	},
	{
		"type": "bgm",
		"path": "res://assets/music/sample_bgm.mp3"
	},
	{
		"type": "dialogue",
		"text": "車窓を流れる景色――。見えるのは青い空、そして青い海。",
	},
	{
		"type": "dialogue",
		"text": "そんな景色を眺めながら僕はバスに揺られていた。"
	},
	{
		"type": "dialogue",
		"text": "大型の路線バスの左側、一番前の座席に腰を掛けているのだが、バスの中に乗客は僕一人だ。"
	},
	{
		"type": "dialogue",
		"text": "一番前の席は足場が他より高くなっており、大の大人が座ると体育座りのような不格好な体勢になってしまう。"
	},
	{
		"type": "dialogue",
		"text": "お世辞にも座り心地は良くないし、乗客のいない車内でわざわざ運転手さんのそばに座る必要なんてない。"
	},
	{
		"type": "dialogue",
		"text": "そう思うかもしれないが、それでも、僕はこの席が好きだった。",
		"go_next": true
	},
	{
		"type": "dialogue",
		"text": "理由は２つ。",
		"new_page": true
	},
	{
		"type": "dialogue",
		"text": "フロントガラスから左の車窓にかけて、大パノラマの景色を拝むことができるというのがひとつ。"
	},
	{
		"type": "dialogue",
		"text": "放り込まれた小銭を大口を開けて飲み込むロボット――、のような運賃箱を見るのが好き、というのがもうひとつだ。"
	},
	{
		"type": "dialogue",
		"text": "とはいっても、乗客のいないこの状況ではその姿も拝めないのだけど……。",
		"go_next": true
	},
	{
		"type": "dialogue",
		"text": "流れる景色を見ていると、いろいろと考えてしまう。",
		"new_page": true
	},
	{
		"type": "dialogue",
		"text": "いろいろと思い出してしまう――。"
	},
	{
		"type": "dialogue",
		"text": "――そう。"
	},
	{
		"type": "dialogue",
		"text": "――――あの日も。"
	},
	{
		"type": "dialogue",
		"text": "あの日も……、１０月にしては青すぎる景色だった――。",
		"go_next": true
	},
	{
		"type": "dialogue",
		"text": "『次は――』",
		"new_page": true
	},
	{
		"type": "sfx",
		"path": "res://assets/sounds/sample_sfx.mp3"
	},
	{
		"type": "dialogue",
		"text": "ピンポーンと軽い音が鳴る。"
	},
	{
		"type": "dialogue",
		"text": "『――だき西口。次は、地蔵焚西口です』"
	},
	{
		"type": "dialogue",
		"text": "次のバス停を知らせる感情のない音声を待たずして、降車ボタンを押した人がいる。"
	},
	{
		"type": "choice",
		"choices": [
			{
				"id": "option1",
				"text": "降りる",
				"next_index": 100  # 次に実行するシナリオのインデックス
			},
			{
				"id": "option2",
				"text": "乗り続ける",
				"next_index": 200  # 次に実行するシナリオのインデックス
			},
			{
				"id": "option3",
				"text": "運転手に話しかける",
				"next_index": 300  # 次に実行するシナリオのインデックス
			}
		]
	},
	# 選択肢 option1 のシナリオ分岐
	{
		"type": "index",
		"index": 100
	},
	{
		"type": "dialogue",
		"text": "僕は次の停留所で降りることにした。",
		"new_page": true
	},
	{
		"type": "dialogue",
		"text": "バスが止まると、僕は席を立ち、運転手に軽く会釈をして降りた。"
	},
	{
		"type": "dialogue",
		"text": "ここから先は歩いて行くことにしよう。"
	},
	{
		"type": "jump",
		"index": 999  # 共通エンドポイント
	},
	
	# 選択肢 option2 のシナリオ分岐
	{
		"type": "index",
		"index": 200
	},
	{
		"type": "dialogue",
		"text": "いや、まだ降りる必要はない。",
		"new_page": true
	},
	{
		"type": "dialogue",
		"text": "僕はそのまま座席に座り、窓の外を見続けた。"
	},
	{
		"type": "dialogue",
		"text": "行き先を決めずに、ただ車窓の景色を楽しむ旅――。"
	},
	{
		"type": "jump",
		"index": 999  # 共通エンドポイント
	},
	
	# 選択肢 option3 のシナリオ分岐
	{
		"type": "index",
		"index": 300
	},
	{
		"type": "dialogue",
		"text": "「すみません、この先の地蔵焚ってどんな場所なんですか？」",
		"new_page": true
	},
	{
		"type": "dialogue",
		"text": "運転手は少し驚いた様子で僕を見た。"
	},
	{
		"type": "dialogue",
		"text": "「地蔵焚？ああ、昔ながらの温泉街だよ。最近は観光客も少なくなったけどね。」"
	},
	{
		"type": "dialogue",
		"text": "「へぇ、そうなんですか。」"
	},
	{
		"type": "jump",
		"index": 999  # 共通エンドポイント
	},
	
	# 共通エンドポイント
	{
		"type": "index",
		"index": 999
	},
	{
		"type": "dialogue",
		"text": "そして、物語は続いていく……",
		"new_page": true
	}
]

var current_index = 0
var waiting_for_click = false
var last_choice_index = -1  # 最後に表示した選択肢のインデックスを記録

# 現在のシナリオインデックスをフォローする辞書
var index_map = {}

# シグナルのエイリアス定義
enum LogLevel {INFO, DEBUG, ERROR}

func _ready():
	novel_system = get_parent()
	log_message("TestScenario ready - NovelSystem: " + str(novel_system), LogLevel.INFO)
	
	if novel_system:
		novel_system.initialized.connect(_on_novel_system_initialized)
		novel_system.text_click_processed.connect(_on_click_processed)
		novel_system.text_completed.connect(_on_text_completed)
		novel_system.choice_selected.connect(_on_choice_selected)
		log_message("Signals connected", LogLevel.DEBUG)
	else:
		log_message("Error: Novel system not found", LogLevel.ERROR)
	
	_initialize_index_map()

func _on_novel_system_initialized():
	log_message("Novel system initialized, starting scenario", LogLevel.INFO)
	execute_current_command()

# シナリオインデックスの初期化
func _initialize_index_map():
	index_map.clear()
	for i in range(scenario.size()):
		var command = scenario[i]
		if command.type == "index":
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
					if choice.has("next_index") and index_map.has(choice.next_index):
						current_index = index_map[choice.next_index]
						log_message("Jumping to choice branch index " + str(choice.next_index) + " (scenario position " + str(current_index) + ")", LogLevel.DEBUG)
						waiting_for_click = false
						execute_current_command()
						return
					else:
						log_message("ERROR: Choice next_index not found: " + str(choice.get("next_index", "unknown")), LogLevel.ERROR)
		else:
			log_message("ERROR: Last choice command is not of type 'choice': " + choice_command.type, LogLevel.ERROR)
	else:
		log_message("ERROR: Invalid last_choice_index: " + str(last_choice_index), LogLevel.ERROR)
	
	# 選択肢が見つからない場合は次のコマンドに進む
	waiting_for_click = false
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

# ログメッセージの出力（NovelSystemと同様のログ機能）
func log_message(message, level = LogLevel.INFO):
	if novel_system:
		novel_system.log_message("[TestScenario] " + message, level)
	else:
		var prefix = ""
		match level:
			LogLevel.INFO:
				prefix = "[INFO] "
			LogLevel.DEBUG:
				prefix = "[DEBUG] "
			LogLevel.ERROR:
				prefix = "[ERROR] "
		
		print(prefix + "[TestScenario] " + message)
