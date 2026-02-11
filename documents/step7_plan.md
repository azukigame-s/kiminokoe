# Step 7: UI/UX デザイン 実装計画

## スコープ

4つのサブステップに分割して実施する。テキスト表示は現状の全画面オーバーレイ（かまいたちの夜風）を維持。

| サブステップ | 内容 | 優先度 | 状態 |
|---|---|---|---|
| 7a | 全画面統合UI改善 | 最優先（他の基盤） | **完了** |
| 7b | テキストログ（足跡） | 中 | **完了** |
| 7c | トロフィー画面 | 中 | 未着手 |
| 7d | セーブ/ロード機能 | 最後（最も複雑） | 未着手 |

### 実施順序と理由

```
7a (UI統一) ← 共通スタイル定数・ヘルパーを確立     ✅ 完了
  ├── 7b (足跡/バックログ) ← TextDisplay改修が必要  ✅ 完了
  ├── 7c (トロフィー画面) ← 独立機能、仕様書あり    ← 次
  └── 7d (セーブ/ロード) ← 最も複雑、全体が安定してから
```

---

## 7a: 全画面統合UI改善

### 目的

全画面（タイトル/設定/ゲーム/トロフィー/ポーズメニュー）で一貫したビジュアルを確立。レスポンシブ対応。ポーズメニューの新規追加。

### 現状の課題

1. ボタンスタイルの不統一（タイトル: 透明+黒文字、設定: ボーダー+白文字）
2. スキップインジケータが固定座標 `Vector2(900, 20)` で非レスポンシブ
3. 色・フォントサイズ・マージン等のマジックナンバーが各スクリプトに散在
4. ゲーム中に設定/トロフィー/タイトルへ戻る手段がない（ポーズメニュー未実装）

### 新規作成ファイル

#### `scripts/ui/ui_constants.gd`

共通デザイントークン（`class_name UIConstants`）。

```gdscript
# Color Palette
const COLOR_TEXT_PRIMARY = Color(1.0, 1.0, 1.0, 1.0)       # 白
const COLOR_TEXT_SECONDARY = Color(0.7, 0.7, 0.7, 1.0)     # グレー
const COLOR_TEXT_DISABLED = Color(0.4, 0.4, 0.4, 1.0)      # 無効
const COLOR_TEXT_ACCENT = Color(1.0, 0.8, 0.0, 1.0)        # ゴールド（ホバー）
const COLOR_TEXT_TITLE_DARK = Color(0.224, 0.196, 0.2, 1.0) # タイトル用黒

const COLOR_BG_OVERLAY = Color(0, 0, 0, 0.5)               # 半透明黒
const COLOR_BG_PANEL = Color(0, 0, 0, 0.8)                 # パネル背景
const COLOR_BG_DARK = Color(0.1, 0.1, 0.1, 0.9)            # 設定/メニュー背景
const COLOR_BG_BUTTON = Color(0.2, 0.2, 0.2, 0.8)          # ボタン通常
const COLOR_BG_BUTTON_HOVER = Color(0.3, 0.3, 0.3, 0.9)    # ボタンホバー

# Font Sizes
const FONT_SIZE_TITLE = 36
const FONT_SIZE_HEADING = 28
const FONT_SIZE_BODY = 24
const FONT_SIZE_BUTTON_LARGE = 32
const FONT_SIZE_BUTTON_NORMAL = 20
const FONT_SIZE_CAPTION = 16
const FONT_SIZE_SKIP_INDICATOR = 28

# Layout
const MARGIN_TEXT = 0.1
const CORNER_RADIUS = 8
const BORDER_WIDTH = 2
```

#### `scripts/ui/ui_style_helper.gd`

再利用可能なスタイリングユーティリティ（`class_name UIStyleHelper`）。

- `static func create_panel_style(bg_color, corner_radius, border_width, border_color) -> StyleBoxFlat`
- `static func style_menu_button(button: Button) -> void` — 設定/メニュー用ボーダー付きボタン
- `static func style_title_button(button: Button) -> void` — タイトル用透明ボタン

#### `scripts/ui/pause_menu.gd`

ゲーム中のポーズメニュー。Escapeキーで開閉。

