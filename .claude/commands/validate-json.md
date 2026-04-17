scenarios/ 配下の全 JSON ファイルを検証してください。

以下の Python スクリプトを実行して構文エラーを検出し、結果を報告してください：

```python
import json, glob, os

errors = []
ok = 0

for path in sorted(glob.glob('scenarios/**/*.json', recursive=True)):
    try:
        with open(path, encoding='utf-8') as f:
            json.load(f)
        ok += 1
    except json.JSONDecodeError as e:
        errors.append((path, str(e)))

print(f"チェック完了: {ok + len(errors)} ファイル")
print(f"  正常: {ok} ファイル")
print(f"  エラー: {len(errors)} ファイル")
if errors:
    print()
    for path, msg in errors:
        print(f"  ❌ {path}")
        print(f"     {msg}")
else:
    print()
    print("  ✅ すべて正常です")
```

エラーがあった場合は、各ファイルを読んで原因を特定し、修正まで行ってください。
