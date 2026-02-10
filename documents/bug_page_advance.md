# バグ調査記録：ページ送り自動進行問題

**作成日**: 2026年2月8日
**最終更新**: 2026年2月10日（根本原因特定・修正完了）
**ステータス**: ✅ 解決済み（短期対応完了、長期対応は任意）

---

## 📋 クイックリファレンス

### 問題の要約

- **症状**: `go_next=true`のコマンドで、テキストが読めずに次のコマンドに進む
- **発生箇所**: `go_next=true`を持つすべてのdialogueコマンド
- **根本原因**: `command_executor.gd`で`go_next=true`時にクリック待機をスキップしていた（**仕様の誤り**）

### 解決内容（2026年2月10日）

- ✅ **根本原因を特定**: `go_next`フラグの誤用（本来はインディケーター制御用）
- ✅ **修正完了**: `command_executor.gd`の`if go_next: return`を削除
- ✅ **動作**: すべてのテキストでクリック待機を行うように修正
- ✅ **影響**: JSONの変更不要、インディケーター制御は維持

### 今後の検討事項（任意）

セクション12に3つの長期的な対応案を記載：
1. **対応案A**: 現状維持（工数ゼロ）
2. **対応案B**: 次コマンド先読み方式（工数中）
3. **対応案C**: インディケーター統一（工数小）

詳細は **セクション12** を参照してください。

### 主要ファイル

- `scripts/ui/text_display.gd` - **最重要**（バグの中心）
- `scripts/core/command_executor.gd` - コマンド実行ロジック
- `scenarios/shared/shared_day_1010_c.json` - 問題が発生するシナリオ

---

## 1. 問題の概要

### 症状

テキスト送り（同一ページ内でのテキスト追加）は正常に動作するが、**ページ送り（new_page=true）の場合のみ、ユーザーのクリック操作を待たずに次のページに自動遷移してしまう。**

### 再現条件

- **F5（ゲーム全体実行）**: 問題が発生する
- **F6（テストシーン単独実行）**: 問題が発生しない（ただしテストシナリオにgo_next→new_page遷移がない可能性あり）
- 具体的な発生箇所: コマンド7（`go_next=true`）→ コマンド8（`new_page=true, go_next=false`）の遷移時

### 発生する条件のパターン

```
コマンド7: dialogue, go_next=true  → wait_for_advance()をスキップ
コマンド8: dialogue, new_page=true, go_next=false → wait_for_advance()で停止すべきだが自動進行
```

### 該当シナリオデータ

`scenarios/shared/shared_day_1010_c.json` のコマンド7-8:

```json
{ "type": "dialogue", "text": "そう思うかもしれないが、それでも、僕はこの席が好きだった。", "go_next": true },
{ "type": "dialogue", "text": "理由は２つ。", "new_page": true }
```

---

## 2. システム構成

### 新システム（現在使用中）

| ファイル | 役割 |
|---|---|
| `scripts/ui/text_display.gd` | テキスト表示UI、クリック待機の中核（**バグの中心**） |
| `scripts/core/command_executor.gd` | コマンド実行、show_text/wait_for_advanceの呼び出し |
| `scripts/core/scenario_engine.gd` | シナリオループ、コマンドの順次実行 |
| `scripts/game_scene.gd` | 本番用ゲームシーン（F5で実行） |
| `scripts/test_scenario_engine.gd` | テスト用シーン（F6で実行） |

### 旧システム（参考用、現在は未使用）

| ファイル | 役割 |
|---|---|
| `scripts/novel_system.gd` | 旧テキスト表示・入力処理（`_input`でcomplete_text()を呼ぶ方式） |
| `scripts/scenario.gd` | 旧シナリオ実行 |

### オートロード（F5実行時のみ有効）

- `SceneManager` (`scripts/scene_manager.gd`) - シーン遷移管理
- `TrophyManager` (`scripts/trophy_manager.gd`) - トロフィー管理（`_input`なし）

### F5とF6の違い

- F5: タイトル画面 → SceneManager.goto_game() → game_scene.tscn
- F6: test_scenario_engine.tscn を直接実行
- F5のみ: SubtitleDisplay、toast_notification が存在
- どちらも `_input()` ハンドラを持つのは TextDisplay, ChoiceDisplay（非アクティブ時は無効）, GameScene/TestScene（キーのみ）

