# 新しいシナリオエンジンのテスト手順

## 1. Godot エディタでシーンを作成

1. Godot エディタを開く
2. 新しいシーンを作成
3. ルートノードを `Control` にして、名前を `TestScene` にする
4. `TestScene` に `test_scenario_engine.gd` スクリプトをアタッチ
5. シーンを `scenes/test_scenario_engine.tscn` として保存

## 2. テストの実行

1. シーンを実行（F6 または シーン実行ボタン）
2. テキストが表示されることを確認
3. クリック（マウスまたはEnter/Space）で次のテキストに進むことを確認
4. `S` キーでスキップモードを切り替えて、自動進行することを確認

## 3. 期待される動作

- テキストが1文字ずつアニメーション表示される
- アニメーション中にクリックすると、即座に全文が表示される
- 全文表示後にクリックすると、次のテキストに進む
- スキップモード（Sキー）では、短い待機時間で自動的に次に進む

## 4. 問題が発生した場合

コンソール出力を確認してください。各処理で以下のようなログが出力されます：

```
[ScenarioEngine] Ready
[TextDisplay] Ready
[CommandExecutor] Ready
[ScenarioEngine] Starting scenario with 5 commands
[CommandExecutor] Dialogue: こんにちは！ (new_page: true)
[TextDisplay] Showing text: こんにちは！
[TextDisplay] Clicked
...
```

## 5. 次のステップ

基本動作が確認できたら、以下の機能を追加していきます：

- 背景表示
- BGM/SFX再生
- 選択肢表示
- エピソード/共用シナリオ呼び出し
- グレースケール効果
