extends Control

# シグナル定義
signal initialized
signal text_click_processed
signal text_completed
signal choice_selected(choice_id)
signal subtitle_completed
signal background_fade_in_completed

# ログレベル定義
enum LogLevel {INFO, DEBUG, ERROR}
var current_log_level = LogLevel.INFO  # 本番環境ではERRORのみにするなど調整可能

# テキスト表示関連の変数
var current_text = ""
var displayed_text = ""
var page_text_buffer = []
var current_page_index = 0

# 背景・音声関連
var current_background = ""
var current_bgm = ""

# インジケータ関連
var show_indicator = false
var indicator_visible = true
var indicator_blink_timer = 0.0

# サブタイトル表示状態
var is_showing_subtitle = false

# 設定値 - ProjectSettingsから取得するように変更
var text_speed: float
var indicator_blink_speed: float
var indicator_symbol: String
var page_indicator_symbol: String
var is_text_completed = true
var text_timer = 0.0

# ノード参照
@onready var background = $background
@onready var text_panel = $text_panel
@onready var dialogue_text = $text_panel/dialogue_text if has_node("text_panel") else null
@onready var bgm_player = $bgm_player
@onready var sfx_player = $sfx_player
@onready var choice_system = $choice_system
@onready var subtitle_scene = $subtitle_scene if has_node("subtitle_scene") else null

func _ready():
	log_message("Visual Novel System: Ready function called.", LogLevel.INFO)
	
	# 設定の読み込み
	_load_settings()
	
	# 画面サイズの設定
	size_flags_horizontal = Control.SIZE_FILL
	size_flags_vertical = Control.SIZE_FILL
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	await get_tree().process_frame
	log_message("Updated Control size after frame: " + str(size), LogLevel.DEBUG)
	
	if _check_required_nodes():
		if background:
			_setup_fullscreen_element(background)
			log_message("Background setup complete. Size: " + str(background.size), LogLevel.DEBUG)
		
		_setup_text_panel()
		
		# 選択肢システムのセットアップ
		_setup_choice_system()
		
		# サブタイトルシステムのセットアップ
		_setup_subtitle_system()
		
		initialized.emit()
	else:
		log_message("Initialization failed due to missing required nodes", LogLevel.ERROR)

# 設定の読み込み - ProjectSettingsから取得
func _load_settings():
	# ProjectSettingsに設定がない場合のデフォルト値
	text_speed = ProjectSettings.get_setting("visual_novel/text_speed", 0.05)
	indicator_blink_speed = ProjectSettings.get_setting("visual_novel/indicator_blink_speed", 0.5)
	indicator_symbol = ProjectSettings.get_setting("visual_novel/indicator_symbol", "⏎")
	page_indicator_symbol = ProjectSettings.get_setting("visual_novel/page_indicator_symbol", "⎘")

# 必要なノードが揃っているかをチェック
func _check_required_nodes() -> bool:
	log_message("Checking node references:", LogLevel.DEBUG)
	log_message("- Background node: " + str(background), LogLevel.DEBUG)
	log_message("- Text panel: " + str(text_panel), LogLevel.DEBUG)
	log_message("- Dialogue text node: " + str(dialogue_text), LogLevel.DEBUG)
	log_message("- BGM player: " + str(bgm_player), LogLevel.DEBUG)
	log_message("- SFX player: " + str(sfx_player), LogLevel.DEBUG)
	
	var all_nodes_present = true
	
	if not background:
		log_message("ERROR: Background node missing. Create a TextureRect named 'background' as a child of this Control node.", LogLevel.ERROR)
		all_nodes_present = false
	
	if not text_panel:
		log_message("ERROR: Text panel missing. Create a Panel or Control named 'text_panel' as a child of this Control node.", LogLevel.ERROR)
		all_nodes_present = false
	
	if not dialogue_text and text_panel:
		log_message("ERROR: Dialogue text node missing. Create a RichTextLabel named 'dialogue_text' as a child of the text_panel.", LogLevel.ERROR)
		all_nodes_present = false
	
	return all_nodes_present

