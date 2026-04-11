# JSON ↔ MD テキスト照合チェックリスト

> JSONの各 `"text"` フィールドが `kiminokoe.md` の内容と一致しているかを確認するためのチェックリスト。
>
> **手順**: 各ファイルを確認したら `- [x]` に変更し、差分があれば「備考」欄に記載する。

---

## メイン

- [x] `scenarios/main.json`

---

## days

- [x] `scenarios/days/day_1010/main.json`
- [x] `scenarios/days/day_1010/exploration.json`
- [x] `scenarios/days/day_1010/evening_branch.json`
- [x] `scenarios/days/day_1010/evening_common.json`
- [x] `scenarios/days/day_1010/dinner.json`
- [x] `scenarios/days/day_1011/main.json`

---

## branches（day_1010）

- [x] `scenarios/branches/day_1010/day_1010_b_1.json`
- [x] `scenarios/branches/day_1010/day_1010_b_2.json`
- [x] `scenarios/branches/day_1010/day_1010_b_3.json`
- [x] `scenarios/branches/day_1010/day_1010_b_4.json`
- [x] `scenarios/branches/day_1010/day_1010_c_1.json`
- [x] `scenarios/branches/day_1010/day_1010_c_2.json`
- [x] `scenarios/branches/day_1010/day_1010_d_1.json`
- [x] `scenarios/branches/day_1010/day_1010_d_2.json`
- [x] `scenarios/branches/day_1010/day_1010_d_3.json`
- [x] `scenarios/branches/day_1010/day_1010_e_1.json`
- [x] `scenarios/branches/day_1010/day_1010_e_2.json`
- [x] `scenarios/branches/day_1010/day_1010_e_3.json`

---

## episodes

- [x] `scenarios/episodes/ep_00.json`
- [x] `scenarios/episodes/ep_00_beta.json`
- [x] `scenarios/episodes/ep_01.json`
- [x] `scenarios/episodes/ep_02.json`
- [x] `scenarios/episodes/ep_03.json`
- [x] `scenarios/episodes/ep_04.json`
- [x] `scenarios/episodes/ep_05.json`
- [x] `scenarios/episodes/ep_06.json`
- [x] `scenarios/episodes/ep_07.json`
- [x] `scenarios/episodes/ep_08.json`
- [x] `scenarios/episodes/ep_08_prime.json`

---

## shared

- [x] `scenarios/shared/shared_day_1010_c.json`
- [x] `scenarios/shared/shared_ep_3_after.json`
- [x] `scenarios/shared/shared_ep_7_shrine.json`
- [x] `scenarios/shared/shared_warabeuta.json`

---

## 備考欄

差分が見つかった場合はここに記載する。

| ファイル | 対応 | 内容 |
|----------|------|------|
| `main.json` | 修正済 | 3件修正（`必要なんてない`→`必要もない`、ロボット文構造、`とはいっても`→`もっとも`） |
| `main.json` | MD側で対応 | `地蔵焚西口` のルビ表記（MD側を修正予定） |
