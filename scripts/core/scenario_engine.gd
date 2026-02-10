extends Node
class_name ScenarioEngine

## シナリオ実行エンジン
## async/await ベースのシンプルな実装

# シグナル
signal scenario_started
signal scenario_completed
signal command_executed(command: Dictionary)

# 依存コンポーネント
var command_executor: CommandExecutor
var scenario_stack: ScenarioStack
var skip_controller: SkipController

# 現在の状態
var current_scenario: Array = []
var current_index: int = 0
var is_running: bool = false
var current_scenario_path: String = ""  # セーブ/ロード用

func _init():
	# コンポーネントの初期化
	command_executor = CommandExecutor.new()
	scenario_stack = ScenarioStack.new()
	skip_controller = SkipController.new()

	# コンポーネントを子ノードとして追加
	add_child(command_executor)
	add_child(scenario_stack)
	add_child(skip_controller)

	# スキップコントローラとの連携を設定
	command_executor.connect_skip_controller(skip_controller)

func _ready():
	pass

## シナリオを開始
func start_scenario(scenario_data: Array, scenario_path: String = "") -> void:
	if is_running:
		push_warning("[ScenarioEngine] Scenario is already running")
		return

	current_scenario = scenario_data
	current_index = 0
	current_scenario_path = scenario_path
	is_running = true

	scenario_started.emit()

	await execute_scenario()

	is_running = false
	scenario_completed.emit()

## シナリオ実行のメインループ
func execute_scenario() -> void:
	while current_index < current_scenario.size():
		var command = current_scenario[current_index]
		var command_type = command.get("type", "unknown")

		# 特殊コマンドの処理（ScenarioEngine側で処理）
		match command_type:
			"load_scenario":
				await handle_load_scenario(command)
				continue  # current_indexはcall_subscenario内で設定済み
			"jump":
				handle_jump(command)
				continue  # current_indexはjumpで設定済み
			"episode_clear":
				handle_episode_clear(command)
				current_index += 1
				continue
			"choice":
				await handle_choice(command)
				continue  # current_indexはchoice内で設定済み
			"branch":
				handle_branch(command)
				continue  # current_indexはbranch内で設定済み

		# 通常のコマンドはCommandExecutorで処理
		await command_executor.execute(command, skip_controller)

		command_executed.emit(command)
		current_index += 1

## load_scenario コマンドの処理
func handle_load_scenario(command: Dictionary) -> void:
	var path = command.get("path", "")
	if path.is_empty():
		push_error("[ScenarioEngine] load_scenario: path が指定されていません")
		return

	var new_page_after_return = command.get("new_page_after_return", true)

	# episodes/ 配下はグレースケール適用
	var is_episode = path.begins_with("episodes/")

	await call_subscenario(path, is_episode, new_page_after_return)

## jump コマンドの処理
func handle_jump(command: Dictionary) -> void:
	var target_index = command.get("index", -1)
	if target_index < 0:
		push_error("[ScenarioEngine] jump: index が指定されていません")
		current_index += 1
		return

	# indexマーカーを探す
	for i in range(current_scenario.size()):
		var cmd = current_scenario[i]
		if cmd.get("type") == "index" and cmd.get("index") == target_index:
			current_index = i + 1  # indexマーカーの次から実行
			return

	push_error("[ScenarioEngine] jump: index %d が見つかりません" % target_index)
	current_index += 1

## choice コマンドの処理
func handle_choice(command: Dictionary) -> void:
	var choices = command.get("choices", [])
	if choices.is_empty():
		push_error("[ScenarioEngine] choice: choices が空です")
		current_index += 1
		return

	# スキップモードを停止
	if skip_controller.is_skipping:
		skip_controller.disable()

	# テキストを隠す
	command_executor.hide_text_for_choice()

	# ChoiceDisplay で選択肢を表示
	var choice_display = command_executor.choice_display
	if not choice_display:
		push_error("[ScenarioEngine] ChoiceDisplay が設定されていません")
		current_index += 1
		return

	choice_display.show_choices(choices)

	# 選択を待機
	var selected = await choice_display.choice_selected

	# テキストを再表示
	command_executor.show_text_after_choice()

	# 選択結果に応じた処理
	if selected.has("scenario"):
		# 別シナリオに遷移（サブシナリオとして呼び出し）
		var scenario_path = selected.get("scenario", "")
		var is_episode = scenario_path.begins_with("episodes/")
		await call_subscenario(scenario_path, is_episode)
		# サブシナリオから戻ったら、choiceの次のコマンドへ
		current_index += 1
	elif selected.has("next_index"):
		# 同一シナリオ内のindexへジャンプ
		var target_index = selected.get("next_index", -1)
		handle_jump({"index": target_index})
	else:
		# next_index も scenario もない場合は次のコマンドへ
		current_index += 1

## branch コマンドの処理（システムデータによる条件分岐）
func handle_branch(command: Dictionary) -> void:
	var condition = command.get("condition", "")
	var branches = command.get("branches", {})

	if condition.is_empty() or branches.is_empty():
		push_error("[ScenarioEngine] branch: condition or branches is empty")
		current_index += 1
		return

	# TrophyManager から条件を評価
	var trophy_manager = get_node_or_null("/root/TrophyManager")
	if not trophy_manager:
		push_error("[ScenarioEngine] branch: TrophyManager が見つかりません")
		current_index += 1
		return

	var result = trophy_manager.evaluate_condition(condition)

	if branches.has(result):
		var target_index = branches[result]
		handle_jump({"index": target_index})
	else:
		push_warning("[ScenarioEngine] branch: result '%s' に対応する分岐がありません" % result)
		current_index += 1