# テキストパネルのセットアップ
func _setup_text_panel():
	if not text_panel:
		return
		
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
	
	log_message("Text panel setup complete for Kamaitachi style. Size: " + str(text_panel.size), LogLevel.DEBUG)
	
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
		
		log_message("Dialogue text setup complete for Kamaitachi style. Size: " + str(dialogue_text.size), LogLevel.DEBUG)
		
		var custom_theme = load("res://themes/novel_theme.tres")
		if custom_theme:
			dialogue_text.theme = custom_theme
			log_message("Custom theme applied to dialogue text", LogLevel.DEBUG)

# 選択肢システムのセットアップ
func _setup_choice_system():
	# シグナル接続
	if choice_system:
		choice_system.choice_made.connect(_on_choice_made)
		# 選択肢システムの表示設定
		choice_system.visible = true
		choice_system.mouse_filter = Control.MOUSE_FILTER_IGNORE
		log_message("Choice system setup complete and set visible", LogLevel.INFO)
	else:
		log_message("ERROR: Choice system is null after setup", LogLevel.ERROR)

# サブタイトルシステムのセットアップ
func _setup_subtitle_system():
	log_message("Setting up subtitle system...", LogLevel.DEBUG)
	log_message("subtitle_scene exists: " + str(subtitle_scene != null), LogLevel.DEBUG)
	
	if subtitle_scene:
		log_message("subtitle_scene has script: " + str(subtitle_scene.get_script() != null), LogLevel.DEBUG)
		log_message("subtitle_scene has subtitle_completed signal: " + str(subtitle_scene.has_signal("subtitle_completed")), LogLevel.DEBUG)
		
		# サブタイトルスクリプトがアタッチされているかチェック
		if subtitle_scene.get_script() and subtitle_scene.has_signal("subtitle_completed"):
			subtitle_scene.subtitle_completed.connect(_on_subtitle_completed)
			# サブタイトルシーンを最前面に配置
			subtitle_scene.z_index = 100
			subtitle_scene.visible = false  # 初期状態では非表示
			log_message("Subtitle system setup complete", LogLevel.INFO)
		else:
			log_message("WARNING: Subtitle scene exists but script not attached - disabling subtitle functionality", LogLevel.INFO)
			# 無効なサブタイトルシーンを非表示にして無効化
			subtitle_scene.visible = false
			subtitle_scene = null
	else:
		log_message("WARNING: Subtitle scene not found - subtitle functionality disabled", LogLevel.INFO)

# 要素をフルスクリーンに設定
func _setup_fullscreen_element(element):
	if not element:
		return
		
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
				text_completed.emit()
	
	# インジケーターの点滅処理
	if is_text_completed and show_indicator:
		indicator_blink_timer += delta
		if indicator_blink_timer >= indicator_blink_speed:
			indicator_blink_timer = 0
			indicator_visible = !indicator_visible
			_update_displayed_text()
		
# 表示テキストの更新
func _update_displayed_text():
	if not dialogue_text:
		return
		
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

# テキスト表示の統合関数（show_textとshow_text_same_pageを統合）
func show_text(text, new_page = true, go_next = false):
	log_message("Showing text: " + text + " (new_page: " + str(new_page) + ")", LogLevel.INFO)
	
	if not dialogue_text:
		log_message("Error: dialogue_text is null in show_text()", LogLevel.ERROR)
		return
		
	current_text = text
	displayed_text = ""
	is_text_completed = false
	text_timer = 0
	
	if new_page:
		page_text_buffer = []
		current_page_index = 0
		
		page_text_buffer.append({
			"text": text,
			"go_next": go_next
		})
		
		dialogue_text.visible = true
		dialogue_text.text = ""
		
		if text_panel:
			text_panel.visible = true
	else:
		var current_displayed = dialogue_text.text
		
		if current_displayed != "":
			current_displayed += "\n\n"
		
		dialogue_text.text = current_displayed
		
		# 既に表示中のテキストに追加する場合はバッファに追加しない
		if page_text_buffer.size() == 0:
			page_text_buffer.append({
				"text": text,
				"go_next": go_next
			})

