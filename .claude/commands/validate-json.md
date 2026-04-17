scenarios/ 配下の全 JSON ファイルを検証してください。

以下の3段階のチェックを行います：
1. **構文エラー** — JSON パース失敗（カンマ抜け等）
2. **意味エラー** — `load_scenario` のパス不明・`jump`/`next_index`/`branch` のジャンプ先 index 未定義
3. **規約警告** — `go_next: true` の後に続く dialogue に `new_page: true` がない（jump のジャンプ先・choice の全分岐も追跡）

以下の Python スクリプトを実行して問題を検出し、結果を報告してください。
エラー・警告があった場合は、各ファイルを読んで原因を特定し、修正まで行ってください。

```python
import json, glob, os

# スキャン時に「素通り」するタイプ（表示状態を変えない、またはクリアするが規約上 new_page 必須）
SKIP_TYPES = {
    "bgm", "sfx", "sfx_loop", "sfx_loop_stop",
    "background", "set_flag", "increment",
    "visit_location", "flashback_start", "flashback_end",
    "episode_clear", "index",
}
TRANSPARENT_TYPES = {
    "subtitle", "load_scenario", "call_subscenario",
    "poem", "staff_roll",
}

def find_index_marker(commands, target):
    for i, cmd in enumerate(commands):
        if cmd.get("type") == "index" and cmd.get("index") == target:
            return i
    return -1

def scan_next_dialogue(commands, start, visited, origin_pos):
    """
    go_next: true の dialogue (origin_pos) に続く最初の dialogue を前方スキャンし、
    new_page: true でなければ警告を返す。
    jump はターゲットを追跡、choice は全 next_index ブランチを確認。
    visited: 無限ループ防止用 index セット
    """
    issues = []
    j = start
    while j < len(commands):
        cmd = commands[j]
        t = cmd.get("type", "")

        if t in SKIP_TYPES or t in TRANSPARENT_TYPES:
            j += 1

        elif t == "jump":
            target = cmd.get("index", -1)
            if target not in visited:
                k = find_index_marker(commands, target)
                if k >= 0:
                    issues += scan_next_dialogue(commands, k + 1, visited | {target}, origin_pos)
            break

        elif t == "choice":
            for ch in cmd.get("choices", []):
                ni = ch.get("next_index")
                if ni is not None and ni not in visited:
                    k = find_index_marker(commands, ni)
                    if k >= 0:
                        issues += scan_next_dialogue(commands, k + 1, visited | {ni}, origin_pos)
            break

        elif t == "dialogue":
            if not cmd.get("new_page", False):
                src = commands[origin_pos].get("text", "")[:30]
                nxt = cmd.get("text", "")[:30]
                issues.append(f"go_next→new_page欠落 [要素{origin_pos}→{j}]: 「{src}」→「{nxt}」")
            break

        else:
            break

    return issues


syntax_errors = []
semantic_errors = []
semantic_warnings = []
ok = 0

for path in sorted(glob.glob('scenarios/**/*.json', recursive=True)):
    # --- ① 構文チェック ---
    try:
        with open(path, encoding='utf-8') as f:
            commands = json.load(f)
        ok += 1
    except json.JSONDecodeError as e:
        syntax_errors.append((path, str(e)))
        continue

    # このファイルで定義されている index マーカー一覧
    defined_indices = {
        cmd.get("index")
        for cmd in commands
        if cmd.get("type") == "index"
    }

    file_errors = []
    file_warnings = []

    for i, cmd in enumerate(commands):
        t = cmd.get("type", "")

        # --- ② go_next → new_page チェック（警告）---
        if t == "dialogue" and cmd.get("go_next", False):
            file_warnings += scan_next_dialogue(commands, i + 1, set(), i)

        # --- ③ load_scenario / call_subscenario パス存在チェック（エラー）---
        if t in ("load_scenario", "call_subscenario"):
            p = cmd.get("path", "")
            if p and not os.path.exists(f"scenarios/{p}.json"):
                file_errors.append(f"パス不明 [{t} 要素{i}]: scenarios/{p}.json")

        # --- ④ jump ターゲット存在チェック（エラー）---
        if t == "jump":
            idx = cmd.get("index", -1)
            if idx not in defined_indices:
                file_errors.append(f"jump 先 index 未定義 [要素{i}]: index={idx}")

        # --- ⑤ choice next_index 存在チェック（エラー）---
        if t == "choice":
            for ch in cmd.get("choices", []):
                ni = ch.get("next_index")
                if ni is not None and ni not in defined_indices:
                    file_errors.append(
                        f"choice next_index 未定義 [要素{i}]: index={ni} (「{ch.get('text','')}」)"
                    )

        # --- ⑥ branch / branch_flag / branch_counter ターゲット存在チェック（エラー）---
        if t == "branch":
            for val, idx in cmd.get("branches", {}).items():
                if isinstance(idx, int) and idx not in defined_indices:
                    file_errors.append(f"branch 先 index 未定義 [要素{i}]: {val}→{idx}")

        if t == "branch_flag":
            for val, idx in cmd.get("branches", {}).items():
                if isinstance(idx, int) and idx not in defined_indices:
                    file_errors.append(f"branch_flag 先 index 未定義 [要素{i}]: {val}→{idx}")

        if t == "branch_counter":
            for key in ("if_gte", "if_lt"):
                idx = cmd.get(key)
                if isinstance(idx, int) and idx not in defined_indices:
                    file_errors.append(f"branch_counter {key} index 未定義 [要素{i}]: {idx}")

    if file_errors:
        semantic_errors.append((path, file_errors))
    if file_warnings:
        semantic_warnings.append((path, file_warnings))

# --- 結果出力 ---
total = ok + len(syntax_errors)
print(f"チェック完了: {total} ファイル")
print(f"  構文エラー : {len(syntax_errors)} ファイル")
print(f"  意味エラー : {len(semantic_errors)} ファイルに問題あり")
print(f"  警告       : {len(semantic_warnings)} ファイルに問題あり")
print()

if syntax_errors:
    print("=== ① 構文エラー ===")
    for path, msg in syntax_errors:
        print(f"  ❌ {path}")
        print(f"     {msg}")
    print()

if semantic_errors:
    print("=== ② 意味エラー（パス不明・index 未定義）===")
    for path, errs in semantic_errors:
        print(f"  ❌ {path}")
        for e in errs:
            print(f"     {e}")
    print()

if semantic_warnings:
    print("=== ③ go_next → new_page 警告 ===")
    for path, warns in semantic_warnings:
        print(f"  ⚠️  {path}")
        for w in warns:
            print(f"     {w}")
    print()

if not syntax_errors and not semantic_errors and not semantic_warnings:
    print("✅ すべて正常です")
```