---

## 3. 試した対策と結果

### 対策1: `accept_event()` の追加

**仮説**: `_input()` のイベントが他のハンドラに伝播し、二重処理されている  
**対応**: WAITING/ANIMATING状態でのクリック処理後に `accept_event()` を追加  
**結果**: ❌ 効果なし

### 対策2: `_advance_requested` シグナルの早期発行防止

**仮説**: `_clear_internal()` から `_advance_requested.emit()` が発行され、次の `await _advance_requested` が即座に解決される  
**対応**: `_clear_internal()` から `_advance_requested.emit()` を削除、`wait_for_advance()` の先頭で `await get_tree().process_frame` を追加  
**結果**: ❌ 効果なし

### 対策3: 時間ベースのスキップ保護タイマー

**仮説**: 前のクリックイベントが残留し、`wait_for_advance()` 開始直後に処理される  
**対応**: `_skip_protection_timer: float = 0.2` を追加、WAITING開始後0.2秒間は入力を無視  
**結果**: ❌ 効果なし（タイマーが `await get_tree().process_frame` の間に消費される疑い）

### 対策4: フレーム数ベースの保護カウンター（3フレーム → 10フレーム）

**仮説**: 時間ベースだとフレームレート不安定で保護が不十分  
**対応**: `_skip_protection_frames` カウンター（3フレーム → 10フレームに増加）  
**結果**: ❌ 効果なし（保護終了直後にクリックが来る）

### 対策5: IDLE状態でのクリック消費

**仮説**: `go_next=true` でスキップした際、IDLE状態の間にクリックイベントが到着し、次の `wait_for_advance()` で処理される  
**対応**: IDLE状態でもクリックを `accept_event()` で消費  
**結果**: ❌ 効果なし（IDLE状態にクリックが来ていないことがログで確認）

### 対策6: `_input()` → `_process()` ポーリングベースに変更

**仮説**: 幽霊クリックが `_input()` イベントシステムのみに影響し、`Input.is_mouse_button_pressed()` には影響しない  
**対応**: WAITING状態のクリック検出を `_input()` のイベントハンドラから `_process()` での `Input.is_mouse_button_pressed()` ポーリングに完全移行。立ち上がりエッジ検出（false→true遷移）のみ受け付け  
**結果**: ❌ 効果なし（`Input.is_mouse_button_pressed()` でも同様にクリックが検出される）

### 対策6の追加診断（最新、未テスト）

**対応**: ミリ秒タイムスタンプ、FPS情報、`_input()` の全MouseButtonイベントログを追加  
**目的**: 
- クリック検出時の実際の経過時間（ミリ秒）を計測
- FPSから「frame 562」等の意味を正確に把握
- `_input()` イベントと `_process()` ポーリングの対応関係を確認

---

## 4. ログ分析から判明している事実

### クリックイベントの特徴

1. **`Input.is_mouse_button_pressed()` でも検出される** → 物理的なマウスボタン状態に反映されている
2. **`_input()` のMouseButtonイベントとしても届く** → Godotの入力システムとして「正しい」イベント
3. **ページ送り時のクリックには先行する `pressed=false`（ボタンリリース）がない**
   - 通常のクリック: `pressed=false` → `MouseMotion` → `pressed=true`
   - 問題のクリック: いきなり `pressed=true`
4. **保護期間を延長しても、保護終了直後にクリックが来る**（タイミングが保護に追従する）
5. **最新ログではframe 562で検出**（FPS不明のため実時間は不明、次のテストで判明予定）

### 正常に動作するケース

- テキスト送り（new_page=false）: ユーザーが手動でクリックして進行 → 正常
- go_next=true: クリック待機をスキップ → 正常（仕様通り）
- F6でのテスト: 問題なし

### プロジェクト全体の `_input()` ハンドラ調査結果

`parse_input_event()`（合成入力イベント生成）の使用: **なし**  
`_unhandled_input()` の使用: **なし**  
F5実行時にアクティブな `_input()` ハンドラ:
- `TextDisplay._input()` - マウス/キー処理
- `ChoiceDisplay._input()` - 選択肢表示中のみ有効
- `game_scene._input()` - KEY_S（スキップ）, KEY_T（トロフィー）のみ

