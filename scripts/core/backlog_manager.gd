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
