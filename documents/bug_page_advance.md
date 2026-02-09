# バグ調査記録：ページ送り自動進行問題

**作成日**: 2026年2月8日  
**最終更新**: 2026年2月8日（ログ分析追記）  
**ステータス**: 未解決（調査中） → 再現性の再確認が必要

---

## 📋 クイックリファレンス

### 問題の要約

- **症状**: ページ送り（`new_page=true`）時に、ユーザーのクリックを待たずに自動進行
- **発生箇所**: コマンド7（`go_next=true`）→ コマンド8（`new_page=true`）の遷移時
- **再現条件**: F5（ゲーム全体実行）でのみ発生、F6（テストシーン）では発生しない
- **追加報告**: コマンド7のテキストが途中までしか表示されていない

### 最新の状況（2026年2月8日）

- **対策6（ポーリングベース化）を実装**: WAITING状態のクリック検出を `_input()` から `_process()` ポーリングに変更
- **最新テスト**: バグが再現せず（コマンド8は1564ms待機してからクリックを受け付け）
- **ただし**: ユーザー報告では「コマンド7のテキストが途中までしか表示されていない」とのこと

### 次のステップ

1. **再現テスト**: F5で5回程度実行し、バグの再現率を確認
2. **コマンド7の検証**: `_complete_animation()` にログを追加して、テキスト表示完了を検証
3. **ログ分析**: 再現した場合のログを詳細に分析（セクション10を参照）

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