**旧システムの `novel_system.gd` はF5実行時のシーンツリーに含まれない**ことを確認済み。

---

## 5. 現在のコードの状態

### `text_display.gd` の現在の設計

```
状態遷移:
  IDLE → ANIMATING (show_text呼び出し)
  ANIMATING → IDLE (_complete_animation / ユーザークリック)
  IDLE → WAITING (wait_for_advance呼び出し)
  WAITING → IDLE (クリック検出 / force_complete)

クリック検出方式:
  ANIMATING: _input() イベントベース（クリックでアニメーション即完了）
  WAITING:   _process() ポーリングベース（Input.is_mouse_button_pressed の立ち上がりエッジ検出）
```

### コマンド実行フロー（execute_dialogue）

```
1. text_display.set_instant_display(skip_controller.is_skipping)
2. text_display.set_go_next(go_next)
3. await text_display.show_text(text, new_page)     ← アニメーション完了まで待機
4. if go_next: return                                ← クリック待機スキップ
5. await text_display.wait_for_advance()             ← クリック待機
```

### デバッグログの状態

- `_input()`: MouseButton イベント（pressed/released）とキーイベントをログ出力（ミリ秒タイムスタンプ付き）
- `_process_waiting_click()`: クリック検出時にフレーム数、経過ミリ秒、FPSをログ出力
- `wait_for_advance()`: WAITING開始時のマウス状態、ミリ秒、FPSをログ出力
- `command_executor.gd` / `scenario_engine.gd`: コマンド実行の開始/完了をログ出力

---

## 6. 最新ログ分析（2026年2月8日）

### テスト条件

- F5（ゲーム全体実行）
- シナリオ: main.json → shared_day_1010_c.json
- FPS: 164-165（安定）

### 全コマンドのクリック待機時間

| コマンド | new_page | go_next | WAITING開始(msec) | クリック(msec) | 待機時間 | フレーム数 |
|---|---|---|---|---|---|---|
| 2 | false | false | 39551 | 39933 | 382ms | 64 |
| 3 | false | false | 41085 | 42007 | 922ms | 153 |
| 4 | false | false | 44118 | 44676 | 558ms | 93 |
| 5 | false | false | 47187 | 48454 | 1267ms | 210 |
| 6 | false | false | 50868 | 52020 | 1152ms | 191 |
| 7 | false | true | - | - | スキップ | - |
| **8** | **true** | **false** | **53785** | **55349** | **1564ms** | **259** |
| 9 | false | false | 57563 | (ログ切断) | - | - |

### 重要な発見

1. **コマンド7（go_next=true）の動作**
   - `show_text()` が完了した後に `wait_for_advance()` をスキップしてコマンド8に進む（仕様通り）
   - ただし、ユーザー報告では「コマンド7のテキストが途中までしか表示されていない」とのこと
   - ログ上は `show_text() completed` となっているが、実際の表示が完了していない可能性
2. **コマンド8の待機時間は1564msで全コマンド中最長**
   - 自動進行していない。ユーザーのクリックを1.6秒間正しく待機している
3. **全クリックに正規の `_input()` イベントが対応**
   - 各クリックに `MouseButton(pressed=true)` が `_input()` で記録されている
   - 各クリック後、次のコマンドのANIMATING中に `MouseButton(pressed=false)` リリースが記録されている
4. **go_next→new_page遷移のタイミング**
   - コマンド6のリリース（msec=52123）→ コマンド7アニメーション開始 → `show_text() completed` → go_nextスキップ → コマンド8 WAITING開始（msec=53785）→ 1564ms後にクリック

### ユーザー報告との不一致

**ユーザー報告**: 「コマンド7のテキストが途中までしか表示されていない」「ページ送りしているテキストは７ですよ」

**ログの状況**: 
- コマンド7の `show_text()` は完了している（`show_text() completed`）
- コマンド8は1564ms待機してからクリックを受け付けている

**考えられる原因**:
1. **`_animation_finished` シグナルが早期に発行されている**
   - `show_text()` 内で `await _animation_finished` を待っているが、実際のアニメーション完了前にシグナルが発行されている可能性
   - `_complete_animation()` が何らかの理由で早期に呼ばれている
