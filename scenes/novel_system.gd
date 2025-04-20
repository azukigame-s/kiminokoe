extends Control

signal initialized

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
@onready var bgm_player: AudioStreamPlayer = $bgm_player
@onready var sfx_player: AudioStreamPlayer = $sfx_player

func _ready():
	print("Ready function called.")
	
	# デバッグ用出力
	print("BGM player: ", bgm_player)
	print("SFX player: ", sfx_player)
	
	# 初期化処理
	dialogue_text.bbcode_enabled = true
	dialogue_text.text = ""
	
	# 初期化完了のシグナルを発行
	emit_signal("initialized")

func _process(delta):
	# 文字送り処理
	if not is_text_completed:
		text_timer += delta
		if text_timer >= text_speed:
			text_timer = 0
			if displayed_text.length() < current_text.length():
				displayed_text += current_text[displayed_text.length()]
				dialogue_text.text  = displayed_text
				# 文字表示時の効果音があれば、ここで再生
			else:
				is_text_completed = true

# テキストを表示する関数
func show_text(text, speaker_name = ""):
	current_text = text
	displayed_text = ""
	is_text_completed = false
	text_timer = 0

# テキストを一気に表示する関数（クリック時など）
func complete_text():
	if not is_text_completed:
		displayed_text = current_text
		dialogue_text.text = displayed_text
		is_text_completed = true
	else:
		# テキストが表示済みなら次のシナリオに進む
		if has_node("test_scenario"):
			$test_scenario.on_text_completed()

# 背景を変更する関数
func change_background(background_path):
	current_background = background_path
	var bg_texture = load("res://assets/backgrounds/" + background_path)
	print("Loading texture at:", "res://assets/backgrounds/" + background_path)
	print("Loaded texture:", bg_texture)
	if bg_texture != null and background != null:
		print("Applying texture...")
		background.texture = bg_texture
		print("Texture applied.")
	else:
		print("Error: Failed to load background texture or background node is null")
		print("Path: ", "res://assets/backgrounds/" + background_path)
		print("Background node: ", background)

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
	if bgm_player == null:
		print("Error: bgm_player is null")
		return
		
	if current_bgm != bgm_path:
		current_bgm = bgm_path
		var audio_stream = load(bgm_path)
		if audio_stream != null:
			bgm_player.stream = audio_stream
			bgm_player.play()
		else:
			print("Failed to load audio: ", bgm_path)

# 効果音を再生する関数
func play_sfx(sfx_path):
	if sfx_player == null:
		print("Error: sfx_player is null")
		return

	var audio_stream = load(sfx_path)
	if audio_stream != null:
		sfx_player.stream = audio_stream
		sfx_player.play()
	else:
		print("Failed to load audio: ", sfx_path)

# 入力処理
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			complete_text()
