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
]

var current_index = 0
var waiting_for_click = false

# シグナルのエイリアス定義
enum LogLevel {INFO, DEBUG, ERROR}

func _ready():
	novel_system = get_parent()
	log_message("TestScenario ready - NovelSystem: " + str(novel_system), LogLevel.INFO)
	
	if novel_system:
		novel_system.initialized.connect(_on_novel_system_initialized)
		novel_system.text_click_processed.connect(_on_click_processed)
		novel_system.text_completed.connect(_on_text_completed)
		log_message("Signals connected", LogLevel.DEBUG)
	else:
		log_message("Error: Novel system not found", LogLevel.ERROR)

func _on_novel_system_initialized():
	log_message("Novel system initialized, starting scenario", LogLevel.INFO)
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
