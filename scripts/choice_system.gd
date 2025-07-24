# ChoiceSystem.gd
# 保存先: res://scripts/ChoiceSystem.gd

extends Control

# シグナル定義
signal choice_made(choice_id)

# スタイリング設定
var choice_text_color = Color(1, 1, 1, 1)
var choice_text_hover_color = Color(1, 0.8, 0, 1)  # 弟切草風の黄色いハイライト
var choice_text_size = 22
var selected_choice_index = -1

# 選択肢データ
var current_choices = []
var choice_labels = []  # 選択肢ラベル (プレフィックス + テキスト全体)
var choice_container
var choice_background

# フォント設定
var choice_font

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
	_create_text_styles()
	log_message("Choice system initialized directly", LogLevel.INFO)

func _on_novel_system_initialized():
	# 選択肢コンテナの初期化
	_initialize_choice_container()
	_create_text_styles()
	log_message("Choice system initialized", LogLevel.INFO)

# 選択肢コンテナの初期化
func _initialize_choice_container():
	# 既存のコンテナがあれば削除
	if choice_container and is_instance_valid(choice_container):
		choice_container.queue_free()
		
	choice_container = Control.new()
	choice_container.name = "choice_container"
	choice_container.anchor_left = 0.0
	choice_container.anchor_top = 0.0
	choice_container.anchor_right = 1.0
	choice_container.anchor_bottom = 1.0
	choice_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	choice_container.visible = false
	
	add_child(choice_container)
	
	# 全画面背景の作成 - より弟切草に近い暗い背景
	choice_background = ColorRect.new()
	choice_background.name = "choice_background"
	choice_background.anchor_left = 0.0
	choice_background.anchor_top = 0.0
	choice_background.anchor_right = 1.0
	choice_background.anchor_bottom = 1.0
	choice_background.color = Color(0, 0, 0, 0.7) 
	
	choice_container.add_child(choice_background)
	log_message("Choice container created", LogLevel.DEBUG)

# テキストスタイルの作成
func _create_text_styles():
	# フォントをロード（プロジェクトにフォントがある場合）
	var font_path = "res://fonts/gothic.tres"
	if ResourceLoader.exists(font_path):
		choice_font = load(font_path)
		log_message("Choice font loaded", LogLevel.DEBUG)
	
	# ノベルシステムからフォントを取得（フォント統一のため）
	if novel_system and novel_system.dialogue_text and novel_system.dialogue_text.get_theme_font("normal_font"):
		choice_font = novel_system.dialogue_text.get_theme_font("normal_font")
		log_message("Using dialogue text font for choices", LogLevel.DEBUG)
	
	log_message("Text styles created", LogLevel.DEBUG)

# 選択肢の表示
func show_choices(choices):
	log_message("show_choices called with " + str(choices.size()) + " choices", LogLevel.INFO)
	log_message("choice_container visible: " + str(choice_container != null) + ", parent: " + str(get_parent().name), LogLevel.INFO)

	# 現在の選択肢をクリア
	_clear_choices()
	
	# ノベルシステムのテキストパネルは残して、テキストだけを非表示
	if novel_system and novel_system.dialogue_text:
		novel_system.dialogue_text.visible = false
	if novel_system and novel_system.text_panel:
		novel_system.text_panel.visible = true  # パネル自体は表示したまま
	
	current_choices = choices
	if choice_container:
		choice_container.visible = true
		log_message("Set choice_container to visible", LogLevel.INFO)
	else:
		log_message("ERROR: choice_container is null!", LogLevel.ERROR)
		return  # コンテナがなければ終了
	
	# 弟切草スタイルの選択肢作成
	var choice_prefixes = ["Ａ", "Ｂ", "Ｃ", "Ｄ", "Ｅ"]
	var total_choices = min(choices.size(), choice_prefixes.size())
	
	# 選択ページのタイトル表示 - より弟切草風に
	var title_label = Label.new()
	title_label.name = "title_label"
	title_label.text = "どうする？"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	
	var viewport_size = get_viewport_rect().size
	title_label.position.x = viewport_size.x * 0.1  # 左マージン10%
	title_label.position.y = viewport_size.y * 0.1  # 上マージン10%
	title_label.size.x = viewport_size.x * 0.8      # 幅80%
	title_label.size.y = 40          

	title_label.add_theme_font_size_override("font_size", 24) 
	title_label.add_theme_color_override("font_color", Color(1, 1, 1))
	
	# タイトルにもメインのフォントを適用
	if choice_font:
		title_label.add_theme_font_override("font", choice_font)
	
	choice_container.add_child(title_label)
	
	# 選択肢の配置計算（弟切草スタイル - 画面下部固定）
	var choice_spacing = 50
	var start_y = viewport_size.y * 0.1 + 80  # タイトルの下から開始0
	
	for i in range(total_choices):
		var choice_data = choices[i]
		var choice_id = choice_data.get("id", str(i))
		var choice_text = choice_data.get("text", "選択肢 " + str(i+1))
		
		# 選択肢全体を含むコンテナを作成
		var choice_panel = Control.new()
		choice_panel.position.x = viewport_size.x * 0.1  # 左マージン10%
		choice_panel.position.y = start_y + (choice_spacing * i)
		choice_panel.size.x = viewport_size.x * 0.8      # 幅80%
		choice_panel.size.y = 40  
		
		choice_container.add_child(choice_panel)
		
		# ここでボタンを使用する代わりに
		var button = Button.new()
		button.name = "choice_button_" + str(i)
		button.text = ""
		button.flat = true
		button.focus_mode = Control.FOCUS_NONE
		button.position = Vector2.ZERO
		button.size = choice_panel.size
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		
		# ボタン背景を完全に透明に
		var normal_style = StyleBoxEmpty.new()
		var hover_style = StyleBoxEmpty.new()
		var pressed_style = StyleBoxEmpty.new()
		
		button.add_theme_stylebox_override("normal", normal_style)
		button.add_theme_stylebox_override("hover", hover_style)
		button.add_theme_stylebox_override("pressed", pressed_style)
		
		# ボタンのシグナル接続
		button.pressed.connect(_on_choice_button_pressed.bind(choice_id))
		button.mouse_entered.connect(_on_choice_button_mouse_entered.bind(i))
		
		choice_panel.add_child(button)
		
		# 弟切草風の選択肢ラベル作成 - ボタンの上にラベルを重ねる
		var label = Label.new()
		label.name = "choice_label_" + str(i)
		label.text = choice_prefixes[i] + "　" + choice_text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.position = Vector2.ZERO
		label.size = choice_panel.size
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# スタイル設定
		label.add_theme_font_size_override("font_size", choice_text_size)
		label.add_theme_color_override("font_color", choice_text_color)
		if choice_font:
			label.add_theme_font_override("font", choice_font)
		
		choice_panel.add_child(label)
		choice_labels.append(label)
		
		log_message("Added choice label: " + choice_text + " with ID: " + choice_id, LogLevel.INFO)
	
	# キーボード選択のための初期設定
	selected_choice_index = 0
	_update_choice_highlight()
	
	# 選択肢表示のデバッグログ
	log_message("Choices now visible: " + str(choice_container.visible) + 
				" with " + str(choice_labels.size()) + " labels", LogLevel.INFO)

