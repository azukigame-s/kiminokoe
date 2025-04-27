extends Control

signal initialized

# テキスト表示関連の変数
var current_text = ""
var displayed_text = ""
var text_speed = 0.05  # 文字表示速度（秒）
var is_text_completed = true
var text_timer = 0.0
var page_text_buffer = []  # 現在のページに表示するテキストのバッファ
var current_page_index = 0  # ページ内の現在位置

# 新しい変数 - 「続きあり」インジケータ用
var more_indicator = null

# 背景関連
var current_background = ""

# キャラクター関連
var current_characters = {}

# 音声関連
var current_bgm = ""

# ノード参照
@onready var background = $background
@onready var characters_container = $characters_container
@onready var text_panel = $text_panel
@onready var dialogue_text = $text_panel/dialogue_text if has_node("text_panel") else null
@onready var bgm_player = $bgm_player
@onready var sfx_player = $sfx_player

func _ready():
	print("Visual Novel System: Ready function called.")
	
	# サイズを明示的に設定（親Controlノードのサイズ問題を解決するコード）
	size_flags_horizontal = Control.SIZE_FILL
	size_flags_vertical = Control.SIZE_FILL
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	await get_tree().process_frame
	print("Updated Control size after frame: ", size)
	
	# ノード参照の確認
	_check_nodes()
	
	# 背景の初期設定
	if background:
		_setup_fullscreen_element(background)
		print("Background setup complete. Size: ", background.size)
	
	# テキストパネルの設定
	if text_panel:
		# テキストパネルを全画面に設定（かまいたちの夜スタイル）
		text_panel.anchor_top = 0.0
		text_panel.anchor_bottom = 1.0
		text_panel.anchor_left = 0.0
		text_panel.anchor_right = 1.0
		text_panel.offset_left = 0
		text_panel.offset_top = 0
		text_panel.offset_right = 0
		text_panel.offset_bottom = 0
		
		# 半透明の黒背景
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(0, 0, 0, 0.5)  # 半透明の黒
		text_panel.add_theme_stylebox_override("panel", style_box)
		
		print("Text panel setup complete for Kamaitachi style. Size: ", text_panel.size)
	
	# テキスト表示の設定
	if dialogue_text:
		dialogue_text.bbcode_enabled = true
		dialogue_text.visible = true
		
		# テキストを画面中央に配置（かまいたちの夜スタイル）
		dialogue_text.anchor_left = 0.1
		dialogue_text.anchor_top = 0.1
		dialogue_text.anchor_right = 0.9
		dialogue_text.anchor_bottom = 0.9
		dialogue_text.offset_left = 0
		dialogue_text.offset_top = 0
		dialogue_text.offset_right = 0
		dialogue_text.offset_bottom = 0
		
		# テキストが見えるように色とフォントサイズを設定
		dialogue_text.add_theme_color_override("default_color", Color(1, 1, 1, 1))  # 白色
		dialogue_text.add_theme_font_size_override("normal_font_size", 24)  # フォントサイズを大きく
		
		print("Dialogue text setup complete for Kamaitachi style. Size: ", dialogue_text.size)
		
		# テーマをロード
		var custom_theme = load("res://themes/novel_theme.tres")
		if custom_theme:
			dialogue_text.theme = custom_theme
			print("Custom theme applied to dialogue text")
	
	# キャラクターコンテナの設定
	if characters_container:
		_setup_fullscreen_element(characters_container)
		print("Characters container setup complete.")
	
	# 「続きあり」インジケータを作成
	create_more_indicator()
	
	# 初期化完了のシグナルを発行
	initialized.emit()

# 「続きあり」インジケータを作成する関数
func create_more_indicator():
	if text_panel and not more_indicator:
		more_indicator = TextureRect.new()
		more_indicator.name = "more_indicator"
		
		# テクスチャの読み込み試行
		var indicator_texture = null
		var possible_paths = [
			"res://assets/icons/file.png",
			"res://assets/icons/pencil.png",
			"res://assets/images/more_indicator.png"
		]
		
		for path in possible_paths:
			indicator_texture = load(path)
			if indicator_texture:
				print("Found indicator texture at: ", path)
				break
		
		if indicator_texture:
			more_indicator.texture = indicator_texture
		else:
			# テクスチャが見つからない場合はプレースホルダーを作成
			print("No indicator texture found. Creating placeholder...")
			more_indicator = create_placeholder_indicator()
		
		# サイズと位置を設定
		more_indicator.custom_minimum_size = Vector2(32, 32)
		more_indicator.position = Vector2(1075, 575)  # 画面の右下あたり、適宜調整してください
		more_indicator.visible = false  # 最初は非表示
		
		text_panel.add_child(more_indicator)
		print("More indicator added to text panel")

