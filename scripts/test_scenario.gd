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
		"type": "dialogue",
		"text": "「へへへ、イチバーン」"
	},
	{
		"type": "dialogue",
		"text": "「あんまり早く押すとまた運転手さんに怒られるぞ」"
	},
	{
		"type": "dialogue",
		"text": "ひとつ後ろの席に座る弟――、スグに向かい僕は言った。",
		"go_next": true
	},
	{
		"type": "dialogue",
		"text": "ニヤニヤと笑いながらスグは口を開く。",
		"new_page": true
	},
	{
		"type": "dialogue",
		"text": "「だって早く帰りたいじゃん！　なんてったって今日は――」"
	},
	{
		"type": "dialogue",
		"text": "満面の笑顔だ。"
	},
	{
		"type": "dialogue",
		"text": "そう。今日は１０月１０日。"
	},
	{
		"type": "dialogue",
		"text": "弟の８歳の誕生日だった。",
		"go_next": true
	},
	{
		"type": "subtitle",
		"text": "10月10日",
		"fade_time": 0.5,
		"display_time": 2.0,
		"typewriter_speed": 0.1
	},
	{
		"type": "dialogue",
		"text": "そんなやり取りをしているうちにバスはスピードを落とし、バス停に着く。",
		"new_page": true
	},
	{
		"type": "dialogue",
		"text": "僕が席を立とうとすると、その横をスグが横切る。"
	},
	{
		"type": "dialogue",
		"text": "「ちょっとスグ、先に行っちゃ……」"
	},
	{
		"type": "dialogue",
		"text": "「ありがとうございましたー。ほら、お兄ぃも早く！」"
	},
	{
		"type": "dialogue",
		"text": "普段は僕の後ろをついてくる弟も、今日は気持ちが高鳴っているのかそそくさとバスを降りてしまう。"
	},
	{
		"type": "dialogue",
		"text": "「ありがとうございました」"
	},
	{
		"type": "dialogue",
		"text": "運転手さんの顔も見ずお礼をし、慌ててあとを追った。",
		"go_next": true
	},
	{
		"type": "dialogue",
		"text": "バスを降りてもそこにスグの姿がない。",
		"new_page": true
	},
	{
		"type": "dialogue",
		"text": "「えっ、どこ？　スグぅ？」"
	},
	{
		"type": "dialogue",
		"text": "ランドセルがバスの後ろに回るのが見えた。"
	},
	{
		"type": "dialogue",
		"text": "――そっちはダメだ！",
		"go_next": true
	},
	{
		"type": "dialogue",
		"text": "「スグっ！　そっちは――――――」",
		"new_page": true
	},
	{
		"type": "sfx",
		"path": "res://assets/sounds/bang_sfx.mp3"
	},
	{
		"type": "dialogue",
		"text": "ドンッ！！！！"
	},
	{
		"type": "sfx",
		"path": "res://assets/sounds/crash_sfx.mp3"
	},
	{
		"type": "dialogue",
		"text": "キキーーッ！　ガシャン！！"
	},
	{
		"type": "dialogue",
		"text": "「…………す……ぐ……？」",
		"go_next": true
	},
	{
		"type": "subtitle",
		"text": "10月10日",
		"fade_time": 0.5,
		"display_time": 3.0,
		"typewriter_speed": 0.15
	},
	{
		"type": "dialogue",
		"text": "今日は１０月１０日。",
		"new_page": true
	},
	{
		"type": "dialogue",
		"text": "弟の８歳の誕生日だった。"
	},
	{
		"type": "dialogue",
		"text": "１０月にしては青すぎる世界がかすみ、白くなる。"
	},
	{
		"type": "dialogue",
		"text": "そして、真っ暗になった――。"
	},
	{
		"type": "dialogue",
		"text": "誰かが遠くから叫ぶ声が聞こえる――。"
	},
	{
		"type": "sfx",
		"path": "res://assets/sounds/kite_sfx.mp3"
	},
	{
		"type": "dialogue",
		"text": "あたりの音も聞こえなくなるなか、鳶の鳴き声だけが耳に残っていた――――。",
		"go_next": true
	},
	{
		"type": "dialogue",
		"text": "……。",
		"new_page": true
	},
	{
		"type": "dialogue",
		"text": "…………。"
	},
	{
		"type": "dialogue",
		"text": "………………。"
	},
	{
		"type": "dialogue",
		"text": "『――だき西口。次は、地蔵焚西口です』",
	},
	{
		"type": "dialogue",
		"text": "車窓の景色は流れるのをやめ、やがて停車する。"
	},
	{
		"type": "dialogue",
		"text": "僕は小さめのボストンバッグを持ち上げて立ち上がり、大口を開けて待つロボに小銭を与え、静かにバスを降りた。"
	},
	{
		"type": "dialogue",
		"text": "１０月にしては強い日差しが目を眩ませる。",
		"go_next": true
	},
	{
		"type": "dialogue",
		"text": "右手で日差しを遮り目を慣らせ、ゆっくりと手を下ろすと――、そこにはひとりの少女が立っていた。",
		"new_page": true
	},
	{
		"type": "dialogue",
		"text": "「おかえり！　私のこと覚えてる？」"
	},
	{
		"type": "dialogue",
		"text": "天真爛漫を絵に書いたような彼女はこちらに笑顔を見せている。"
	},
	{
		"type": "dialogue",
		"text": "僕は――。"
	},
	{
		"type": "choice",
		"choices": [
			{
				"id": "remember_yes",
				"text": "はい",
				"next_index": 400
			},
			{
				"id": "remember_no",
				"text": "いいえ",
				"next_index": 500
			}
		]
	},
	
	# 「はい」を選択した場合の分岐
	{
		"type": "index",
		"index": 400
	},
	{
		"type": "dialogue",
		"text": "「ふふふ、良かった。改めてお兄ちゃんおかえり！」",
		"new_page": true
	},
	{
		"type": "jump",
		"index": 600  # 共通の続きに
	},
	
	# 「いいえ」を選択した場合の分岐
	{
		"type": "index",
		"index": 500
	},
	{
		"type": "dialogue",
		"text": "「ちょっとぉ、お兄ちゃんの冗談分かりづらいんだからやめてよね！」",
		"new_page": true
	},
	{
		"type": "jump",
		"index": 600  # 共通の続きに
	},
	
	# 共通の続き
	{
		"type": "index",
		"index": 600
	},
	{
		"type": "dialogue",
		"text": "そう、彼女はイロ。中学２年生の妹だ。"
	},
	{
		"type": "dialogue",
		"text": "「荷物は……大丈夫そうだね！　じゃあ帰ろう！」"
	},
	{
		"type": "dialogue",
		"text": "今日は１０月１０日。"
	},
	{
		"type": "dialogue",
		"text": "弟の命日だった。"
	}
]

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
	log_message("TestScenario ready - NovelSystem: " + str(novel_system), LogLevel.INFO)
	
	if novel_system:
		novel_system.initialized.connect(_on_novel_system_initialized)
		novel_system.text_click_processed.connect(_on_click_processed)
		novel_system.text_completed.connect(_on_text_completed)
		novel_system.choice_selected.connect(_on_choice_selected)
		novel_system.subtitle_completed.connect(_on_subtitle_completed)
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
		"subtitle":
			var subtitle_text = command.get("text", "")
			var fade_time = command.get("fade_time", 1.0)
			var display_time = command.get("display_time", 2.0)
			var typewriter_speed = command.get("typewriter_speed", 0.05)
			log_message("Showing subtitle: " + subtitle_text, LogLevel.INFO)
			novel_system.show_subtitle(subtitle_text, fade_time, display_time, typewriter_speed)
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
		_:
			log_message("Unknown command type: " + command.type, LogLevel.ERROR)
			proceed_to_next()

func proceed_to_next():
	if waiting_for_click or waiting_for_subtitle:
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
