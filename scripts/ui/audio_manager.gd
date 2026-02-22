extends Node

## オーディオ管理クラス
## BGMと効果音の再生を管理

# オーディオプレイヤー
var bgm_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

# 現在再生中のBGMパス
var current_bgm_path: String = ""

# フェード設定
var bgm_fade_duration: float = 1.5
var bgm_fade_start_db: float = -40.0  # フェードイン開始時の音量

func _ready():
	print("[AudioManager] 準備完了")
	# ゲームツリーがポーズ中（一息・足跡画面）でもBGMが止まらないようにする
	process_mode = Node.PROCESS_MODE_ALWAYS

	# BGMプレイヤーの作成
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	bgm_player.bus = "Master"  # 必要に応じてバスを変更
	add_child(bgm_player)

	# SFXプレイヤーの作成
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SFXPlayer"
	sfx_player.bus = "Master"
	add_child(sfx_player)

## BGMを再生
func play_bgm(path: String, fade_in: bool = true) -> void:
	if current_bgm_path == path and bgm_player.playing:
		print("[AudioManager] 同じBGMが再生中: %s" % path)
		return

	print("[AudioManager] BGM再生: %s" % path)

	# 現在のBGMをフェードアウト
	if bgm_player.playing and fade_in:
		await _fade_out_bgm()

	# 新しいBGMを読み込み
	var stream = load(path)
	if stream == null:
		push_error("[AudioManager] BGM読み込み失敗: %s" % path)
		return

	current_bgm_path = path
	bgm_player.stream = stream

	if fade_in:
		bgm_player.volume_db = bgm_fade_start_db
		bgm_player.play()
		await _fade_in_bgm()
	else:
		bgm_player.volume_db = 0.0
		bgm_player.play()

	print("[AudioManager] BGM再生開始: %s" % path)

## BGMを停止
func stop_bgm(fade_out: bool = true) -> void:
	if not bgm_player.playing:
		return

	print("[AudioManager] BGM停止")

	if fade_out:
		await _fade_out_bgm()

	bgm_player.stop()
	current_bgm_path = ""

## 効果音を再生
func play_sfx(path: String) -> void:
	print("[AudioManager] 効果音再生: %s" % path)

	var stream = load(path)
	if stream == null:
		push_error("[AudioManager] 効果音読み込み失敗: %s" % path)
		return

	sfx_player.stream = stream
	sfx_player.play()

## BGMフェードアウト
func _fade_out_bgm() -> void:
	var tween = create_tween()
	tween.tween_property(bgm_player, "volume_db", bgm_fade_start_db, bgm_fade_duration)
	await tween.finished

## BGMフェードイン
func _fade_in_bgm() -> void:
	var tween = create_tween()
	tween.tween_property(bgm_player, "volume_db", 0.0, bgm_fade_duration)
	await tween.finished

## BGM音量を設定（0.0〜1.0）
func set_bgm_volume(volume: float) -> void:
	bgm_player.volume_db = linear_to_db(clamp(volume, 0.0, 1.0))

## SFX音量を設定（0.0〜1.0）
func set_sfx_volume(volume: float) -> void:
	sfx_player.volume_db = linear_to_db(clamp(volume, 0.0, 1.0))

## フェード時間を設定
func set_fade_duration(duration: float) -> void:
	bgm_fade_duration = duration