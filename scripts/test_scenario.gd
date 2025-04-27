extends Node

# ノベルシステムへの参照
var novel_system

# テストシナリオデータ - キャラクター表示なし
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
		"speaker": "",
		"text": "車窓を流れる景色――。見えるのは青い空、そして青い海。",
		"new_page": true  # 新しいシーンの開始なので新ページ
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "そんな景色を眺めながら僕はバスに揺られていた。"
		# new_pageが省略されているので同じページに追加
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "大型の路線バスの左側、一番前の座席に腰を掛けているのだが、バスの中に乗客は僕一人だ。"
		# 同じページに追加
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "一番前の席は足場が他より高くなっており、大の大人が座ると体育座りのような不格好な体勢になってしまう。"
		# 同じページに追加
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "お世辞にも座り心地は良くないし、乗客のいない車内でわざわざ運転手さんのそばに座る必要なんてない。"
		# 同じページに追加
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "そう思うかもしれないが、それでも、僕はこの席が好きだった。"
		# 同じページに追加
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "理由は２つ。",
		"new_page": true  # 新しい段落で区切るため新ページ
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "フロントガラスから左の車窓にかけて、大パノラマの景色を拝むことができるというのがひとつ。"
		# 同じページに追加
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "放り込まれた小銭を大口を開けて飲み込むロボット――、のような運賃箱を見るのが好き、というのがもうひとつだ。"
		# 同じページに追加
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "とはいっても、乗客のいないこの状況ではその姿も拝めないのだけど……。"
		# 同じページに追加
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "流れる景色を見ていると、いろいろと考えてしまう。",
		"new_page": true  # 場面転換のような重要な文なので新ページ
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "いろいろと思い出してしまう――。"
		# 同じページに追加
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "――そう。",
		"new_page": true  # 強調するため新ページ
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "――――あの日も。"
		# 同じページに追加
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "あの日も……、１０月にしては青すぎる景色だった――。"
		# 同じページに追加
	},
	{
		"type": "sfx",
		"path": "res://assets/sounds/sample_sfx.mp3"
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "『次は――』",
		"new_page": true  # SFX後は新ページ
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "ピンポーンと軽い音が鳴る。"
		# 同じページに追加
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "『――だき西口。次は、地蔵焚西口です』"
		# 同じページに追加
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "次のバス停を知らせる感情のない音声を待たずして、降車ボタンを押した人がいる。"
		# 同じページに追加
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "「へへへ、イチバーン」",
		"new_page": true  # 会話の始まりなので新ページ
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "「あんまり早く押すとまた運転手さんに怒られるぞ」"
		# 同じページに追加
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "ひとつ後ろの席に座る弟――、スグに向かい僕は言った。"
		# 同じページに追加
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "ニヤニヤと笑いながらスグは口を開く。"
		# 同じページに追加
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "「だって早く帰りたいじゃん！　なんてったって今日は――」"
		# 同じページに追加
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "満面の笑顔だ。"
		# 同じページに追加
	},
]

var current_index = 0

func _ready():
	novel_system = get_parent()
	print("TestScenario ready - NovelSystem:", novel_system)
	
	# Godot 4.x形式のシグナル接続
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
			var current_speaker = command.speaker
			
			# 新しいページで表示するかどうかを判断
			if command.has("new_page") and command.new_page == true:
				# 新しいページを開始
				novel_system.clear_text_page()
				novel_system.show_text(current_dialog, current_speaker)
			else:
				# 既存のページに追加
				if novel_system.page_text_buffer.size() == 0:
					# バッファが空の場合は新規表示
					novel_system.show_text(current_dialog, current_speaker)
				else:
					# 既存のページに追加（同じページ内）
					novel_system.show_text_same_page(current_dialog, current_speaker)
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
	current_index += 1
	if current_index < scenario.size():
		execute_current_command()

# テキスト表示が完了して次に進むときの処理
func on_text_completed():
	print("Text completed, moving to next command")
	current_index += 1
	execute_current_command()
