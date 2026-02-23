extends TextureRect
class_name BackgroundDisplay

## 背景表示クラス
## フェード効果とエフェクト（グレースケール、セピア）をサポート

# シグナル
signal fade_completed

# フェード設定
var fade_duration: float = 0.5
var is_fading: bool = false

# エフェクト状態
var current_effect: String = "normal"  # "normal", "grayscale", "sepia"

# 段階的エフェクト用 Tween
var _gradual_tween: Tween = null

# 現在の背景パス（セーブ/ロード用）
var current_background_path: String = ""

func _ready():
	print("[BackgroundDisplay] 準備完了")

	# フルスクリーン設定（novel_system.tscn に合わせる）
	custom_minimum_size = Vector2(1024, 600)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

## 背景を設定（フェード付き）
func set_background(path: String, effect: String = "normal", use_fade: bool = true) -> void:
	print("[BackgroundDisplay] 背景設定: %s (エフェクト: %s)" % [path, effect])

	current_background_path = path

	# テクスチャを読み込み
	var new_texture = load(path)
	if new_texture == null:
		push_error("[BackgroundDisplay] テクスチャ読み込み失敗: %s" % path)
		return

	if use_fade and visible:
		# フェードアウト → 変更 → フェードイン
		await _fade_out()
		texture = new_texture
		_apply_effect(effect)
		await _fade_in()
	else:
		# 即座に変更
		texture = new_texture
		_apply_effect(effect)
		modulate.a = 1.0
		visible = true

	fade_completed.emit()
	print("[BackgroundDisplay] 背景設定完了")

## エフェクトのみ変更
func set_effect(effect: String, use_fade: bool = true) -> void:
	# 段階的エフェクト中なら停止してから即時適用
	if _gradual_tween:
		_gradual_tween.kill()
		_gradual_tween = null

	if current_effect == effect:
		return

	print("[BackgroundDisplay] エフェクト変更: %s → %s" % [current_effect, effect])

	if use_fade:
		await _fade_out()
		_apply_effect(effect)
		await _fade_in()
	else:
		_apply_effect(effect)

	fade_completed.emit()

## 段階的エフェクト開始（非ブロッキング）
func begin_gradual_effect(target: String, duration: float) -> void:
	if _gradual_tween:
		_gradual_tween.kill()
		_gradual_tween = null

	if target == "grayscale":
		var shader = load("res://shaders/grayscale.gdshader")
		if not shader:
			push_warning("[BackgroundDisplay] グレースケールシェーダー読み込み失敗")
			return
		var mat = ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("mix_amount", 0.0)
		material = mat
		current_effect = "grayscale"
		_gradual_tween = create_tween()
		_gradual_tween.tween_method(
			func(v: float): if material is ShaderMaterial: material.set_shader_parameter("mix_amount", v),
			0.0, 1.0, duration
		)
	elif target == "normal":
		if not (material is ShaderMaterial):
			material = null
			current_effect = "normal"
			return
		_gradual_tween = create_tween()
		_gradual_tween.tween_method(
			func(v: float): if material is ShaderMaterial: material.set_shader_parameter("mix_amount", v),
			1.0, 0.0, duration
		)
		_gradual_tween.tween_callback(func():
			material = null
			current_effect = "normal"
			_gradual_tween = null
		)

## エフェクトを適用
func _apply_effect(effect: String) -> void:
	current_effect = effect

	match effect:
		"grayscale":
			var shader = load("res://shaders/grayscale.gdshader")
			if shader:
				var mat = ShaderMaterial.new()
				mat.shader = shader
				material = mat
				print("[BackgroundDisplay] グレースケール適用")
			else:
				push_warning("[BackgroundDisplay] グレースケールシェーダー読み込み失敗")
		"sepia":
			var shader = load("res://shaders/sepia.gdshader")
			if shader:
				var mat = ShaderMaterial.new()
				mat.shader = shader
				material = mat
				print("[BackgroundDisplay] セピア適用")
			else:
				push_warning("[BackgroundDisplay] セピアシェーダー読み込み失敗")
		"normal", _:
			material = null
			print("[BackgroundDisplay] エフェクト解除")

## フェードアウト
func _fade_out() -> void:
	if is_fading:
		return

	is_fading = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_duration / 2.0)
	await tween.finished
	is_fading = false

## フェードイン
func _fade_in() -> void:
	if is_fading:
		return

	is_fading = true
	visible = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_duration / 2.0)
	await tween.finished
	is_fading = false

## フェード時間を設定
func set_fade_duration(duration: float) -> void:
	fade_duration = duration