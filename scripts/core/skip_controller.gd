extends Node
class_name SkipController

## スキップモード制御クラス
## シンプルなフラグ管理

# スキップモード状態
var is_skipping: bool = false

# スキップモード時の待機時間（秒）
var skip_wait_time: float = 0.05

# シグナル
signal skip_mode_changed(is_skipping: bool)

func _ready():
	print("[SkipController] Ready")

## スキップモードを切り替え
func toggle() -> void:
	is_skipping = !is_skipping
	skip_mode_changed.emit(is_skipping)
	print("[SkipController] Skip mode: %s" % is_skipping)

## スキップモードを有効化
func enable() -> void:
	if not is_skipping:
		is_skipping = true
		skip_mode_changed.emit(is_skipping)
		print("[SkipController] Skip mode enabled")

## スキップモードを無効化
func disable() -> void:
	if is_skipping:
		is_skipping = false
		skip_mode_changed.emit(is_skipping)
		print("[SkipController] Skip mode disabled")
