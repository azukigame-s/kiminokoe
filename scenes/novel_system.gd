extends Control

# テキスト表示関連の変数
var current_text = ""
var displayed_text = ""
var text_speed = 0.05  # 文字表示速度（秒）
var is_text_completed = true
var text_timer = 0.0

# 背景関連
var current_background = ""

# キャラクター関連
var current_characters = {}

# 音声関連
var current_bgm = ""

# ノード参照
@onready var background = $background
@onready var characters_container = $characters_container
@onready var dialogue_text = $text_panel/dialogue_text
@onready var character_name = $text_panel/character_name
@onready var bgm_player = $bgm_player
@onready var sfx_player = $sfx_player

func _ready():
	# 初期化処理
	dialogue_text.bbcode_enabled = true
	dialogue_text.bbcode_text = ""

func _process(delta):
	# 文字送り処理
	if not is_text_completed:
		text_timer += delta
		if text_timer >= text_speed:
			text_timer = 0
			if displayed_text.length() < current_text.length():
				displayed_text += current_text[displayed_text.length()]
				dialogue_text.bbcode_text = displayed_text
				# 文字表示時の効果音があれば、ここで再生
			else:
				is_text_completed = true

# テキストを表示する関数
func show_text(text, speaker_name = ""):
	current_text = text
	displayed_text = ""
	is_text_completed = false
	text_timer = 0
	
	# 話者名を設定
	if speaker_name != "":
		character_name.text = speaker_name
		character_name.visible = true
	else:
		character_name.visible = false

# テキストを一気に表示する関数（クリック時など）
func complete_text():
	if not is_text_completed:
		displayed_text = current_text
		dialogue_text.bbcode_text = displayed_text
		is_text_completed = true
	else:
		# テキストが表示済みなら次のシナリオに進む
		if has_node("test_scenario"):
			$test_scenario.on_text_completed()

# 背景を変更する関数
func change_background(background_path):
	current_background = background_path
	var bg_texture = load(background_path)
	background.texture = bg_texture

# キャラクターを表示する関数
func show_character(character_id, character_path, position = Vector2(0, 0)):
	if not character_id in current_characters:
		var character_sprite = TextureRect.new()
		character_sprite.name = character_id
		characters_container.add_child(character_sprite)
		current_characters[character_id] = character_sprite
	
	var character = current_characters[character_id]
	character.texture = load(character_path)
	character.rect_position = position

# キャラクターを非表示にする関数
func hide_character(character_id):
	if character_id in current_characters:
		current_characters[character_id].queue_free()
		current_characters.erase(character_id)

# BGMを再生する関数
func play_bgm(bgm_path):
	if current_bgm != bgm_path:
		#current_bgm = bgm_path
		#bgm_player.stream = load(bgm_path)
		#bgm_player.play()
		pass

# 効果音を再生する関数
func play_sfx(sfx_path):
	sfx_player.stream = load(sfx_path)
	sfx_player.play()

# 入力処理
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			complete_text()
