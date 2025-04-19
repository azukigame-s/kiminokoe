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
		"path": "res://assets/music/sample_bgm.ogg"
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
		"path": "res://assets/sounds/sample_sfx.ogg"
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
	execute_current_command()

# 現在のコマンドを実行
func execute_current_command():
	if current_index >= scenario.size():
		return
	
	var command = scenario[current_index]
	match command.type:
		"background":
			novel_system.change_background(command.path)
			proceed_to_next()
		"character":
			novel_system.show_character(command.id, command.path, Vector2(command.position_x, command.position_y))
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

# 次のコマンドに進む
func proceed_to_next():
	current_index += 1
	if current_index < scenario.size():
		execute_current_command()

# テキスト表示が完了して次に進むときの処理
func on_text_completed():
	current_index += 1
	execute_current_command()
