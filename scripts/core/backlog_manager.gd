extends Node
class_name BacklogManager

## バックログ（テキスト履歴）管理クラス
## ダイアログテキストのみを記録する（choice、subtitle、system系は除外）

const MAX_ENTRIES: int = 500

var _history: Array = []

## テキストエントリを履歴に追加
func add_entry(text: String) -> void:
	_history.append({ "text": text })
	if _history.size() > MAX_ENTRIES:
		_history.pop_front()

## 全履歴を返す
func get_history() -> Array:
	return _history

## 履歴をクリア
func clear() -> void:
	_history.clear()

## 履歴をシリアライズ（セーブ用、直近200件まで）
func serialize() -> Array:
	var max_save = mini(_history.size(), 200)
	return _history.slice(_history.size() - max_save)

## デシリアライズして履歴を復元（ロード用）
func deserialize(data: Array) -> void:
	_history.clear()
	for entry in data:
		if entry is Dictionary and entry.has("text"):
			_history.append(entry)