2. **コマンド7のテキストが完全に表示される前にコマンド8の `new_page=true` でクリアされている**
   - コマンド8の `show_text(new_page=true)` で `_clear_internal()` が呼ばれ、コマンド7のテキストが消える
   - ただし、ログ上はコマンド7の `show_text() completed` の後にコマンド8が開始されている
3. **視覚的な問題**
   - アニメーションは完了しているが、テキストが画面に完全に表示される前に次のページに進んでいる（レンダリングタイミングの問題）

### 結論

ログ上は正常に見えるが、ユーザー報告ではコマンド7のテキストが途中までしか表示されていない。`_animation_finished` シグナルの発行タイミングや、実際のテキスト表示完了の検証が必要。

### 考えられる解釈

1. **対策6（ポーリングベース変更）が効果を発揮している可能性**
   - 以前の `_input()` ベースでは発生していた幽霊クリックが、ポーリングベースでは検出されなくなった
2. **間欠的なバグの可能性**
   - 特定の条件（FPS低下、シーン遷移直後等）でのみ発生する
3. **以前のテストでユーザーが無意識にクリックしていた可能性**
   - ただし、ユーザーは複数回にわたり「クリックしていない」と明確に報告しているため、慎重な判断が必要

---

## 7. 今後の調査方針

### 最優先: コマンド7のテキスト表示完了の検証

ユーザー報告では「コマンド7のテキストが途中までしか表示されていない」とのこと。以下を確認:

1. **`_animation_finished` シグナルの発行タイミング**
   - `_complete_animation()` が呼ばれるタイミングをログで確認
   - `_char_index` が `_current_text.length()` に達しているか確認
   - `show_text() completed` ログの時点で、実際にテキストが完全に表示されているか視覚的に確認
2. **`instant_display` フラグの状態**
   - コマンド7実行時に `instant_display` が `true` になっていないか確認
   - スキップモードが有効になっていないか確認
3. **コマンド7→8の遷移タイミング**
   - コマンド7の `show_text() completed` からコマンド8の `show_text()` 開始までの時間を確認
   - コマンド8の `new_page=true` による `_clear_internal()` がコマンド7のテキストを消すタイミングを確認

### 再現テスト

今回のログではバグが再現しなかったため、以下を確認:

1. **複数回テストして再現率を確認**
   - 5回程度F5実行し、バグが再現するか確認
   - 再現しなければ対策6（ポーリングベース化）が有効だった可能性
2. **再現した場合のログ確認**
   - コマンド7の `_char_index` と `_current_text.length()` をログ出力して、アニメーション完了を検証
   - コマンド8の待機時間が極端に短い（100ms以下）場合 → 幽霊クリック
   - 待機時間が500ms以上の場合 → 別の要因（ユーザー操作の可能性）
3. **以前のバグ発生環境との差異確認**
   - FPSの違い、ウィンドウフォーカス状態、マウス/タッチパッドの種別

### 診断ログの分析ポイント（再現した場合）

現在のコードに追加したミリ秒タイムスタンプ・FPS・_inputイベントログで以下を確認:

1. **FPSの値** → frame数を実時間に変換し、クリック検出までの実際の経過秒数を把握
2. **`_input()` の MouseButton(pressed=true) が WAITING 状態中に届いているか**
   - 届いている場合: 物理的なクリックが存在する（ユーザーの無意識クリック or ハードウェア問題）
   - 届いていない場合: `Input.is_mouse_button_pressed()` のみが変化する特殊な状態
3. **WAITING開始からクリック検出までの実時間（ミリ秒）**
   - 100ms以下: フレーム処理中の入力汚染
   - 100-500ms: タイミング的に残留イベントの可能性
   - 500ms以上: ユーザーの操作である可能性が高い

### 仮説と対応案

#### 仮説A: ユーザーの無意識クリック（現時点で最有力）

前回のログでframe 562という高い値が出ており、FPSが高い場合でも1秒以上の遅延がある。ユーザーのクリックリズムが `go_next` による自動進行と重なっている可能性。

**対応案**:
- `go_next=true` → `new_page=true` 遷移時に、より長い保護期間（1-2秒）を設定
- または `new_page=true` の後に最低表示時間を設ける