- **ボタン**: ゲームに戻る / バックログ(7b) / セーブ(7d) / ロード(7d) / トロフィー(7c) / 設定 / タイトルへ戻る
- 半透明ダーク背景 + 中央揃え VBoxContainer
- `get_tree().paused = true` で入力をブロック（`process_mode = PROCESS_MODE_WHEN_PAUSED`）
- 7b/7c/7d 未実装時はプレースホルダー（グレーアウト）

#### `scripts/ui/settings_panel.gd`

settings_scene.gd から設定UIロジックを抽出した再利用可能コンポーネント。ポーズメニューからも、タイトルからも呼び出せる。

### 修正ファイル

| ファイル | 変更内容 |
|---|---|
| `scripts/game_scene.gd` | ポーズメニュー追加、スキップインジケータをアンカーベースに修正、ESC入力処理追加 |
| `scripts/settings_scene.gd` | UIConstants/UIStyleHelper を使用してリファクタ |
| `scripts/title_scene.gd` | トロフィーボタン追加、UIConstants 適用 |
| `scenes/title_scene.tscn` | TrophyButton ノード追加 |
| `scripts/scene_manager.gd` | `TROPHY_SCENE` 定数と `goto_trophy()` 追加 |

### スキップインジケータ修正

```gdscript
# Before: 固定座標（壊れる）
skip_indicator.position = Vector2(900, 20)

# After: アンカーベース（レスポンシブ）
skip_indicator.anchor_left = 1.0
skip_indicator.anchor_top = 0.0
skip_indicator.offset_left = -120
skip_indicator.offset_top = 20
```

---

## 7b: 足跡（テキストログ） ✅ 完了

### 概要

セッション中の全テキスト履歴を「足跡」として閲覧可能。Lキー / 下部メニュー / ポーズメニューから開閉。

### 実装済みファイル

#### `scripts/core/backlog_manager.gd`

- `class_name BacklogManager` — エントリを `{ "text": text }` 辞書で保存
- `MAX_ENTRIES = 500`
- `add_entry()` / `get_history()` / `clear()`

#### `scripts/ui/backlog_display.gd`

- CanvasLayer(layer=50) 上に配置（`game_scene.gd` で設定）
- `process_mode` は親 CanvasLayer から継承（WHEN_PAUSED）
- 和風ノベル風デザイン:
  - 装飾線タイトル（── 足跡 ──）、深紅アクセント
  - PanelContainer エントリ（左3px深紅ボーダー、カード型背景）
  - 背景: `Color(COLOR_BASE_DARK, 0.85)`（半透明漆黒緑）
- 閉じるヒント: 「Esc / L」
- 入力: Escape / Lキーで閉じる

### キャプチャ対象

- `dialogue` テキスト → `command_executor.execute_dialogue()` で記録
- 選択した選択肢 → `scenario_engine.handle_choice()` で「▸ 選択肢テキスト」として記録

### 操作方法

- **Lキー**: バックログ開閉（ゲーム中）
- **下部メニュー「足跡」ボタン**: バックログを開く
- **ポーズメニュー「足跡」ボタン**: バックログを開く（ポーズメニューは一時非表示、閉じると戻る）
- **Esc / Lキー**: バックログを閉じる

---

## 7c: トロフィー画面

### 目的

project_overview.md の仕様に基づくトロフィー閲覧画面を実装。タイトル画面とポーズメニューからアクセス可能。

### UI仕様（project_overview.md より）

```
【通常トロフィー】
■ カード           「キラカードをあげた日」
□ 海               ──────────
■ バス停           「雪の日の待ちぼうけ」
□ キャッチボール   ──────────
...

【シークレットトロフィー】
■ 秘密基地         「僕たちだけの場所」
？？？              ──────────
...

進行度: 4/12 (33%)
```

- 取得済み通常: `■` + 名前 + `「説明」`
- 未取得通常: `□` + 名前（グレーアウト）
- 取得済みシークレット: `■` + 名前 + `「説明」`
- 未取得シークレット: `？？？`（グレーアウト）

### アクセス方法

- **タイトルから**: シーン遷移（`SceneManager.goto_trophy()`）
- **ゲーム中（ポーズメニューから）**: オーバーレイとして開く（シーン遷移するとゲーム状態が失われるため）

### 新規作成ファイル

#### `scripts/ui/trophy_screen.gd`