# インジケーターシンボルを取得
func _get_indicator_symbol():
	if current_page_index < page_text_buffer.size():
		var current_item = page_text_buffer[current_page_index]
		if current_item.get("go_next", false):
			return page_indicator_symbol
		
	return indicator_symbol
	
# テキストバッファをクリア
func clear_text_buffers():
	page_text_buffer = []
	current_page_index = 0
	is_text_completed = true
	current_text = ""
	displayed_text = ""
	
	if dialogue_text:
		dialogue_text.text = ""
	
	log_message("All text buffers cleared", LogLevel.DEBUG)

# バッファに次のテキストがあるかをチェック
func has_more_text_in_buffer():
	return current_page_index < page_text_buffer.size() - 1

# バッファから次のテキストを表示
func display_next_text_from_buffer():
	if has_more_text_in_buffer():
		current_page_index += 1
		var next_text = page_text_buffer[current_page_index]
		show_text(next_text["text"], false)
		return true
	return false

# テキスト表示を即座に完了
func complete_text_display():
	if not is_text_completed:
		displayed_text = current_text
		is_text_completed = true
		show_indicator = true
		_update_displayed_text()
		text_completed.emit()
		log_message("Text display completed instantly", LogLevel.DEBUG)

# テキスト進行の処理
func complete_text():
	if not is_text_completed:
		complete_text_display()
	else:
		if has_more_text_in_buffer():
			display_next_text_from_buffer()
		else:
			log_message("All text in buffer displayed", LogLevel.DEBUG)
			
			# 現在のテキストアイテムの go_next フラグを確認
			var should_clear = false
			if current_page_index < page_text_buffer.size():
				var current_item = page_text_buffer[current_page_index]
				if current_item.get("go_next", false):
					should_clear = true
					log_message("go_next flag is true, clearing text buffers", LogLevel.DEBUG)
			
			show_indicator = false
			_update_displayed_text()
			
			# go_next が true の場合はテキストをクリア
			if should_clear:
				clear_text_buffers()
				# go_next の場合は、次のテキストを待たずにすぐに次のコマンドに進む
				text_click_processed.emit()
			else:
				# go_next でない場合は、従来通り次のテキストがバッファに追加されるのを待つ
				text_click_processed.emit()
				
				# ここでTestScenarioの処理を待ち、次のテキストがバッファに追加されたかチェック
				await get_tree().process_frame
				if has_more_text_in_buffer():
					display_next_text_from_buffer()

# 背景変更（フェードイン付き）
var background_fade_in_progress: bool = false
var current_background_effect: String = "normal"  # "normal", "sepia", "grayscale"
var is_flashback_mode: bool = false  # 回想モード中かどうか
var flashback_effect_type: String = "sepia"  # 回想時のエフェクトタイプ（"sepia" または "grayscale"）

func change_background(background_path, use_fade: bool = true, fade_duration: float = 0.5, effect: String = "normal"):
	if not background:
		log_message("ERROR: Background node is null", LogLevel.ERROR)
		return
		
	current_background = background_path
	log_message("Loading background: " + background_path, LogLevel.INFO)
	
	var bg_texture = load(background_path)
	if bg_texture == null:
		log_message("ERROR: Failed to load background texture from path: " + background_path, LogLevel.ERROR)
		return
	
	if use_fade and background_fade_in_progress:
		# 既にフェードイン処理中の場合は待つ
		await get_tree().create_timer(0.1).timeout
		return await change_background(background_path, use_fade, fade_duration)
	
	# 背景を設定
	background.texture = bg_texture
	background.visible = true
	_setup_fullscreen_element(background)
	
	# エフェクトを適用（回想モード中は自動的に色調変更を適用）
	var effect_to_apply = effect
	if is_flashback_mode and effect == "normal":
		# 回想モード中は指定されたエフェクトを適用
		effect_to_apply = flashback_effect_type
	# 背景変更時はアニメーションなしで即座に適用（フェードインと同時に色調も適用）
	_apply_background_effect(effect_to_apply, false)
	
	if use_fade:
		# フェードイン処理
		background_fade_in_progress = true
		background.modulate = Color(1, 1, 1, 0)  # 最初は透明
		
		var tween = create_tween()
		if tween:
			tween.tween_property(background, "modulate", Color(1, 1, 1, 1), fade_duration)
			await tween.finished
		else:
			# ツイーンが作成できない場合は即座に表示
			background.modulate = Color(1, 1, 1, 1)
			await get_tree().create_timer(fade_duration).timeout
		
		background_fade_in_progress = false
		background_fade_in_completed.emit()  # フェードイン完了を通知
	else:
		# フェードなしの場合は即座に表示
		background.modulate = Color(1, 1, 1, 1)
	
	log_message("Background properties:", LogLevel.DEBUG)
	log_message("- Visible: " + str(background.visible), LogLevel.DEBUG)
	log_message("- Modulate: " + str(background.modulate), LogLevel.DEBUG)
	log_message("- Size: " + str(background.size), LogLevel.DEBUG)
	log_message("- Effect: " + effect, LogLevel.DEBUG)
	log_message("Background changed successfully.", LogLevel.INFO)

