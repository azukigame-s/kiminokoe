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
		"go_next": true  # 新しいページへ進める
	},
	{
		"type": "dialogue",
		"text": "理由は２つ。",
		"new_page": true  # 新しいページが始まる
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
		"go_next": true  # 新しいページへ進める
	},
	{
		"type": "dialogue",
		"text": "流れる景色を見ていると、いろいろと考えてしまう。",
		"new_page": true  # 新しいページが始まる
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
		"go_next": true  # 新しいページへ進める
	},
	{
		"type": "dialogue",
		"text": "『次は――』",
		"new_page": true  # 新しいページが始まる
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
var waiting_for_click = false  # クリック待ち状態フラグ

func _ready():
	novel_system = get_parent()
	print("TestScenario ready - NovelSystem:", novel_system)
	
	# シグナル接続
	if novel_system:
		novel_system.initialized.connect(_on_novel_system_initialized)
		print("Signal connected")
	else:
		print("Error: Novel system not found")

func _on_novel_system_initialized():
	print("Novel system initialized, starting scenario")
	execute_current_command()

# 現在のコマンドを実行
func execute_current_command():
	if current_index >= scenario.size():
		print("Scenario complete")
		return
	
	var command = scenario[current_index]
	print("Executing command: ", command.type, " at index ", current_index)
	
	match command.type:
		"background":
			novel_system.change_background(command.path)
			proceed_to_next()
		"dialogue":
			var current_dialog = command.text
			var new_page = command.get("new_page", false)  # デフォルトはfalse
			var go_next = command.get("go_next", false)  # go_nextプロパティの取得
			
			if new_page:
				# 新しいページの開始 - 以前のすべてのバッファをクリア
				novel_system.clear_text_buffers()
				novel_system.show_text(current_dialog)
				print("Started new page with text: ", current_dialog)
			else:
				if novel_system.page_text_buffer.size() == 0:
					# バッファが空の場合は最初のテキストとして表示
					novel_system.show_text(current_dialog)
					print("First text in buffer: ", current_dialog)
				else:
					# すでにテキストがある場合はバッファに追加するのみ
					novel_system.add_to_page_buffer(current_dialog, go_next)  # go_nextを渡す
					print("Added text to buffer: ", current_dialog)
			
			# クリック待ち状態に移行
			waiting_for_click = true
		"bgm":
			novel_system.play_bgm(command.path)
			proceed_to_next()
		"sfx":
			novel_system.play_sfx(command.path)
			proceed_to_next()
		_:
			print("Unknown command type: ", command.type)
			proceed_to_next()

# 次のコマンドに進む
func proceed_to_next():
	if waiting_for_click:
		# クリック待ち状態なら何もしない
		return
		
	current_index += 1
	if current_index < scenario.size():
		execute_current_command()

# テキスト表示が完了して次に進むときの処理
func on_text_completed():
	print("Text completed signal received")
	waiting_for_click = false
	current_index += 1
	execute_current_command()

# クリック時の処理 - ノベルシステムからクリックイベントを受け取る
func on_click_received():
	print("Click received in test_scenario")
	
	# テキスト表示がすでに完了しているか確認
	if novel_system.is_text_completed:
		# バッファに次のテキストがあれば表示
		if novel_system.has_more_text_in_buffer():
			novel_system.display_next_text_from_buffer()
			print("Displaying next text from buffer")
		else:
			# バッファが空なら次のコマンドへ
			waiting_for_click = false
			on_text_completed()
	else:
		# テキスト表示中なら表示を完了させる
		novel_system.complete_text_display()
		print("Completed current text display")