#### 仮説B: Godotエンジンレベルでの入力イベント生成

シーン遷移やControl配置変更時にGodotが内部的にマウスイベントを生成する可能性。

**対応案**:
- F5とF6で同一シナリオ（go_next→new_page含む）を実行して比較
- Control の `mouse_filter` 設定を見直し

#### 仮説C: タッチパッドの誤タップ

ユーザーがWindowsラップトップを使用している場合、タッチパッドの誤タップがクリックとして認識される可能性。

**対応案**:
- ユーザーに確認（外付けマウス使用か、タッチパッドか）
- 再現テスト時にタッチパッドを無効化して確認

### コード面での追加対策案

1. **WAITING状態でのマウスリリース必須化**
   - WAITING開始時に `_waiting_needs_release = true` を常に設定
   - リリースイベント（`pressed=false`）を確認してからクリック受付
   - 欠点: 初回クリック時にダブルクリックが必要になる

2. **go_next後の最低表示時間**
   - `go_next=true` の直後の `new_page=true` コマンドで、最低1秒間の表示時間を保証
   - `command_executor.gd` で前コマンドの `go_next` フラグを記憶し、次コマンドの `wait_for_advance()` 前に遅延挿入

3. **旧システムの方式に回帰**
   - `_input()` ベースに戻し、旧 `novel_system.gd` の `complete_text()` パターンを参考に、テキスト表示状態を厳密に管理

---

## 8. 変更したファイル一覧

| ファイル | 変更内容 |
|---|---|
| `scripts/ui/text_display.gd` | 大幅変更（クリック検出のポーリング化、デバッグログ追加） |
| `scripts/core/command_executor.gd` | デバッグログ追加のみ |
| `scripts/core/scenario_engine.gd` | デバッグログ追加のみ |

### Git差分確認方法

```bash
git diff scripts/ui/text_display.gd
git diff scripts/core/command_executor.gd
git diff scripts/core/scenario_engine.gd
```

---

## 9. 再現手順

1. F5でゲーム全体を実行
2. タイトル画面で「ゲームを始める」をクリック
3. テキストをクリックで進める（コマンド2-6）
4. コマンド7（go_next=true）が自動進行した後、コマンド8（new_page=true）でクリックしていないのにページが進むか確認
5. コンソールログでコマンド8前後の `_input()` イベントと `_process_waiting_click()` のログを確認

---

## 10. 次の調査者が最初に確認すべきポイント

### ステップ1: バグの再現確認

1. **F5でゲームを実行し、コマンド7→8の遷移を5回程度テスト**
   - バグが再現するか確認
   - 再現率を記録（例: 5回中2回発生 = 40%）

2. **再現した場合のログを取得**
   - コマンド7の `show_text()` 開始からコマンド8の `wait_for_advance()` 完了までのログを保存
   - 特に以下のタイミングを確認:
     - コマンド7の `_complete_animation()` が呼ばれるタイミング
     - コマンド7の `show_text() completed` ログ
     - コマンド8の `show_text() new_page=true` ログ
     - コマンド8の `wait_for_advance()` 開始とクリック検出のタイミング

### ステップ2: コマンド7のテキスト表示完了の検証

**追加すべきログ**（`text_display.gd` の `_complete_animation()` 内）:

```gdscript
func _complete_animation() -> void:
    print("[TextDisplay] _complete_animation() called, _char_index=%d, _current_text.length()=%d" % [_char_index, _current_text.length()])
    _displayed_text = _current_text
    _char_index = _current_text.length()
    _state = State.IDLE
    _finalize_text()
    _animation_finished.emit()
    print("[TextDisplay] _animation_finished emitted")
```

**確認事項**:
- `_char_index` が `_current_text.length()` と一致しているか
- `show_text() completed` ログの直前に `_complete_animation()` が呼ばれているか
- コマンド7のテキストが実際に画面に完全に表示されているか（視覚的確認）

### ステップ3: 再現しない場合の確認

今回のログではバグが再現しなかったため、以下を確認:

1. **対策6（ポーリングベース化）が有効だった可能性**
   - 複数回テストして再現しない場合は、対策6が成功したと判断
   - ただし、ユーザー報告の「コマンド7のテキストが途中までしか表示されていない」問題は別途調査が必要