# 背景エフェクトを適用（アニメーション付き）
func _apply_background_effect(effect: String, use_animation: bool = true, duration: float = 0.8):
	if not background:
		return
	
	current_background_effect = effect
	
	var target_material: ShaderMaterial = null
	var target_modulate: Color = Color(1, 1, 1, 1)
	
	match effect:
		"sepia":
			# セピア調エフェクト（シェーダーを使用）
			var sepia_shader = load("res://shaders/sepia.gdshader")
			if sepia_shader:
				target_material = ShaderMaterial.new()
				target_material.shader = sepia_shader
				log_message("Applied sepia effect to background", LogLevel.DEBUG)
			else:
				log_message("ERROR: Failed to load sepia shader", LogLevel.ERROR)
		"grayscale":
			# グレースケールエフェクト（シェーダーを使用）
			var grayscale_shader = load("res://shaders/grayscale.gdshader")
			if grayscale_shader:
				target_material = ShaderMaterial.new()
				target_material.shader = grayscale_shader
				log_message("Applied grayscale effect to background", LogLevel.DEBUG)
			else:
				log_message("ERROR: Failed to load grayscale shader", LogLevel.ERROR)
		"normal", _:
			# エフェクトを解除
			target_material = null
			log_message("Removed background effect", LogLevel.DEBUG)
	
	if use_animation:
		# アニメーションでエフェクトを切り替え
		# フェードアウト → エフェクト変更 → フェードイン
		var current_alpha = background.modulate.a
		var half_duration = duration / 2.0
		
		# フェードアウト
		var fade_out_tween = create_tween()
		if fade_out_tween:
			fade_out_tween.tween_property(background, "modulate:a", 0.0, half_duration)
			await fade_out_tween.finished
		else:
			background.modulate.a = 0.0
			await get_tree().create_timer(half_duration).timeout
		
		# エフェクトを適用（alpha は 0 のまま）
		background.material = target_material
		background.modulate = Color(target_modulate.r, target_modulate.g, target_modulate.b, 0.0)
		
		# フェードイン（保存した alpha に戻す）
		var fade_in_tween = create_tween()
		if fade_in_tween:
			fade_in_tween.tween_property(background, "modulate:a", current_alpha, half_duration)
			await fade_in_tween.finished
		else:
			background.modulate.a = current_alpha
	else:
		# アニメーションなしで即座に適用
		background.material = target_material
		background.modulate = target_modulate

# BGM再生
func play_bgm(bgm_path):
	if not bgm_player:
		log_message("ERROR: bgm_player is null", LogLevel.ERROR)
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
			log_message("BGM playing: " + bgm_path, LogLevel.INFO)
		else:
			log_message("ERROR: Failed to load audio: " + bgm_path, LogLevel.ERROR)

# BGM停止
func stop_bgm():
	if not bgm_player:
		log_message("ERROR: bgm_player is null", LogLevel.ERROR)
		return
		
	bgm_player.stop()
	current_bgm = ""
	log_message("BGM stopped", LogLevel.INFO)

