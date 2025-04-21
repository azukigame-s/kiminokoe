extends Node

# ノベルシステムへの参照
var novel_system

# テストシナリオデータ
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
		"speaker": "???",
		"text": "ここは...どこだろう？"
	},
	{
		"type": "dialogue",
		"speaker": "???",
		"text": "確か、私は..."
	},
	{
		"type": "sfx",
		"path": "res://assets/sounds/sample_sfx.mp3"
	},
	{
		"type": "dialogue",
		"speaker": "",
		"text": "その時、不思議な声が聞こえてきた。"
	}
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
		"character":
			# Vector2の作成方法を修正
			var position = Vector2(
				command.get("position_x", 0), 
				command.get("position_y", 0)
			)
			novel_system.show_character(command.id, command.path, position)
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