2. **コマンド7のテキスト表示問題の調査**
   - `_complete_animation()` に上記のログを追加して再テスト
   - `instant_display` フラグの状態をログ出力して確認

### ステップ4: コードレビュー

以下のファイルを確認して、現在の実装を理解:

1. `scripts/ui/text_display.gd` - 特に以下:
   - `show_text()` メソッド（行168-199）
   - `_complete_animation()` メソッド（行268-273）
   - `_process_animation()` メソッド（行92-106）
   - `wait_for_advance()` メソッド（行202-226）
   - `_process_waiting_click()` メソッド（行110-155）

2. `scripts/core/command_executor.gd` - 特に以下:
   - `execute_dialogue()` メソッド（行85-116）

### ステップ5: 関連ドキュメントの確認

- `documents/handoff_instructions.md` - プロジェクト全体の概要
- `documents/project_overview.md` - ゲーム仕様書
- 旧システムの `scripts/novel_system.gd` - 参考用（動作していた実装）

---

## 11. 参考情報

### 旧システムとの比較

旧システム（`novel_system.gd`）では `waiting_for_click` フラグと `text_click_processed` シグナルを使用していた。新システムでは `_advance_requested` シグナルと `await` を使用している。

### Godotの入力システムに関する注意点

- `_input()` はイベントベース（各イベントごとに呼ばれる）
- `Input.is_mouse_button_pressed()` はポーリングベース（現在の状態を取得）
- `accept_event()` はイベントの伝播を止めるが、`Input.is_mouse_button_pressed()` の状態には影響しない
- シグナルが `await` より前に発行された場合、`await` は待機しない（Godotの仕様）

### デバッグ時の注意点

- FPSが高い（164-165）場合、フレーム単位の保護は短時間になる
- ミリ秒タイムスタンプ（`Time.get_ticks_msec()`）は相対時間の計測に有効
- `_input()` と `_process()` の実行順序は保証されていない

---

## 12. 根本原因の特定と修正（2026年2月10日）

### 🎯 問題の再定義

#### 当初の誤解
調査記録では「ページ送り（`new_page=true`）時に自動進行」と記載していたが、これは**問題の本質を誤解していた**。

#### 実際の問題
ユーザー報告：「`go_next=true`のコマンドで、テキストが途中までしか表示されずに次のコマンドに進む」

**根本原因**:
```gdscript
// command_executor.gd の execute_dialogue()
await text_display.show_text(text, new_page)
if go_next:
    return  // ← これが原因！クリック待機をスキップしている
await text_display.wait_for_advance()
```

### 🔍 `go_next`フラグの本来の目的

#### 誤った実装
- `go_next=true`でクリック待機をスキップ
- これにより、テキストを読む時間がなく次のコマンドに進んでしまう

#### 本来の目的
- 旧システムでは**インディケーター（クリック待ちマーク）の表示制御**に使用
- `go_next=true` → 次は画面が切り替わる（違うインディケーター）
- `go_next=false` → 次も同じページでテキスト追加（通常のインディケーター）
- **クリック待機のスキップではない**

#### ユーザーの正しい期待
- ノベルゲームとして、**すべてのテキストでクリックを待つべき**
- 内部フラグ（`go_next`、`new_page`）でユーザー操作を変えるべきではない

### ✅ 短期対応（2026年2月10日実施）

#### 修正内容
**ファイル**: `scripts/core/command_executor.gd`
**変更**: 行104-107の`if go_next: return`を削除

**Before**:
```gdscript
await text_display.show_text(text, new_page)

# go_next: アニメーション完了後に自動進行（クリック待機なし）
if go_next:
    print("[CommandExecutor] execute_dialogue() go_next=true, skipping wait_for_advance()")
    return

await text_display.wait_for_advance()
```

**After**:
```gdscript
await text_display.show_text(text, new_page)

# go_next フラグはインディケーター制御のみに使用（text_display.set_go_next()で設定済み）
# クリック待機は go_next に関わらず常に行う

await text_display.wait_for_advance()
```

#### 効果
- ✅ すべてのテキストでクリック待機を行う
- ✅ ユーザーがテキストを読む時間が確保される
- ✅ `go_next`フラグは残るのでインディケーター制御に使用可能
- ✅ JSONの変更は不要

