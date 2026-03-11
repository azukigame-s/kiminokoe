# 音声設計

> 本ドキュメントは `project_overview.md` の BGMエイリアス・SE配置一覧から分離。

------

## BGMエイリアス一覧

BGMのパス定義は `scripts/ui/audio_manager.gd` の `bgm_aliases` 辞書に集約されている。
シナリオJSON・title_scene.gd ともにエイリアス名のみを指定することで、BGMファイルの変更が1箇所で完結する。

| エイリアス名 | ファイル                       | 用途                         |
| ------------ | ------------------------------ | ---------------------------- |
| `title`      | 悠久の彼方.mp3                 | タイトル画面                 |
| `main`       | 忘却の都.mp3                   | メイン・実家到着・探索シーン |
| `flashback`  | Ancient_Travelers.mp3          | ep_01〜ep_07 回想BGM         |
| `autumn`     | 秋の想い出.mp3                 | ep_00 回想BGM（プロローグ）  |
| `dinner`     | Old_home.mp3                   | 夕食シーン                   |
| `night`      | 冬待人.mp3                     | 夜・就寝シーン               |
| `suspense`   | 悲しい記憶.mp3                 | 焚き場・不穏シーン           |
| `stop`       | （空文字）                     | BGM停止                      |

------

## SE（効果音）配置一覧

SEファイルはすべて `assets/sounds/` 以下に配置する。
ループ再生は `sfx_loop` コマンドで制御。ワンショットは `sfx` コマンド。

### SEファイル一覧

| ファイル名 | 種別 | 説明 |
|---|---|---|
| `sounds/bus_button_sfx.mp3` | ワンショット | バスの降車ボタン音 |
| `sounds/bang_sfx.mp3` | ワンショット | 衝突音（ドンッ） |
| `sounds/crash_sfx.mp3` | ワンショット | 衝突後の破砕音 |
| `sounds/kite_sfx.mp3` | ワンショット | 凧の音（ピーヒョロロ） |
| `sounds/thunder_sfx.mp3` | ワンショット | 雷鳴 |
| `sounds/ambient/grass_walk.mp3` | ループ ch1 | 草道を歩く足音 |
| `sounds/ambient/rain.mp3` | ループ ch1 | 雨音（屋外） |
| `sounds/ambient/eaves_rain.mp3` | ループ ch1 | 軒下の雨音（屋根付き避難時） |
| `sounds/ambient/blizzard.mp3` | ループ ch1 | 吹雪（12月の回想） |
| `sounds/ambient/eerie_ambience.mp3` | ループ ch1 | 不穏な環境音（童歌演出用） |
| `sounds/ambient/wind_howl.mp3` | ループ ch2 | 吹きすさぶ風（焚き場） |
| `sounds/ambient/sea_waves.mp3` | ループ ch1 | 海の波音（海岸・砂浜） |
| `sounds/ambient/rocky_waves.mp3` | ループ ch2 | 岩場の波音（東岸ルート） |
| `sounds/ambient/underwater.mp3` | ループ ch1 | 水中SE（溺れる回想） |
| `sounds/ambient/night_insects.mp3` | ループ ch1 | 夜の秋虫（就寝シーン） |

**未配置（将来用）**: `stream.mp3`（川）/ `village_evening.mp3`（田舎の夕方）

### シーン別SE配置

| シナリオ | タイミング | SE | 備考 |
|---|---|---|---|
| **ep_00 / ep_00_beta** | バスのボタンを押す | `bus_button_sfx.mp3` | ワンショット |
| | 「ドンッ！！！！」 | `bang_sfx.mp3` | ワンショット |
| | 衝突直後 | `crash_sfx.mp3` | ワンショット |
| | 「誰かが遠くから叫ぶ声が聞こえる」 | `kite_sfx.mp3` | ワンショット |
| **day_1010_b_4** | BGM停止直後（細道入口） | `grass_walk.mp3` ch1 開始 | 焚き場への暗い細道 |
| | 焚き場背景（fire_pit.jpg）に切替 | ch1 停止 → `wind_howl.mp3` ch2 開始 | 廃墟の荒れ果てた風 |
| | 「頬に冷たいものが触れた。」 | `rain.mp3` ch1 開始 | 降り始める雨 |
| | 「その時、風が吹いた。」 | `thunder_sfx.mp3` | ワンショット（雷鳴） |
| | 焚き場退場（jump前） | ch1・ch2 両方停止 | |
| **day_1010_d_1** | バス停小屋（busstop2.jpg）表示時 | `eaves_rain.mp3` ch1 開始 | 北→岩場→南ルートのep_03前 |
| **day_1010_e_1** | バス停小屋（busstop2.jpg）表示時 | `eaves_rain.mp3` ch1 開始 | 東→北ルートのep_03前 |
| **ep_03**（flashback内） | flashback_start直後 | ch1（eaves_rain）停止 → `blizzard.mp3` ch1 開始（+12dB） | 10月雨から12月吹雪へ |
| | flashback_end（gradual）直前 | ch1（blizzard）停止 → `eaves_rain.mp3` ch1 再開 | 吹雪から10月雨へ復帰 |
| **shared_ep_3_after** | 「家に帰ることにした。」の後 | ch1（eaves_rain）停止 | 雨宿りシーン終了 |
| **shared_warabeuta** | poem表示中（ambient指定） | `eerie_ambience.mp3` ch1 開始・終了（poem内で自動管理） | BGMも一時停止（mute_bgm: true） |
| **day_1010_b_1** | sea_road.jpg 表示時 | `sea_waves.mp3` ch1 開始 | 海岸到着（東西両ルートの親） |
| **day_1010_c_1** | シナリオ冒頭 | ch1（sea_waves）停止 → `rocky_waves.mp3` ch1 開始 | 岩場ルート（波の質を切り替え） |
| | waterway.jpg 切替前 | ch1（rocky_waves）停止 | 用水路へ入るタイミング |
| **shared_day_1010_c** | beach.jpg 直後 | `sea_waves.mp3` ch1 開始 | 砂浜・白い少年のシーン |
| | ep_02 復帰後（bgm: main 直後） | `sea_waves.mp3` ch1 再開 | 水中から砂浜へ戻る |
| | シナリオ末尾 | ch1（sea_waves）停止 | 砂浜シーン終了 |
| **ep_02**（flashback内） | 「――その瞬間。」の直後 | `underwater.mp3` ch1 開始 | 波に飲み込まれる |
| | 「ただ青い景色が回る中…」の直後 | ch1（underwater）停止 | 意識が戻る（弟の声） |
| **evening_common** | bgm: night 直後 | `night_insects.mp3` ch1 開始 | 帰宅・就寝シーン |

### チャンネル設計

| チャンネル | 用途 | 同時再生 |
|---|---|---|
| ch1（ambient_player） | ベース環境音（雨・草・吹雪など） | ch2 と同時再生可 |
| ch2（ambient2_player） | オーバーレイ環境音（風など） | ch1 と同時再生可 |

**注意**: `sfx_loop_stop` は直後に `sfx_loop` で別トラックを開始する場合はデフォルト（即時停止）を使う。シーン終了時にフェードさせたい場合のみ `"fade": true` を指定する。