# プレースホルダーインジケータを作成する関数
func create_placeholder_indicator():
	var indicator = ColorRect.new()
	indicator.name = "placeholder_indicator"
	indicator.size = Vector2(20, 20)
	indicator.color = Color(1, 1, 0, 0.8)  # 黄色の四角形
	
	# 点滅アニメーション用のタイマー
	var timer = Timer.new()
	timer.name = "blink_timer"
	timer.wait_time = 0.5
	timer.autostart = true
	timer.timeout.connect(_on_indicator_blink)
	indicator.add_child(timer)
	
	return indicator

# インジケータの点滅処理
func _on_indicator_blink():
	if more_indicator and more_indicator is ColorRect:
		more_indicator.modulate.a = 1.0 if more_indicator.modulate.a < 0.5 else 0.3

# ノード参照を確認するヘルパー関数
func _check_nodes():
	print("Checking node references:")
	print("- Background node: ", background)
	print("- Characters container: ", characters_container)
	print("- Text panel: ", text_panel)
	print("- Dialogue text node: ", dialogue_text)
	print("- BGM player: ", bgm_player)
	print("- SFX player: ", sfx_player)
	
	# 親ノードのサイズ確認
	print("Control size: ", size)
	
	# ノードが見つからない場合はエラーメッセージと推奨修正
	if not background:
		print("ERROR: Background node missing. Create a TextureRect named 'background' as a child of this Control node.")
	
	if not text_panel:
		print("ERROR: Text panel missing. Create a Panel or Control named 'text_panel' as a child of this Control node.")
	
	if not dialogue_text and text_panel:
		print("ERROR: Dialogue text node missing. Create a RichTextLabel named 'dialogue_text' as a child of the text_panel.")
	
	if not characters_container:
		print("ERROR: Characters container missing. Create a Control named 'characters_container' as a child of this Control node.")

# 要素を画面全体に表示する共通設定関数
func _setup_fullscreen_element(element):
	# アンカーを画面全体に設定
	element.anchor_left = 0.0
	element.anchor_top = 0.0
	element.anchor_right = 1.0
	element.anchor_bottom = 1.0
	
	# オフセットを0に設定（画面の端から端まで広げる）
	element.offset_left = 0
	element.offset_top = 0
	element.offset_right = 0
	element.offset_bottom = 0
	
	# TextureRect固有のプロパティを設定
	if element is TextureRect:
		element.expand = true
		element.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

func _process(delta):
	# 文字送り処理
	if not is_text_completed:
		text_timer += delta
		if text_timer >= text_speed:
			text_timer = 0
			if displayed_text.length() < current_text.length():
				displayed_text += current_text[displayed_text.length()]
				_update_displayed_text()
				# 文字表示時の効果音があれば、ここで再生する場合
				# if displayed_text.length() % 3 == 0:  # 3文字ごとに再生など
				#     play_sfx("text_sound.wav")
			else:
				is_text_completed = true
				# テキスト表示が完了したら、「続きあり」インジケータを表示
				if more_indicator:
					more_indicator.visible = current_page_index < page_text_buffer.size() - 1

# 現在表示すべきテキストを更新する関数
func _update_displayed_text():
	if dialogue_text:
		if displayed_text.length() == 1 && current_page_index == 0:
			# 最初の文字を表示するときは、テキストをリセット
			var base_text = ""
			
			# 話者名があれば追加
			if page_text_buffer[0]["speaker"] != "":
				base_text = "[color=#FFDD00][b]" + page_text_buffer[0]["speaker"] + "[/b][/color]\n\n"
			
			dialogue_text.text = base_text
		
		# 1文字ずつ追加
		if displayed_text.length() > 0:
			dialogue_text.text += displayed_text[displayed_text.length() - 1]
	else:
		print("Error: dialogue_text is null in _update_displayed_text()")