# 効果音再生
func play_sfx(sfx_path):
	if not sfx_player:
		log_message("ERROR: sfx_player is null", LogLevel.ERROR)
		return

	var audio_stream
	if sfx_path.begins_with("res://"):
		audio_stream = load(sfx_path)
	else:
		audio_stream = load("res://assets/audio/sfx/" + sfx_path)
	
	if audio_stream != null:
		sfx_player.stream = audio_stream
		sfx_player.play()
		log_message("SFX playing: " + sfx_path, LogLevel.INFO)
	else:
		log_message("ERROR: Failed to load audio: " + sfx_path, LogLevel.ERROR)

# ページバッファに追加
func add_to_page_buffer(text, go_next = false):
	page_text_buffer.append({
		"text": text,
		"go_next": go_next
	})
	log_message("Added to page buffer: " + text, LogLevel.DEBUG)
	log_message("Current buffer size: " + str(page_text_buffer.size()), LogLevel.DEBUG)

# 選択肢の表示
func show_choices(choices):
	if choice_system:
		log_message("Showing choices: " + str(choices.size()) + " options", LogLevel.INFO)
		choice_system.show_choices(choices)
	else:
		log_message("ERROR: Choice system not initialized", LogLevel.ERROR)

# 選択肢が選ばれた時の処理
func _on_choice_made(choice_id):
	log_message("Choice made: " + choice_id, LogLevel.INFO)
	choice_selected.emit(choice_id)

# サブタイトルが完了した時の処理
func _on_subtitle_completed():
	log_message("Subtitle completed", LogLevel.INFO)
	is_showing_subtitle = false
	subtitle_completed.emit()

# サブタイトル表示
func show_subtitle(text: String, fade_time: float = 1.0, display_time: float = 2.0):
	log_message("show_subtitle called with text: " + text, LogLevel.DEBUG)
	log_message("subtitle_scene exists: " + str(subtitle_scene != null), LogLevel.DEBUG)
	
	if subtitle_scene:
		log_message("subtitle_scene has script: " + str(subtitle_scene.get_script() != null), LogLevel.DEBUG)
		log_message("subtitle_scene has show_subtitle method: " + str(subtitle_scene.has_method("show_subtitle")), LogLevel.DEBUG)
	
	if subtitle_scene and subtitle_scene.get_script() and subtitle_scene.has_method("show_subtitle"):
		log_message("Showing subtitle: " + text, LogLevel.INFO)
		is_showing_subtitle = true
		subtitle_scene.show_subtitle(text, fade_time, display_time)
	else:
		log_message("WARNING: Subtitle scene not available - skipping subtitle: " + text, LogLevel.INFO)
		# サブタイトルシーンがない場合は即座に完了シグナルを発行
		subtitle_completed.emit()

# 入力イベント処理
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# サブタイトル表示中はスキップ
			if is_showing_subtitle and subtitle_scene:
				if subtitle_scene.has_method("skip_subtitle"):
					subtitle_scene.skip_subtitle()
					log_message("Subtitle skipped by click", LogLevel.DEBUG)
				return
			# 通常のテキスト進行
			complete_text()
			log_message("Mouse click detected - text advanced", LogLevel.DEBUG)

# ログメッセージの出力（ログレベルによるフィルタリング）
func log_message(message, level = LogLevel.INFO):
	if level >= current_log_level:
		var prefix = ""
		match level:
			LogLevel.INFO:
				prefix = "[INFO] "
			LogLevel.DEBUG:
				prefix = "[DEBUG] "
			LogLevel.ERROR:
				prefix = "[ERROR] "
		
		print(prefix + message)

# 回想モード開始
func start_flashback(effect_type: String = "sepia"):
	log_message("Starting flashback mode with effect: " + effect_type, LogLevel.INFO)
	is_flashback_mode = true
	flashback_effect_type = effect_type
	# 現在の背景にエフェクトを適用（アニメーション付き）
	if background and background.visible:
		await _apply_background_effect(flashback_effect_type, true, 0.8)

# 回想モード終了
func end_flashback():
	log_message("Ending flashback mode", LogLevel.INFO)
	is_flashback_mode = false
	# 現在の背景のエフェクトを解除（アニメーション付き）
	if background and background.visible:
		await _apply_background_effect("normal", true, 0.8)