### 🔄 長期的な対応案（判断材料）

#### 現状の課題
1. **JSONの複雑性**: `go_next`と`new_page`の組み合わせが複雑
2. **フラグの意味**: `go_next`が本来の目的（インディケーター制御）で使われていない
3. **保守性**: 将来的にフラグの意味を忘れて誤用する可能性

#### 対応案A: 現状維持（`go_next`を残す）

**実装**:
- 短期対応のみ（既に完了）
- `go_next`はインディケーター制御に使用

**メリット**:
- ✅ 実装済み、追加作業不要
- ✅ JSONの変更不要
- ✅ インディケーターの違いを保持

**デメリット**:
- ❌ JSONが複雑なまま
- ❌ フラグの意味が不明瞭（誤用の可能性）

**工数**: ゼロ

#### 対応案B: 次コマンド先読み方式

**実装**:
- `scenario_engine.gd`に`_peek_next_command()`メソッドを追加
- 次のコマンドが`new_page=true`かどうかを見てインディケーターを決定
- JSONから`go_next`を削除

**メリット**:
- ✅ JSONがシンプルになる（`go_next`が消える）
- ✅ フラグの誤用がなくなる
- ✅ インディケーターの違いを保持

**デメリット**:
- ❌ コマンド先読みの実装が必要
- ❌ 既存のJSONから`go_next`を削除する必要がある

**工数**: 中（コード変更：2-3時間、JSON変更：1-2時間）

**実装例**:
```gdscript
// scenario_engine.gd に追加
func _peek_next_command() -> Dictionary:
    if _current_command_index + 1 < scenario_data.size():
        return scenario_data[_current_command_index + 1]
    return {}

// command_executor.gd で使用
var next_command = scenario_engine._peek_next_command()
var next_is_new_page: bool = false
if next_command.get("type") == "dialogue":
    next_is_new_page = next_command.get("new_page", false)
text_display.set_next_is_new_page(next_is_new_page)
```

#### 対応案C: インディケーター統一

**実装**:
- インディケーターの違いを廃止
- すべてのテキストで同じインディケーター（▼）を表示
- `go_next`フラグを完全に削除

**メリット**:
- ✅ 最もシンプル
- ✅ JSONから`go_next`が消える
- ✅ フラグの誤用がなくなる

**デメリット**:
- ❌ インディケーターの違いがなくなる（UX的には問題ない可能性）
- ❌ 既存のJSONから`go_next`を削除する必要がある

**工数**: 小（コード削除：30分、JSON変更：1-2時間）

### 📊 推奨方針

#### 短期的（現在）
- ✅ 対応済み：`if go_next: return`を削除
- ✅ バグは修正済み

#### 中期的（次回開発時）
1. **インディケーターの重要性を確認**
   - インディケーターの違いがUXに重要か検討
   - 重要でない → **対応案C**を推奨
   - 重要 → **対応案B**を検討

2. **JSONのシンプル化**
   - 現在のJSONの複雑性が開発効率に影響しているか確認
   - 影響大 → 対応案BまたはCを実施
   - 影響小 → **対応案A**（現状維持）

#### 長期的（リファクタリング時）
- シナリオシステム全体の見直し
- コマンド設計の再検討（`new_page`、`go_next`などのフラグの整理）

### 🎯 判断基準

以下の質問に答えることで、最適な対応案を選択できます：

1. **インディケーターの違いは重要ですか？**
   - はい → 対応案AまたはB
   - いいえ → 対応案C

2. **JSONの複雑性は問題ですか？**
   - はい → 対応案BまたはC
   - いいえ → 対応案A

3. **開発工数をかけられますか？**
   - 2-3時間OK → 対応案B
   - 1時間以内 → 対応案C
   - 工数なし → 対応案A

### 📝 ステータス更新

**最終更新**: 2026年2月10日
**ステータス**: ✅ 解決済み（短期対応完了）
**次のアクション**: 中期的な対応案の検討（任意）

---

## 13. コードクリーンアップ（2026年2月10日）

バグ調査の過程で追加された不要なコードを削除しました。

### 削除内容

#### 1. ポーリング式クリック検出システム（`text_display.gd`）