## episode_clear コマンドの処理
func handle_episode_clear(command: Dictionary) -> void:
	var episode_id = command.get("id", "")
	if episode_id.is_empty():
		push_error("[ScenarioEngine] episode_clear: id が指定されていません")
		return

	# TrophyManagerが存在する場合は呼び出す
	if Engine.has_singleton("TrophyManager"):
		var trophy_manager = Engine.get_singleton("TrophyManager")
		trophy_manager.clear_episode(episode_id)
	else:
		# オートロードとして設定されている場合
		var trophy_manager = get_node_or_null("/root/TrophyManager")
		if trophy_manager:
			trophy_manager.clear_episode(episode_id)
		else:
			push_warning("[ScenarioEngine] TrophyManager が見つかりません")

## サブシナリオ呼び出し（エピソード/共用シナリオ）
func call_subscenario(scenario_path: String, apply_grayscale: bool = false, new_page_after_return: bool = true) -> void:
	# 現在の状態をスタックに保存
	scenario_stack.push({
		"scenario": current_scenario,
		"index": current_index,
		"path": current_scenario_path
	})

	# グレースケール効果を適用（エピソード呼び出し時）
	if apply_grayscale:
		await command_executor.execute_flashback_start({"effect": "grayscale"}, skip_controller)

	# サブシナリオを読み込んで実行
	# is_running フラグを一時的に解除（サブシナリオでstart_scenarioを呼ぶため）
	is_running = false
	var subscenario_data = await load_scenario_data(scenario_path)
	if subscenario_data:
		await start_scenario(subscenario_data, scenario_path)

	# 元のシナリオに復帰
	var previous_state = scenario_stack.pop()
	if previous_state:
		current_scenario = previous_state.scenario
		current_index = previous_state.index + 1  # 次のコマンドから再開
		current_scenario_path = previous_state.path
		is_running = true  # 実行状態を復元

		# グレースケール効果を解除（エピソード呼び出し時）
		if apply_grayscale:
			await command_executor.execute_flashback_end({}, skip_controller)

		# エピソード再生完了時に自動的にクリア記録（episodes/ 配下のみ）
		if apply_grayscale and scenario_path.begins_with("episodes/"):
			var trophy_manager = get_node_or_null("/root/TrophyManager")
			if trophy_manager:
				var episode_id = trophy_manager.extract_episode_id(scenario_path)
				if not episode_id.is_empty():
					trophy_manager.clear_episode(episode_id)
					print("[ScenarioEngine] Auto-cleared episode: " + episode_id)

		# サブシナリオ復帰後にテキストバッファをクリア（旧システムと同等）
		if new_page_after_return and command_executor.text_display:
			command_executor.text_display.clear()

## シナリオデータを読み込む
func load_scenario_data(scenario_path: String) -> Array:
	var file_path = "res://scenarios/%s.json" % scenario_path

	if not FileAccess.file_exists(file_path):
		push_error("[ScenarioEngine] Scenario file not found: %s" % file_path)
		return []

	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("[ScenarioEngine] Failed to open scenario file: %s" % file_path)
		return []

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		push_error("[ScenarioEngine] Failed to parse JSON: %s" % file_path)
		return []

	return json.data

## スキップモードの切り替え
func toggle_skip_mode() -> void:
	skip_controller.toggle()

## セーブ用の状態を取得
func get_save_state() -> Dictionary:
	return {
		"scenario_path": current_scenario_path,
		"index": current_index,
		"stack": _serialize_stack()
	}

## スタックをシリアライズ（パスとインデックスのみ）
func _serialize_stack() -> Array:
	var serialized = []
	for i in range(scenario_stack.size()):
		var state = scenario_stack.stack[i]
		serialized.append({
			"path": state.get("path", ""),
			"index": state.get("index", 0)
		})
	return serialized

## セーブ状態から復元
func load_from_save_state(save_state: Dictionary) -> void:
	var scenario_path = save_state.get("scenario_path", "")
	var index = save_state.get("index", 0)
	var stack_data = save_state.get("stack", [])

	if scenario_path.is_empty():
		push_error("[ScenarioEngine] load_from_save_state: scenario_path が空です")
		return

	# スタックを復元
	scenario_stack.clear()
	for state in stack_data:
		var path = state.get("path", "")
		var state_index = state.get("index", 0)
		var scenario_data = await load_scenario_data(path)
		scenario_stack.push({
			"scenario": scenario_data,
			"index": state_index,
			"path": path
		})

	# シナリオを読み込み
	var scenario_data = await load_scenario_data(scenario_path)
	if scenario_data.is_empty():
		push_error("[ScenarioEngine] load_from_save_state: シナリオ読み込み失敗: %s" % scenario_path)
		return

	# 状態を設定
	current_scenario = scenario_data
	current_scenario_path = scenario_path
	current_index = index
	is_running = true

	# シナリオを再開
	scenario_started.emit()
	await execute_scenario()

	is_running = false
	scenario_completed.emit()
