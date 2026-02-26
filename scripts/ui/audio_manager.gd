extends Node

## オーディオ管理クラス
## BGMと効果音の再生を管理

# オーディオプレイヤー
var bgm_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer   # 環境音 ch1（地面・水などベース）
var ambient2_player: AudioStreamPlayer  # 環境音 ch2（風・雨などオーバーレイ）

# 現在再生中のBGMパス
var current_bgm_path: String = ""

# 現在再生中の環境音パスと音量（セーブ・ロード用）
var current_ambient_path: String = ""
var current_ambient_volume_db: float = 0.0
var current_ambient2_path: String = ""
var current_ambient2_volume_db: float = 0.0

# フェード設定
var bgm_fade_duration: float = 1.5
var bgm_fade_start_db: float = -40.0  # フェードイン開始時の音量

# BGMエイリアス → パスの対応表（JSONからはエイリアス名で指定する）
var bgm_aliases: Dictionary = {
	"title":    "res://assets/bgm/悠久の彼方.mp3",
	"main":     "res://assets/bgm/忘却の都.mp3",
	"flashback":"res://assets/bgm/Ancient_Travelers.mp3",
	"autumn":   "res://assets/bgm/秋の想い出.mp3",
	"dinner":   "res://assets/bgm/Old_home.mp3",
	"night":    "res://assets/bgm/冬待人.mp3",
	"suspense": "res://assets/bgm/悲しい記憶.mp3",
	"stop":     "",
}

## エイリアス名をファイルパスに解決する
## 未定義のエイリアスは警告を出してそのまま返す（後方互換）
func resolve_bgm_alias(alias_name: String) -> String:
	if bgm_aliases.has(alias_name):
		return bgm_aliases[alias_name]
	push_warning("[AudioManager] 未定義のBGMエイリアス: %s（パスとして使用）" % alias_name)
	return alias_name

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

	# 環境音プレイヤーの作成（ループ再生専用）
	ambient_player = AudioStreamPlayer.new()
	ambient_player.name = "AmbientPlayer"
	ambient_player.bus = "Master"
	add_child(ambient_player)

	# 環境音プレイヤー ch2（風・雨など ch1 と同時再生するオーバーレイ用）
	ambient2_player = AudioStreamPlayer.new()
	ambient2_player.name = "AmbientPlayer2"
	ambient2_player.bus = "Master"
	add_child(ambient2_player)

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

## 環境音をループ再生（fade_in=true でフェードイン、volume_db で音量調整）
func play_ambient(path: String, fade_in: bool = false, volume_db: float = 0.0) -> void:
	if current_ambient_path == path and ambient_player.playing:
		print("[AudioManager] 同じ環境音が再生中: %s" % path)
		return

	print("[AudioManager] 環境音再生: %s" % path)

	var stream = load(path)
	if stream == null:
		push_error("[AudioManager] 環境音読み込み失敗: %s" % path)
		return

	# ループ設定
	if stream is AudioStreamMP3:
		stream.loop = true
	elif stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD

	current_ambient_path = path
	current_ambient_volume_db = volume_db
	ambient_player.stream = stream

	if fade_in:
		ambient_player.volume_db = -40.0
		ambient_player.play()
		var tween = create_tween()
		tween.tween_property(ambient_player, "volume_db", volume_db, 1.0)
	else:
		ambient_player.volume_db = volume_db
		ambient_player.play()

## 環境音を停止（fade_out=true でフェードアウト）
func stop_ambient(fade_out: bool = true) -> void:
	if not ambient_player.playing:
		return

	print("[AudioManager] 環境音停止")

	if fade_out:
		var tween = create_tween()
		tween.tween_property(ambient_player, "volume_db", -40.0, 1.0)
		await tween.finished

	ambient_player.stop()
	current_ambient_path = ""
	current_ambient_volume_db = 0.0

## 環境音 ch2 をループ再生（volume_db で音量調整）
func play_ambient2(path: String, fade_in: bool = false, volume_db: float = 0.0) -> void:
	if current_ambient2_path == path and ambient2_player.playing:
		print("[AudioManager] 同じ環境音(ch2)が再生中: %s" % path)
		return

	print("[AudioManager] 環境音(ch2)再生: %s" % path)

	var stream = load(path)
	if stream == null:
		push_error("[AudioManager] 環境音(ch2)読み込み失敗: %s" % path)
		return

	if stream is AudioStreamMP3:
		stream.loop = true
	elif stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD

	current_ambient2_path = path
	current_ambient2_volume_db = volume_db
	ambient2_player.stream = stream

	if fade_in:
		ambient2_player.volume_db = -40.0
		ambient2_player.play()
		var tween = create_tween()
		tween.tween_property(ambient2_player, "volume_db", volume_db, 1.0)
	else:
		ambient2_player.volume_db = volume_db
		ambient2_player.play()

## 環境音 ch2 を停止
func stop_ambient2(fade_out: bool = true) -> void:
	if not ambient2_player.playing:
		return

	print("[AudioManager] 環境音(ch2)停止")

	if fade_out:
		var tween = create_tween()
		tween.tween_property(ambient2_player, "volume_db", -40.0, 1.0)
		await tween.finished

	ambient2_player.stop()
	current_ambient2_path = ""
	current_ambient2_volume_db = 0.0

## ch1・ch2 の環境音をすべて即時停止（タイトルへ戻る時などに使用）
func stop_all_ambient() -> void:
	ambient_player.stop()
	current_ambient_path = ""
	current_ambient_volume_db = 0.0
	ambient2_player.stop()
	current_ambient2_path = ""
	current_ambient2_volume_db = 0.0
	print("[AudioManager] 全環境音停止")

## 効果音を再生
func play_sfx(path: String, volume_db: float = 0.0) -> void:
	print("[AudioManager] 効果音再生: %s" % path)

	var stream = load(path)
	if stream == null:
		push_error("[AudioManager] 効果音読み込み失敗: %s" % path)
		return

	sfx_player.stream = stream
	sfx_player.volume_db = volume_db
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

## 環境音音量を設定（0.0〜1.0）
func set_ambient_volume(volume: float) -> void:
	ambient_player.volume_db = linear_to_db(clamp(volume, 0.0, 1.0))

## 環境音 ch2 音量を設定（0.0〜1.0）
func set_ambient2_volume(volume: float) -> void:
	ambient2_player.volume_db = linear_to_db(clamp(volume, 0.0, 1.0))

## フェード時間を設定
func set_fade_duration(duration: float) -> void:
	bgm_fade_duration = duration