# テキストを表示する関数（新しいページの開始）
func show_text(text, speaker_name = ""):
	print("Showing text: ", text)
	current_text = text
	displayed_text = ""
	is_text_completed = false
	text_timer = 0
	
	# ページバッファをリセット
	page_text_buffer = []
	current_page_index = 0
	
	# 現在のテキストをバッファに追加
	page_text_buffer.append({
		"text": text,
		"speaker": speaker_name
	})
	
	# 「続きあり」インジケータを非表示にする
	if more_indicator:
		more_indicator.visible = false
	
	if dialogue_text:
		dialogue_text.visible = true
		# テキストを完全にクリア
		dialogue_text.text = ""
		
		# 話者名があれば追加
		if speaker_name != "":
			dialogue_text.text = "[color=#FFDD00][b]" + speaker_name + "[/b][/color]\n\n"
		
		# テキストパネルが非表示になっていたら表示
		if text_panel:
			text_panel.visible = true
	else:
		print("Error: dialogue_text is null in show_text()")

# 同じページに文を追加表示する関数
func show_text_same_page(text, speaker_name = ""):
	print("Showing additional text in the same page: ", text)
	
	# 新しい文章をバッファに追加
	add_to_page_buffer(text, speaker_name)
	
	# 現在のテキストを保存して続きを表示する
	var last_text = page_text_buffer[current_page_index]
	current_text = last_text["text"]
	displayed_text = ""
	is_text_completed = false
	text_timer = 0
	
	# 「続きあり」インジケータを非表示にする
	if more_indicator:
		more_indicator.visible = false
	
	if dialogue_text:
		# 現在の話者名を追加
		if speaker_name != "":
			# 改行を追加して話者名を設定
			dialogue_text.text = dialogue_text.text + "\n\n[color=#FFDD00][b]" + speaker_name + "[/b][/color]\n\n"
		else:
			# 話者名なしの場合は単に改行を追加
			dialogue_text.text = dialogue_text.text + "\n\n"
	else:
		print("Error: dialogue_text is null in show_text_same_page()")

# テキストを一気に表示する関数（クリック時など）
func complete_text():
	if not is_text_completed:
		# まだテキストが表示中なら、一気に表示
		displayed_text = current_text
		_update_displayed_text()
		is_text_completed = true
		
		# テキスト表示完了後に「続きあり」インジケータを表示（次のテキストがある場合のみ）
		if more_indicator:
			more_indicator.visible = current_page_index < page_text_buffer.size() - 1
			
		print("Text display completed.")
	else:
		# テキストが表示済みの場合
		if current_page_index < page_text_buffer.size() - 1:
			# まだ表示する文がある場合、同じページ内の次のテキストへ
			current_page_index += 1
			var next_text = page_text_buffer[current_page_index]
			
			# 次のテキストを設定
			current_text = next_text["text"]
			displayed_text = ""
			is_text_completed = false
			text_timer = 0
			
			# 話者名があれば追加（保持しているテキストの後に）
			if next_text["speaker"] != "":
				# 改行を追加して話者名を設定
				dialogue_text.text = dialogue_text.text + "\n\n[color=#FFDD00][b]" + next_text["speaker"] + "[/b][/color]\n\n"
			else:
				# 話者名なしの場合は単に改行を追加
				dialogue_text.text = dialogue_text.text + "\n\n"
				
			# 「続きあり」インジケータを非表示にする
			if more_indicator:
				more_indicator.visible = false
				
			print("Starting next text in the same page.")
		else:
			# バッファ内のテキストをすべて表示したので次のシナリオへ
			print("All text displayed, advancing to next scenario.")
			# 「続きあり」インジケータを非表示
			if more_indicator:
				more_indicator.visible = false
			# バッファをリセット
			page_text_buffer = []
			current_page_index = 0
			
			# テストシナリオがある場合はシナリオを進める
			if has_node("test_scenario"):
				$test_scenario.on_text_completed()