func _on_choice_button_pressed(choice_id):
	_select_choice(choice_id)

func _on_choice_button_mouse_entered(choice_index):
	if selected_choice_index != choice_index:
		selected_choice_index = choice_index
		_update_choice_highlight()

func _select_choice(choice_id):
	log_message("Choice selected: " + choice_id, LogLevel.INFO)
	
	# 選択肢を非表示に
	choice_container.visible = false
	
	# テキストパネルを再表示（選択後にテキストを表示するため）
	if novel_system and novel_system.dialogue_text:
		novel_system.dialogue_text.visible = true
	
	# 選択シグナルの発行
	choice_made.emit(choice_id)
	
	# 選択肢をクリア
	_clear_choices()

# 選択肢のクリア
func _clear_choices():
	for child in choice_container.get_children():
		if child != choice_background:  # 背景は保持
			child.queue_free()
	
	choice_labels.clear()
	current_choices.clear()
	selected_choice_index = -1
	
	log_message("Choices cleared", LogLevel.DEBUG)

# 選択肢ハイライトの更新
func _update_choice_highlight():
	for i in range(choice_labels.size()):
		if i == selected_choice_index:
			choice_labels[i].add_theme_color_override("font_color", choice_text_hover_color)
		else:
			choice_labels[i].add_theme_color_override("font_color", choice_text_color)

# キーボード入力処理
func _input(event):
	if not choice_container or not choice_container.visible or choice_labels.size() == 0:
		return
		
	if event is InputEventKey and event.pressed:
		var key_handled = true
		
		match event.keycode:
			KEY_UP:
				if selected_choice_index > 0:
					selected_choice_index -= 1
					_update_choice_highlight()
			KEY_DOWN:
				if selected_choice_index < choice_labels.size() - 1:
					selected_choice_index += 1
					_update_choice_highlight()
			KEY_ENTER, KEY_SPACE:
				if selected_choice_index >= 0 and selected_choice_index < current_choices.size():
					_select_choice(current_choices[selected_choice_index].get("id", str(selected_choice_index)))
			KEY_A:
				if choice_labels.size() >= 1:
					_select_choice(current_choices[0].get("id", "0"))
			KEY_B:
				if choice_labels.size() >= 2:
					_select_choice(current_choices[1].get("id", "1"))
			KEY_C:
				if choice_labels.size() >= 3:
					_select_choice(current_choices[2].get("id", "2"))
			KEY_D:
				if choice_labels.size() >= 4:
					_select_choice(current_choices[3].get("id", "3"))
			KEY_E:
				if choice_labels.size() >= 5:
					_select_choice(current_choices[4].get("id", "4"))
			_:
				key_handled = false
		
		if key_handled:
			get_viewport().set_input_as_handled()

# ログメッセージの出力（NovelSystemと同様のログ機能）
func log_message(message, level = LogLevel.INFO):
	if novel_system:
		novel_system.log_message("[ChoiceSystem] " + message, level)
	else:
		var prefix = ""
		match level:
			LogLevel.INFO:
				prefix = "[INFO] "
			LogLevel.DEBUG:
				prefix = "[DEBUG] "
			LogLevel.ERROR:
				prefix = "[ERROR] "
		
		print(prefix + "[ChoiceSystem] " + message)
