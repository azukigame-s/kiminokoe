extends Node
class_name ScenarioStack

## シナリオスタック管理クラス
## エピソード/共用シナリオ呼び出し時の状態保存

# スタック
var stack: Array = []

func _ready():
	print("[ScenarioStack] Ready")

## スタックに状態を追加
func push(state: Dictionary) -> void:
	stack.append(state)
	print("[ScenarioStack] Pushed state (stack size: %d)" % stack.size())

## スタックから状態を取得
func pop() -> Dictionary:
	if stack.is_empty():
		push_warning("[ScenarioStack] Stack is empty")
		return {}

	var state = stack.pop_back()
	print("[ScenarioStack] Popped state (stack size: %d)" % stack.size())
	return state

## スタックの先頭を参照（取り出さない）
func peek() -> Dictionary:
	if stack.is_empty():
		return {}
	return stack[-1]

## スタックのサイズを取得
func size() -> int:
	return stack.size()

## スタックが空かどうか
func is_empty() -> bool:
	return stack.is_empty()

## スタックをクリア
func clear() -> void:
	stack.clear()
	print("[ScenarioStack] Cleared")