# 背景を変更する関数
func change_background(background_path):
	current_background = background_path
	print("Loading background: ", background_path)
	
	var bg_texture = load(background_path)
	if bg_texture == null:
		print("ERROR: Failed to load background texture from path: ", background_path)
		return
		
	print("Loaded texture: ", bg_texture)
	
	if background != null:
		# モジュレートカラーを確認/設定
		background.modulate = Color(1, 1, 1, 1)  # 完全不透明の白
		
		# テクスチャを設定
		background.texture = bg_texture
		background.visible = true
		
		print("Background properties:")
		print("- Visible: ", background.visible)
		print("- Modulate: ", background.modulate)
		print("- Size: ", background.size)
		print("- Global position: ", background.global_position)
		
		_setup_fullscreen_element(background)
		print("Background changed successfully.")
	else:
		print("ERROR: Background node is null")

# キャラクターを表示する関数
func show_character(character_id, character_path, position = Vector2(512, 300)):
	print("Showing character: ", character_id, " at path: ", character_path)
	
	if not character_id in current_characters:
		var character_sprite = TextureRect.new()
		character_sprite.name = character_id
		characters_container.add_child(character_sprite)
		current_characters[character_id] = character_sprite
		print("Created new character sprite: ", character_id)
	
	var character = current_characters[character_id]
	
	# パスが相対パスかどうかを確認
	var character_texture
	if character_path.begins_with("res://"):
		character_texture = load(character_path)
	else:
		character_texture = load("res://assets/characters/" + character_path)
	
	if character_texture != null:
		character.texture = character_texture
		character.expand = true
		character.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		
		# サイズ設定
		character.custom_minimum_size = Vector2(300, 600)  # 適切なサイズに調整
		
		# 位置設定: キャラクターの中心を指定位置に
		var char_width = character.custom_minimum_size.x
		var char_height = character.custom_minimum_size.y
		
		# アンカーを左上に設定
		character.anchor_left = 0
		character.anchor_top = 0
		character.anchor_right = 0
		character.anchor_bottom = 0
		
		# 位置を中心に調整
		character.offset_left = position.x - char_width / 2
		character.offset_top = position.y - char_height / 2
		character.offset_right = position.x + char_width / 2
		character.offset_bottom = position.y + char_height / 2
		
		character.visible = true
		print("Character displayed: ", character_id, " at position ", position)
	else:
		print("ERROR: Failed to load character texture: ", character_path)

# キャラクターを非表示にする関数
func hide_character(character_id):
	if character_id in current_characters:
		current_characters[character_id].queue_free()
		current_characters.erase(character_id)
		print("Character hidden: ", character_id)
	else:
		print("Warning: Attempted to hide non-existent character: ", character_id)

# BGMを再生する関数
func play_bgm(bgm_path):
	if bgm_player == null:
		print("ERROR: bgm_player is null")
		return
		
	if current_bgm != bgm_path:
		current_bgm = bgm_path
		
		# パスが相対パスかどうかを確認
		var audio_stream
		if bgm_path.begins_with("res://"):
			audio_stream = load(bgm_path)
		else:
			audio_stream = load("res://assets/audio/bgm/" + bgm_path)
		
		if audio_stream != null:
			bgm_player.stream = audio_stream
			bgm_player.play()
			print("BGM playing: ", bgm_path)
		else:
			print("ERROR: Failed to load audio: ", bgm_path)

# BGMを停止する関数
func stop_bgm():
	if bgm_player != null:
		bgm_player.stop()
		current_bgm = ""
		print("BGM stopped")

# 効果音を再生する関数
func play_sfx(sfx_path):
	if sfx_player == null:
		print("ERROR: sfx_player is null")
		return

	# パスが相対パスかどうかを確認
	var audio_stream
	if sfx_path.begins_with("res://"):
		audio_stream = load(sfx_path)
	else:
		audio_stream = load("res://assets/audio/sfx/" + sfx_path)
	
	if audio_stream != null:
		sfx_player.stream = audio_stream
		sfx_player.play()
		print("SFX playing: ", sfx_path)
	else:
		print("ERROR: Failed to load audio: ", sfx_path)

# ページバッファにテキストを追加する関数
func add_to_page_buffer(text, speaker_name = ""):
	page_text_buffer.append({
		"text": text,
		"speaker": speaker_name
	})

# テキストページをクリアする関数（新規ページ作成時に使用）
func clear_text_page():
	page_text_buffer = []
	current_page_index = 0
	if dialogue_text:
		dialogue_text.text = ""
	if more_indicator:
		more_indicator.visible = false
	print("Text page cleared")

# 入力処理
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			complete_text()
			print("Mouse click detected - text advanced")
