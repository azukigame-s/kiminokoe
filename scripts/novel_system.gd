extends Control

# シグナル定義
signal initialized
signal text_click_processed

# テキスト表示関連の変数
var current_text = ""
var displayed_text = ""
var text_speed = 0.05
var is_text_completed = true
var text_timer = 0.0
var page_text_buffer = []
var current_page_index = 0

# 背景・音声関連
var current_background = ""
var current_bgm = ""

# インジケーター関連
var show_indicator = false
var indicator_symbol = "⏎"
var page_indicator_symbol = "⎘"
var indicator_visible = true
var indicator_blink_timer = 0.0
var indicator_blink_speed = 0.5

# ノード参照
@onready var background = $background
@onready var text_panel = $text_panel
@onready var dialogue_text = $text_panel/dialogue_text if has_node("text_panel") else null
@onready var bgm_player = $bgm_player
@onready var sfx_player = $sfx_player

func _ready():
	print("Visual Novel System: Ready function called.")
	
	# 画面サイズの設定
	size_flags_horizontal = Control.SIZE_FILL
	size_flags_vertical = Control.SIZE_FILL
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	await get_tree().process_frame
	print("Updated Control size after frame: ", size)
	
	_check_nodes()
	
	if background:
		_setup_fullscreen_element(background)
		print("Background setup complete. Size: ", background.size)
	
	_setup_text_panel()
	
	initialized.emit()

func _check_nodes():
	print("Checking node references:")
	print("- Background node: ", background)
	print("- Text panel: ", text_panel)
	print("- Dialogue text node: ", dialogue_text)
	print("- BGM player: ", bgm_player)
	print("- SFX player: ", sfx_player)
	print("Control size: ", size)
	
	if not background:
		print("ERROR: Background node missing. Create a TextureRect named 'background' as a child of this Control node.")
	
	if not text_panel:
		print("ERROR: Text panel missing. Create a Panel or Control named 'text_panel' as a child of this Control node.")
	
	if not dialogue_text and text_panel:
		print("ERROR: Dialogue text node missing. Create a RichTextLabel named 'dialogue_text' as a child of the text_panel.")

func _setup_text_panel():
	if text_panel:
		# かまいたちの夜スタイルのテキストパネル設定
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
		style_box.bg_color = Color(0, 0, 0, 0.5)
		text_panel.add_theme_stylebox_override("panel", style_box)
		
		print("Text panel setup complete for Kamaitachi style. Size: ", text_panel.size)
	
	if dialogue_text:
		dialogue_text.bbcode_enabled = true
		dialogue_text.visible = true
		
		# テキストを画面中央に配置
		dialogue_text.anchor_left = 0.1
		dialogue_text.anchor_top = 0.1
		dialogue_text.anchor_right = 0.9
		dialogue_text.anchor_bottom = 0.9
		dialogue_text.offset_left = 0
		dialogue_text.offset_top = 0
		dialogue_text.offset_right = 0
		dialogue_text.offset_bottom = 0
		
		dialogue_text.add_theme_color_override("default_color", Color(1, 1, 1, 1))
		dialogue_text.add_theme_font_size_override("normal_font_size", 24)
		
		print("Dialogue text setup complete for Kamaitachi style. Size: ", dialogue_text.size)
		
		var custom_theme = load("res://themes/novel_theme.tres")
		if custom_theme:
			dialogue_text.theme = custom_theme
			print("Custom theme applied to dialogue text")

func _setup_fullscreen_element(element):
	element.anchor_left = 0.0
	element.anchor_top = 0.0
	element.anchor_right = 1.0
	element.anchor_bottom = 1.0
	
	element.offset_left = 0
	element.offset_top = 0
	element.offset_right = 0
	element.offset_bottom = 0
	
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
			else:
				is_text_completed = true
				show_indicator = true
				_update_displayed_text()
	
	# インジケーターの点滅処理
	if is_text_completed and show_indicator:
		indicator_blink_timer += delta
		if indicator_blink_timer >= indicator_blink_speed:
			indicator_blink_timer = 0
			indicator_visible = !indicator_visible
			_update_displayed_text()
		
