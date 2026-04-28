# キミノコエ - Claude Code 開発ガイド

## プロジェクト概要

Godot 4 製のノベル＆アドベンチャーゲーム。シナリオは `scenarios/` 配下の JSON ファイルで管理されている。

## ドキュメント一覧

開発に必要なドキュメントは `documents/dev/` にある。

| ファイル | 内容 |
|---------|------|
| `project_overview.md` | ゲーム概要・キャラクター・ルート設計・ミスリード設定 |
| `scenario_rules.md` | シナリオ原稿（MD形式）の記法ルール |
| `trophy_system.md` | トロフィー一覧・解放条件・実装方針 |
| `audio_design.md` | BGM・SE の割り当て一覧 |
| `handoff_instructions.md` | 引き継ぎ情報・現在の作業状況 |
| `test_cases.md` | テストケース一覧 |
| `ui_design.md` | UI 設計 |

## シナリオ JSON の主要コマンド

- `dialogue` — テキスト表示。`new_page: true` でページ送り、`go_next: true` で自動進行
- `background` — 背景切り替え（`path`）
- `subtitle` — サブタイトル表示。`next_background` で背景もセット可能
- `bgm` / `sfx` — 音楽・効果音
- `choice` — 選択肢。`hidden_if` で条件付き非表示
- `load_scenario` — 別シナリオへ移動（スタック不使用）
- `call_subscenario` — サブシナリオ呼び出し（終了後に呼び出し元へ戻る）
- `set_flag` / `branch_flag` / `branch_counter` — フラグ操作・分岐
- `visit_location` — ロケーション訪問記録（トロフィー判定に使用）
- `index` — ジャンプ先マーカー
- `jump` — 同シナリオ内ジャンプ

## 重要な規則

- シナリオ JSON の dialogue `text` に先頭全角スペース（`　`）は不要（MD 原稿側の記法）
- エピソードファイル名はゼロパディングあり（`ep_01.json`）、システム内部 ID はなし（`ep_1`）
- `subtitle` + 直後の `background` は `subtitle` の `next_background` にまとめる
- `choice` で `scenario` と `next_index` を混在させない（Memory 参照）

## JSON バリデーション

シナリオ JSON に構文エラーがないか確認するには `/validate-json` を使う。
