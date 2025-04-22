extends Node

# ノベルシステムへの参照
var novel_system

# テストシナリオデータ - キャラクター表示なし
var scenario = [
	{
		"type": "background",
		"path": "res://assets/backgrounds/sample.jpg"
	},
	{
		"type": "bgm",
		"path": "res://assets/music/sample_bgm.mp3"
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "車窓を流れる景色――。見えるのは青い空、そして青い海。
	
そんな景色を眺めながら僕はバスに揺られていた。

大型の路線バスの左側、一番前の座席に腰を掛けているのだが、バスの中に乗客は僕一人だ。

一番前の席は足場が他より高くなっており、大の大人が座ると体育座りのような不格好な体勢になってしまう。

お世辞にも座り心地は良くないし、乗客のいない車内でわざわざ運転手さんのそばに座る必要なんてない。

そう思うかもしれないが、それでも、僕はこの席が好きだった。"
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "理由は２つ。

フロントガラスから左の車窓にかけて、大パノラマの景色を拝むことができるというのがひとつ。

放り込まれた小銭を大口を開けて飲み込むロボット――、のような運賃箱を見るのが好き、というのがもうひとつだ。

とはいっても、乗客のいないこの状況ではその姿も拝めないのだけど……。"
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "流れる景色を見ていると、いろいろと考えてしまう。

いろいろと思い出してしまう――。"
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "――そう。"
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "――――あの日も。"
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "あの日も……、１０月にしては青すぎる景色だった――。"
	},
	{
		"type": "sfx",
		"path": "res://assets/sounds/sample_sfx.mp3"
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "『次は――』

ピンポーンと軽い音が鳴る。

『――だき西口。次は、地蔵焚西口です』

次のバス停を知らせる感情のない音声を待たずして、降車ボタンを押した人がいる。"
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "「へへへ、イチバーン」

「あんまり早く押すとまた運転手さんに怒られるぞ」

ひとつ後ろの席に座る弟――、スグに向かい僕は言った。

ニヤニヤと笑いながらスグは口を開く。

「だって早く帰りたいじゃん！　なんてったって今日は――」

満面の笑顔だ。"
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "そう。今日は１０月１０日。

弟の８歳の誕生日だった。

そんなやり取りをしているうちにバスはスピードを落とし、バス停に着く。

僕が席を立とうとすると、その横を直が横切る。

「ちょっとスグ、先に行っちゃ……」

「ありがとうございましたー。ほら、お兄ぃも早く！」

普段は僕の後ろをついてくる弟も、今日は気持ちが高鳴っているのかそそくさとバスを降りてしまう。"
	},
	{
		"type": "background",
		"path": "res://assets/backgrounds/forest.jpg"
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "「ありがとうございました」

運転手さんの顔も見ずお礼をし、慌ててあとを追った。

バスを降りてもそこに弟の姿がない。

「えっ、どこ？　スグぅ？」"
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "ランドセルがバスの後ろに回るのが見えた。

――そっちはダメだ！"
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "「スグっ！　そっちは――――――」"
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "ドンッ！！！！"
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "キキーーッ！　ガシャン！！"
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "「…………ス……グ……？」"
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "今日は１０月１０日。

弟の８歳の誕生日だった。"
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "１０月にしては青すぎる世界がかすみ、白くなる。"
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "そして、真っ暗になった――。"
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "誰かが遠くから叫ぶ声が聞こえる――。"
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "まわりの音も聞こえなくなり、鳶の鳴き声だけが耳に残っていた――――。"
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
			novel_system.show_text(command.text, command.speaker)
			# ダイアログはプレイヤーの入力を待つので自動的には進まない
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