**削除したコード**:
- `_waiting_mouse_was_down`、`_waiting_key_was_down`などのポーリング用変数
- `_waiting_needs_release`、`_waiting_frame_count`、`_waiting_start_msec`
- `WAITING_PROTECTION_FRAMES`定数
- `_process_waiting_click()`関数全体（約50行）

**理由**:
- 対策1-6として試した`_process()`ベースのクリック検出システム
- 結局バグの原因は仕様の誤りだったため不要
- イベントベース（`_input()`）のシンプルな実装に戻した

**変更後**:
```gdscript
func _input(event):
	var is_click = false

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			is_click = true
	elif event is InputEventKey:
		if (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE) and event.pressed:
			is_click = true

	if not is_click:
		return

	match _state:
		State.ANIMATING:
			_complete_animation()
		State.WAITING:
			_state = State.IDLE
			_advance_requested.emit()
```

#### 2. accept_event()呼び出し

**削除箇所**: `text_display.gd`の`_input()`関数内

**理由**:
- イベント消費を試みた対策だったが効果なし
- Godotのイベント伝播に影響を与える可能性があり不要

#### 3. デバッグログ

**削除したファイル**:
- `scripts/ui/text_display.gd` - 約10箇所のprint文
- `scripts/core/command_executor.gd` - 約5箇所のprint文
- `scripts/core/scenario_engine.gd` - 約10箇所のprint文

**削除した内容**:
- ミリ秒タイムスタンプ付きログ
- FPS情報
- 状態遷移の詳細ログ
- コマンド実行ログ

**理由**:
- バグ調査のために追加された一時的なログ
- 本番環境では不要
- デバッグが必要な場合はGodotのデバッガを使用

#### 4. 不要な初期化コード

**削除箇所**: `text_display.gd`の`wait_for_advance()`関数

**削除前**:
```gdscript
func wait_for_advance() -> void:
	print("[TextDisplay] wait_for_advance() called")
	await get_tree().process_frame
	_state = State.WAITING
	_indicator_visible = true
	_indicator_blink_timer = 0.0
	_update_display()

	# ポーリングベースのクリック検出を初期化
	_waiting_frame_count = 0
	_waiting_start_msec = Time.get_ticks_msec()
	var mouse_currently_down = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var key_currently_down = Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_SPACE)
	_waiting_mouse_was_down = mouse_currently_down
	_waiting_key_was_down = key_currently_down
	_waiting_needs_release = mouse_currently_down

	print("[TextDisplay] wait_for_advance() WAITING")
	await _advance_requested
	print("[TextDisplay] wait_for_advance() received _advance_requested")
```

**削除後**:
```gdscript
func wait_for_advance() -> void:
	_state = State.WAITING
	_indicator_visible = true
	_indicator_blink_timer = 0.0
	_update_display()

	await _advance_requested
```

#### 5. show_text()の不要なコード

**削除内容**:
- `new_page=true`時の即座のANIMATING状態設定（IDLE時間最小化の試み）
- デバッグログ

**理由**:
- シンプルに`_state = State.ANIMATING`で十分
- 複雑化していたコードを簡素化

### 残したコード

#### `set_go_next()`メソッドと`_go_next`変数

**理由**:
- インディケーター制御に使用中（▼ vs ▽）
- セクション12の対応案A/B/Cのどれを選ぶかで削除するか判断

**条件**:
- 対応案A（現状維持）→ 残す
- 対応案B（次コマンド先読み）→ 削除してロジック変更
- 対応案C（インディケーター統一）→ 削除

### クリーンアップ効果

- **削除行数**: 約80行
- **コード可読性**: 大幅に改善
- **保守性**: シンプルなイベントベース実装に戻った
- **パフォーマンス**: `_process()`での不要なポーリング処理がなくなった

### 今後の推奨事項

1. **本番デプロイ前の確認**
   - クリーンアップ後のコードでゲーム全体を実行
   - ページ送り、テキスト送りが正常に動作することを確認

2. **go_next関連コードの方針決定**
   - セクション12の対応案A/B/Cを検討
   - 決定後、必要に応じて`set_go_next()`を削除

3. **デバッグログポリシーの確立**
   - 今後のデバッグログは一時的なものとして明示
   - `# DEBUG:`などのコメントを追加
   - 調査完了後は必ず削除
