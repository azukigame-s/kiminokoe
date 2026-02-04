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

func _init():
	# コンポーネントの初期化
	command_executor = CommandExecutor.new()
	scenario_stack = ScenarioStack.new()
	skip_controller = SkipController.new()

	# コンポーネントを子ノードとして追加
	add_child(command_executor)
	add_child(scenario_stack)
	add_child(skip_controller)

func _ready():
	print("[ScenarioEngine] Ready")

## シナリオを開始
func start_scenario(scenario_data: Array) -> void:
	if is_running:
		push_warning("[ScenarioEngine] Scenario is already running")
		return

	current_scenario = scenario_data
	current_index = 0
	is_running = true

	scenario_started.emit()
	print("[ScenarioEngine] Starting scenario with %d commands" % scenario_data.size())

	await execute_scenario()

	is_running = false
	scenario_completed.emit()
	print("[ScenarioEngine] Scenario completed")

## シナリオ実行のメインループ
func execute_scenario() -> void:
	while current_index < current_scenario.size():
		var command = current_scenario[current_index]

		print("[ScenarioEngine] Executing command %d: %s" % [current_index, command.get("type", "unknown")])

		await command_executor.execute(command, skip_controller)

		command_executed.emit(command)
		current_index += 1

## サブシナリオ呼び出し（エピソード/共用シナリオ）
func call_subscenario(scenario_path: String, apply_grayscale: bool = false) -> void:
	# 現在の状態をスタックに保存
	scenario_stack.push({
		"scenario": current_scenario,
		"index": current_index
	})

	print("[ScenarioEngine] Calling subscenario: %s (grayscale: %s)" % [scenario_path, apply_grayscale])

	# グレースケール効果を適用
	if apply_grayscale:
		# TODO: グレースケール効果の実装
		pass

	# サブシナリオを読み込んで実行
	var subscenario_data = await load_scenario_data(scenario_path)
	if subscenario_data:
		await start_scenario(subscenario_data)

	# 元のシナリオに復帰
	var previous_state = scenario_stack.pop()
	if previous_state:
		current_scenario = previous_state.scenario
		current_index = previous_state.index + 1  # 次のコマンドから再開

		print("[ScenarioEngine] Returned from subscenario")

		# グレースケール効果を解除
		if apply_grayscale:
			# TODO: グレースケール効果の解除
			pass

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
	print("[ScenarioEngine] Skip mode: %s" % skip_controller.is_skipping)