プログラマティック構築。ScrollContainer + VBoxContainer。

```
TrophyScreen (Control, full rect)
  ├── Background (ColorRect, dark)
  ├── ScrollContainer
  │   └── VBoxContainer
  │       ├── TitleLabel ("トロフィー")
  │       ├── NormalSection
  │       │   ├── SectionLabel ("【通常トロフィー】")
  │       │   └── TrophyItem × 7 (HBoxContainer: StatusIcon + Name + Description)
  │       ├── SecretSection
  │       │   ├── SectionLabel ("【シークレットトロフィー】")
  │       │   └── TrophyItem × 5
  │       └── ProgressLabel ("進行度: X/12 (Y%)")
  └── BackButton ("戻る")
```

#### `scenes/trophy_screen.tscn`

最小シーン（Control + script のみ）。

### 修正ファイル

| ファイル | 変更内容 |
|---|---|
| `scripts/trophy_manager.gd` | トロフィー説明文の追加、`get_all_trophy_display_data()`, `get_unlocked_trophy_count()`, `get_total_trophy_count()` 追加 |
| `scripts/scene_manager.gd` | `TROPHY_SCENE` 定数、`goto_trophy()` 追加 |

### TrophyManager に追加するデータ

```gdscript
var episode_trophy_descriptions: Dictionary = {
    "ep_1": "キラカードをあげた日",
    "ep_2": "波に揉まれた日",
    "ep_3": "雪の日の待ちぼうけ",
    "ep_4": "弟の悩みを聞いた日",
    "ep_5": "みんなで子猫を救った日",
    "ep_6": "兄の水で遊んだ日",
    "ep_7": "擁壁で動けなくなった日",
}

var secret_trophy_descriptions: Dictionary = {
    "secret_base": "僕たちだけの場所",
    "futako_jizo": "2体並びの地蔵",
    "takiba": "忘れられた場所",
    "kiminokoe": "失った声を取り戻した",
    "iro_story": "妹の秘密",
}
```

---

## 7d: セーブ/ロード機能

### 目的

マルチスロットのセーブ/ロード。ゲームの進行状態を保存・復元。

### 既存の基盤

`ScenarioEngine` に既にセーブ/ロードの骨格がある:

- `get_save_state()` — `scenario_path`, `index`, `stack` を返す（L305-310）
- `load_from_save_state()` — スタック復元 → シナリオ読込 → 再開（L324-362）

### 保存対象

| データ | ソース | 備考 |
|---|---|---|
| シナリオパス | `scenario_engine.current_scenario_path` | String |
| コマンドインデックス | `scenario_engine.current_index` | int |
| シナリオスタック | `scenario_engine.scenario_stack` | Array of {path, index} |
| 背景画像パス | `background_display` | **要追加**: `current_background_path` プロパティ |
| 背景エフェクト | `background_display.current_effect` | 既存 |
| BGMパス | `audio_manager` | **要確認**: 現在のBGMパス追跡の有無 |
| プレビューテキスト | `text_display` | 表示中テキストの先頭100文字 |
| バックログ | `backlog_manager.history` | Array[String] |
| トロフィー/進行度 | TrophyManager | **別ファイル管理**（セーブとは独立、永続的解除） |

### セーブフォーマット

ファイル: `user://saves/save_slot_N.json`（6スロット + オートセーブ1）

```json
{
    "version": 1,
    "timestamp": 1707000000,
    "preview_text": "最後に表示されたテキスト...",
    "background_path": "res://assets/backgrounds/sea.jpg",
    "background_effect": "normal",
    "bgm_path": "res://assets/music/sample_bgm.mp3",
    "scenario_state": {
        "scenario_path": "branches/day_1010/day_1010_b_1",
        "index": 15,
        "stack": [
            {"path": "main", "index": 3},
            {"path": "days/day_1010/exploration", "index": 8}
        ]
    },
    "backlog": ["テキスト1...", "テキスト2...", ...]
}
```

### 新規作成ファイル

#### `scripts/save_manager.gd`（オートロード）

- `save_game(slot, game_state) -> bool`
- `load_game(slot) -> Dictionary`
- `get_save_info(slot) -> Dictionary` — UI表示用（preview_text, timestamp のみ）
- `has_save(slot) -> bool`
- `delete_save(slot) -> void`
- `pending_load_state: Dictionary` — ロード選択後、GameScene で読み込むためのバッファ