func _update_displayed_text():
	if dialogue_text:
		var base_text = ""
		
		if current_page_index > 0:
			base_text = dialogue_text.text
			var last_text_start = base_text.rfind("\n\n")
			if last_text_start != -1:
				var next_line = base_text.find("\n\n", last_text_start + 2)
				if next_line != -1 and base_text.find("[color=#FFDD00][b]", last_text_start) != -1:
					base_text = base_text.substr(0, next_line + 2)
				else:
					base_text = base_text.substr(0, last_text_start + 2)
		
		if current_page_index == 0:
			var text_parts = dialogue_text.text.split("\n\n", false, 1)
			if text_parts.size() > 0 and text_parts[0].begins_with("[color=#FFDD00][b]"):
				base_text = text_parts[0] + "\n\n"
		
		var final_text = base_text + displayed_text
		
		if is_text_completed and show_indicator and indicator_visible:
			final_text += _get_indicator_symbol()
		
		dialogue_text.text = final_text

func show_text(text, go_next = false):
	print("Showing text: ", text)
	current_text = text
	displayed_text = ""
	is_text_completed = false
	text_timer = 0
	
	page_text_buffer = []
	current_page_index = 0
	
	page_text_buffer.append({
		"text": text,
		"go_next": go_next
	})
	
	if dialogue_text:
		dialogue_text.visible = true
		dialogue_text.text = ""
		
		if text_panel:
			text_panel.visible = true
	else:
		print("Error: dialogue_text is null in show_text()")

func show_text_same_page(text):
	print("Showing additional text in the same page: ", text)
	
	current_text = text
	displayed_text = ""
	is_text_completed = false
	text_timer = 0
	
	if dialogue_text:
		var current_displayed = dialogue_text.text
		
		if current_displayed != "":
			current_displayed += "\n\n"
		
		dialogue_text.text = current_displayed
	else:
		print("Error: dialogue_text is null in show_text_same_page()")

func _get_indicator_symbol():
	if current_page_index < page_text_buffer.size():
		var current_item = page_text_buffer[current_page_index]
		if current_item.get("go_next", false):
			return page_indicator_symbol
		
	return indicator_symbol
	
func clear_text_buffers():
	page_text_buffer = []
	current_page_index = 0
	is_text_completed = true
	current_text = ""
	displayed_text = ""
	
	if dialogue_text:
		dialogue_text.text = ""
	
	print("All text buffers cleared")

func has_more_text_in_buffer():
	return current_page_index < page_text_buffer.size() - 1

func display_next_text_from_buffer():
	if has_more_text_in_buffer():
		current_page_index += 1
		var next_text = page_text_buffer[current_page_index]
		show_text_same_page(next_text["text"])
		return true
	return false

func complete_text_display():
	if not is_text_completed:
		displayed_text = current_text
		is_text_completed = true
		show_indicator = true
		_update_displayed_text()
		print("Text display completed instantly")
		
func complete_text():
	if not is_text_completed:
		complete_text_display()
	else:
		if has_more_text_in_buffer():
			display_next_text_from_buffer()
		else:
			print("All text in buffer displayed")
			show_indicator = false
			_update_displayed_text()
			
			if has_node("test_scenario"):
				$test_scenario.on_click_received()

func change_background(background_path):
	current_background = background_path
	print("Loading background: ", background_path)
	
	var bg_texture = load(background_path)
	if bg_texture == null:
		print("ERROR: Failed to load background texture from path: ", background_path)
		return
		
	print("Loaded texture: ", bg_texture)
	
	if background != null:
		background.modulate = Color(1, 1, 1, 1)
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

func play_bgm(bgm_path):
	if bgm_player == null:
		print("ERROR: bgm_player is null")
		return
		
	if current_bgm != bgm_path:
		current_bgm = bgm_path
		
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

func stop_bgm():
	if bgm_player != null:
		bgm_player.stop()
		current_bgm = ""
		print("BGM stopped")

func play_sfx(sfx_path):
	if sfx_player == null:
		print("ERROR: sfx_player is null")
		return

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

func add_to_page_buffer(text, go_next = false):
	page_text_buffer.append({
		"text": text,
		"go_next": go_next
	})
	print("Added to page buffer: ", text)
	print("Current buffer size: ", page_text_buffer.size())

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			complete_text()
			print("Mouse click detected - text advanced")
			
			if has_node("test_scenario") and is_text_completed:
				$test_scenario.on_click_received()
