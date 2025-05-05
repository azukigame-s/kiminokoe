# ChoiceSystem.gd
# 保存先: res://scripts/ChoiceSystem.gd

extends Control

# シグナル定義
signal choice_made(choice_id)

# スタイリング設定
var choice_button_style: StyleBoxFlat
var choice_button_hover_style: StyleBoxFlat
var selected_choice_index = -1

# 選択肢データ
var current_choices = []
var choice_buttons = []
var choice_container

# ノード参照
@onready var novel_system = get_parent()

# シグナルのエイリアス定義
enum LogLevel {INFO, DEBUG, ERROR}

func _ready():
	print("ChoiceSystem _ready called")
	
	# ノベルシステムの参照を取得
	novel_system = get_parent()
	if novel_system:
		log_message("Got parent: " + novel_system.name, LogLevel.INFO)
		
		# 初期化シグナルの接続
		if not novel_system.initialized.is_connected(_on_novel_system_initialized):
			novel_system.initialized.connect(_on_novel_system_initialized)
			log_message("Connected to initialized signal", LogLevel.INFO)
	else:
		log_message("ERROR: Failed to get parent node", LogLevel.ERROR)
	
	# コンテナを直接初期化（シグナルを待たない）
	_initialize_choice_container()
	_create_button_styles()
	log_message("Choice system initialized directly", LogLevel.INFO)

func _on_novel_system_initialized():
	# 選択肢コンテナの初期化
	_initialize_choice_container()
	_create_button_styles()
	log_message("Choice system initialized", LogLevel.INFO)

# 選択肢コンテナの初期化
func _initialize_choice_container():
	choice_container = Control.new()
	choice_container.name = "choice_container"
	choice_container.anchor_left = 0.0
	choice_container.anchor_top = 0.7
	choice_container.anchor_right = 1.0
	choice_container.anchor_bottom = 1.0
	choice_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	choice_container.visible = false
	
	add_child(choice_container)
	log_message("Choice container created", LogLevel.DEBUG)

# ボタンスタイルの作成
func _create_button_styles():
	# 通常のボタンスタイル
	choice_button_style = StyleBoxFlat.new()
	choice_button_style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	choice_button_style.border_width_bottom = 2
	choice_button_style.border_color = Color(0.7, 0.7, 0.7)
	choice_button_style.content_margin_left = 20
	choice_button_style.content_margin_top = 10
	choice_button_style.content_margin_right = 20
	choice_button_style.content_margin_bottom = 10
	
	# ホバー時のボタンスタイル
	choice_button_hover_style = StyleBoxFlat.new()
	choice_button_hover_style.bg_color = Color(0.3, 0.3, 0.3, 0.9)
	choice_button_hover_style.border_width_bottom = 2
	choice_button_hover_style.border_color = Color(1, 1, 1)
	choice_button_hover_style.content_margin_left = 20
	choice_button_hover_style.content_margin_top = 10
	choice_button_hover_style.content_margin_right = 20
	choice_button_hover_style.content_margin_bottom = 10
	
	log_message("Button styles created", LogLevel.DEBUG)

# 選択肢の表示
func show_choices(choices):
	log_message("show_choices called with " + str(choices.size()) + " choices", LogLevel.INFO)
	log_message("choice_container visible: " + str(choice_container != null) + ", parent: " + str(get_parent().name), LogLevel.INFO)

	# 現在の選択肢をクリア
	_clear_choices()
	
	current_choices = choices
	if choice_container:
		choice_container.visible = true
		log_message("Set choice_container to visible", LogLevel.INFO)
	else:
		log_message("ERROR: choice_container is null!", LogLevel.ERROR)
	
	# 弟切草スタイルの選択肢作成
	var choice_labels = ["Ａ", "Ｂ", "Ｃ", "Ｄ", "Ｅ"]
	var button_height = 50
	var button_spacing = 10
	var total_buttons = min(choices.size(), choice_labels.size())
	
	# 画面下部にボタンを配置するための計算
	var viewport_size = get_viewport_rect().size
	var total_height = (button_height + button_spacing) * total_buttons
	var start_y = viewport_size.y - total_height - 50  # 下部からのマージン
	
	for i in range(total_buttons):
		var choice_data = choices[i]
		var choice_id = choice_data.get("id", str(i))
		var choice_text = choice_data.get("text", "選択肢 " + str(i+1))
		
		# ボタン作成
		var button = Button.new()
		button.name = "choice_button_" + str(i)
		button.text = choice_labels[i] + "： " + choice_text
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		# ボタンのスタイリング
		button.add_theme_stylebox_override("normal", choice_button_style)
		button.add_theme_stylebox_override("hover", choice_button_hover_style)
		button.add_theme_stylebox_override("focus", choice_button_hover_style)
		button.add_theme_font_size_override("font_size", 20)
		
		# ボタンの配置（下から上に配置）
		button.position = Vector2(50, start_y + (button_height + button_spacing) * i)
		button.size = Vector2(viewport_size.x - 100, button_height)
		
		choice_container.add_child(button)
		choice_buttons.append(button)
		
		# シグナル接続
		button.pressed.connect(_on_choice_button_pressed.bind(choice_id))
		
		log_message("Added choice button: " + choice_text + " with ID: " + choice_id, LogLevel.INFO)
	
	# キーボード選択のためのフォーカス設定
	if choice_buttons.size() > 0:
		choice_buttons[0].grab_focus()
		selected_choice_index = 0
		
	# 選択肢表示のデバッグログ
	log_message("Choices now visible: " + str(choice_container.visible) + 
				" with " + str(choice_buttons.size()) + " buttons", LogLevel.INFO)

func _on_choice_button_pressed(choice_id):
	log_message("Choice selected: " + choice_id, LogLevel.INFO)
	
	# 選択肢を非表示に
	choice_container.visible = false
	
	# 選択シグナルの発行
	choice_made.emit(choice_id)
	
	# 選択肢をクリア
	_clear_choices()

# 選択肢のクリア
func _clear_choices():
	for button in choice_buttons:
		if is_instance_valid(button):
			button.queue_free()
	
	choice_buttons.clear()
	current_choices.clear()
	selected_choice_index = -1
	
	log_message("Choices cleared", LogLevel.DEBUG)

# キーボード入力処理
func _input(event):
	if not choice_container.visible or choice_buttons.size() == 0:
		return
		
	if event is InputEventKey and event.pressed:
		var key_handled = false
		
		match event.keycode:
			KEY_UP:
				if selected_choice_index > 0:
					selected_choice_index -= 1
					choice_buttons[selected_choice_index].grab_focus()
					key_handled = true
			KEY_DOWN:
				if selected_choice_index < choice_buttons.size() - 1:
					selected_choice_index += 1
					choice_buttons[selected_choice_index].grab_focus()
					key_handled = true
			KEY_A:
				if choice_buttons.size() >= 1:
					_on_choice_button_pressed(current_choices[0].get("id", "0"))
					key_handled = true
			KEY_B:
				if choice_buttons.size() >= 2:
					_on_choice_button_pressed(current_choices[1].get("id", "1"))
					key_handled = true
			KEY_C:
				if choice_buttons.size() >= 3:
					_on_choice_button_pressed(current_choices[2].get("id", "2"))
					key_handled = true
			KEY_D:
				if choice_buttons.size() >= 4:
					_on_choice_button_pressed(current_choices[3].get("id", "3"))
					key_handled = true
			KEY_E:
				if choice_buttons.size() >= 5:
					_on_choice_button_pressed(current_choices[4].get("id", "4"))
					key_handled = true
		
		if key_handled:
			get_viewport().set_input_as_handled()

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