#### `scripts/ui/save_load_screen.gd`

セーブ/ロード共用UI。モード切替（Save / Load）。

```
SaveLoadScreen (Control, full rect)
  ├── Background (ColorRect, dark)
  ├── TitleLabel ("セーブ" / "ロード")
  ├── GridContainer (2行 × 3列)
  │   └── SaveSlotPanel × 6
  │       ├── SlotNumber ("Slot 1")
  │       ├── PreviewText（最終テキスト）
  │       └── Timestamp ("2026/02/10 15:30")
  └── BackButton ("戻る")
```

- **セーブモード**: クリックで保存。データがあるスロットは上書き確認
- **ロードモード**: クリックで読み込み。空スロットはグレーアウト

#### `scenes/save_load_screen.tscn`

最小シーン。

### 修正ファイル

| ファイル | 変更内容 |
|---|---|
| `scripts/ui/background_display.gd` | `current_background_path` プロパティ追加、`set_background()` でパスを記録 |
| `scripts/game_scene.gd` | `get_full_save_state()`, `load_from_save()` 追加、pending load チェック |
| `scripts/scene_manager.gd` | `SAVE_LOAD_SCENE` 定数追加 |
| `scripts/title_scene.gd` | 「ロード」ボタン追加 |
| `scenes/title_scene.tscn` | LoadButton ノード追加 |
| `project.godot` | SaveManager をオートロードに追加 |

### ロードフロー（タイトルから）

1. タイトル画面で「ロード」クリック
2. `SceneManager.change_scene(SAVE_LOAD_SCENE)` （mode = "load"）
3. スロット選択 → `SaveManager.load_game(slot)` でデータ取得
4. `SaveManager.pending_load_state` にセット
5. `SceneManager.change_scene(GAME_SCENE)` でゲーム画面へ
6. `game_scene.gd._start_game()` で `pending_load_state` を検出、`load_from_save()` を実行

---

## 全ファイル一覧

### 新規作成（11ファイル）

| パス | サブステップ | 用途 |
|---|---|---|
| `scripts/ui/ui_constants.gd` | 7a | 共通デザイン定数 |
| `scripts/ui/ui_style_helper.gd` | 7a | スタイリングユーティリティ |
| `scripts/ui/pause_menu.gd` | 7a | ポーズメニュー |
| `scripts/ui/settings_panel.gd` | 7a | 再利用可能な設定パネル |
| `scripts/ui/backlog_manager.gd` | 7b | テキスト履歴データ |
| `scripts/ui/backlog_panel.gd` | 7b | バックログUI |
| `scripts/ui/trophy_screen.gd` | 7c | トロフィー画面 |
| `scenes/trophy_screen.tscn` | 7c | トロフィーシーン |
| `scripts/save_manager.gd` | 7d | セーブ/ロード管理（autoload） |
| `scripts/ui/save_load_screen.gd` | 7d | セーブ/ロードUI |
| `scenes/save_load_screen.tscn` | 7d | セーブ/ロードシーン |

### 修正（10ファイル）

| パス | サブステップ | 変更内容 |
|---|---|---|
| `scripts/game_scene.gd` | 7a,7b,7d | ポーズメニュー、バックログ、セーブ状態、スキップ修正 |
| `scripts/scene_manager.gd` | 7a,7c,7d | 新シーン定数・ナビゲーション追加 |
| `scripts/trophy_manager.gd` | 7c | 説明文・表示データヘルパー追加 |
| `scripts/settings_scene.gd` | 7a | UIConstants/UIStyleHelper でリファクタ |
| `scripts/title_scene.gd` | 7a,7c,7d | トロフィー・ロードボタン追加 |
| `scenes/title_scene.tscn` | 7a,7d | TrophyButton, LoadButton ノード追加 |
| `scripts/core/command_executor.gd` | 7b | バックログ連携 |
| `scripts/ui/background_display.gd` | 7d | 背景パス追跡追加 |
| `project.godot` | 7d | SaveManager autoload 追加 |
| `scripts/ui/text_display.gd` | 7b | （必要に応じて）履歴連携 |