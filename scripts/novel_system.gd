extends Control

# _ready 完了シグナル
signal initialized
# クリック処理完了シグナル
signal text_click_processed

# テキスト表示関連の変数
var current_text = ""
var displayed_text = ""
var text_speed = 0.05  # 文字表示速度（秒）
var is_text_completed = true
var text_timer = 0.0
var page_text_buffer = []  # 現在のページに表示するテキストのバッファ
var current_page_index = 0  # ページ内の現在位置

# 背景関連
var current_background = ""

# 音声関連
var current_bgm = ""

# インジケーターの状態を示す変数
var show_indicator = false
var indicator_symbol = "⏎"  # 文字送り用
var page_indicator_symbol = "⎘"  # ページ送り用

var indicator_visible = true  # インジケーターの表示/非表示状態
var indicator_blink_timer = 0.0  # 点滅タイマー
var indicator_blink_speed = 0.5  # 点滅の速さ（秒）

# ノード参照
@onready var background = $background
@onready var text_panel = $text_panel
@onready var dialogue_text = $text_panel/dialogue_text if has_node("text_panel") else null
@onready var bgm_player = $bgm_player
@onready var sfx_player = $sfx_player

func _ready():
	print("Visual Novel System: Ready function called.")
	
	# サイズを明示的に設定
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
	_setup_text_panel()
	
	# 初期化完了のシグナルを発行
	initialized.emit()

# ノード参照を確認するヘルパー関数
func _check_nodes():
	print("Checking node references:")
	print("- Background node: ", background)
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

# テキストパネルのセットアップ
func _setup_text_panel():
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
			else:
				is_text_completed = true
				show_indicator = true  # インジケーターを表示
				_update_displayed_text()
	
	# インジケーターの点滅処理
	if is_text_completed and show_indicator:
		indicator_blink_timer += delta
		if indicator_blink_timer >= indicator_blink_speed:
			indicator_blink_timer = 0
			indicator_visible = !indicator_visible  # 表示状態を反転
			_update_displayed_text()  # テキスト表示を更新
		
# 現在表示すべきテキストを更新する関数
func _update_displayed_text():
	if dialogue_text:
		var base_text = ""
		
		# 話者名やすでにバッファにある内容を取得
		if current_page_index > 0:
			# 前のページ内容を保持
			base_text = dialogue_text.text
			# 最後の文章の表示部分のみを置き換える（現在表示中の文のプレフィクス部分を見つける）
			var last_text_start = base_text.rfind("\n\n")
			if last_text_start != -1:
				# 話者名が含まれているか確認
				var next_line = base_text.find("\n\n", last_text_start + 2)
				if next_line != -1 and base_text.find("[color=#FFDD00][b]", last_text_start) != -1:
					# 話者名を含む場合、その後の改行までをベーステキストとする
					base_text = base_text.substr(0, next_line + 2)
				else:
					# 話者名を含まない場合、最後の改行までをベーステキストとする
					base_text = base_text.substr(0, last_text_start + 2)
		
		# 話者名がある場合は最初に追加
		if current_page_index == 0:
			var text_parts = dialogue_text.text.split("\n\n", false, 1)
			if text_parts.size() > 0 and text_parts[0].begins_with("[color=#FFDD00][b]"):
				base_text = text_parts[0] + "\n\n"
		
		# 最終的なテキストを設定（インジケーター付き）
		var final_text = base_text + displayed_text
		
		# インジケーター表示（点滅エフェクト）
		if is_text_completed and show_indicator and indicator_visible:
			final_text += _get_indicator_symbol()
		
		dialogue_text.text = final_text

# テキストを表示する関数（新しいページの開始）
func show_text(text, go_next = false):
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
		"go_next": go_next
	})
	
	if dialogue_text:
		dialogue_text.visible = true
		# テキストを完全にクリア
		dialogue_text.text = ""
		
		# テキストパネルが非表示になっていたら表示
		if text_panel:
			text_panel.visible = true
	else:
		print("Error: dialogue_text is null in show_text()")

# 同じページに文を追加表示する関数
func show_text_same_page(text):
	print("Showing additional text in the same page: ", text)
	
	# 新しい文章を設定
	current_text = text
	displayed_text = ""
	is_text_completed = false
	text_timer = 0
	
	if dialogue_text:
		# 現在のテキストを保存
		var current_displayed = dialogue_text.text
		
		# 話者名なしの場合は単に改行を追加（前のテキストがある場合のみ）
		if current_displayed != "":
			current_displayed += "\n\n"
		
		# 基本テキストを設定（文字送りのベースとなる）
		dialogue_text.text = current_displayed
	else:
		print("Error: dialogue_text is null in show_text_same_page()")

# インジケータのシンボルを決定する関数
func _get_indicator_symbol():
	# 現在のテキストが「次へ」を示す場合
	if current_page_index < page_text_buffer.size():
		var current_item = page_text_buffer[current_page_index]
		if current_item.get("go_next", false):
			return page_indicator_symbol  # ページ送り用インジケータ
	
	# バッファにさらにテキストがある場合も「次へ」インジケータ
	if has_more_text_in_buffer():
		return page_indicator_symbol  # ページ送り用インジケータ
		
	# それ以外は通常の文字送りインジケータ
	return indicator_symbol
	
# バッファをクリアする関数
func clear_text_buffers():
	page_text_buffer = []
	current_page_index = 0
	is_text_completed = true
	current_text = ""
	displayed_text = ""
	
	# テキストディスプレイをクリア
	if dialogue_text:
		dialogue_text.text = ""
	
	print("All text buffers cleared")

# バッファに次のテキストがあるかチェック
func has_more_text_in_buffer():
	return current_page_index < page_text_buffer.size() - 1

# バッファから次のテキストを表示
func display_next_text_from_buffer():
	if has_more_text_in_buffer():
		current_page_index += 1
		var next_text = page_text_buffer[current_page_index]
		show_text_same_page(next_text["text"])
		return true
	return false

# テキスト表示を即座に完了
func complete_text_display():
	if not is_text_completed:
		displayed_text = current_text
		is_text_completed = true
		show_indicator = true  # インジケーターを表示
		_update_displayed_text()
		print("Text display completed instantly")
		
# テキストを一気に表示する関数（クリック時など）
func complete_text():
	if not is_text_completed:
		# まだテキストが表示中なら、一気に表示
		complete_text_display()
	else:
		# テキストが表示済みの場合
		if has_more_text_in_buffer():
			# まだバッファにテキストがある場合、次を表示
			display_next_text_from_buffer()
		else:
			# バッファ内のすべてのテキストを表示し終えた
			print("All text in buffer displayed")
			# インジケーターを非表示にする
			show_indicator = false
			_update_displayed_text()
			
			# テストシナリオに通知
			if has_node("test_scenario"):
				$test_scenario.on_click_received()

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
func add_to_page_buffer(text, go_next = false):
	page_text_buffer.append({
		"text": text,
		"go_next": go_next
	})
	print("Added to page buffer: ", text)
	print("Current buffer size: ", page_text_buffer.size())

# 入力処理
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			complete_text()
			print("Mouse click detected - text advanced")
			
			# テストシナリオにクリックイベントを通知
			if has_node("test_scenario") and is_text_completed:
				$test_scenario.on_click_received()
