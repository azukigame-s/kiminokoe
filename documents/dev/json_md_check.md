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
- [ ] `scenarios/days/day_1010/exploration.json`
- [ ] `scenarios/days/day_1010/evening_branch.json`
- [ ] `scenarios/days/day_1010/evening_common.json`
- [ ] `scenarios/days/day_1010/dinner.json`
- [ ] `scenarios/days/day_1011/main.json`

---

## branches（day_1010）

- [ ] `scenarios/branches/day_1010/day_1010_b_1.json`
- [ ] `scenarios/branches/day_1010/day_1010_b_2.json`
- [ ] `scenarios/branches/day_1010/day_1010_b_3.json`
- [ ] `scenarios/branches/day_1010/day_1010_b_4.json`
- [ ] `scenarios/branches/day_1010/day_1010_c_1.json`
- [ ] `scenarios/branches/day_1010/day_1010_c_2.json`
- [ ] `scenarios/branches/day_1010/day_1010_d_1.json`
- [ ] `scenarios/branches/day_1010/day_1010_d_2.json`
- [ ] `scenarios/branches/day_1010/day_1010_d_3.json`
- [ ] `scenarios/branches/day_1010/day_1010_e_1.json`
- [ ] `scenarios/branches/day_1010/day_1010_e_2.json`
- [ ] `scenarios/branches/day_1010/day_1010_e_3.json`

---

## episodes

- [ ] `scenarios/episodes/ep_00.json`
- [ ] `scenarios/episodes/ep_00_beta.json`
- [ ] `scenarios/episodes/ep_01.json`
- [ ] `scenarios/episodes/ep_02.json`
- [ ] `scenarios/episodes/ep_03.json`
- [ ] `scenarios/episodes/ep_04.json`
- [ ] `scenarios/episodes/ep_05.json`
- [ ] `scenarios/episodes/ep_06.json`
- [ ] `scenarios/episodes/ep_07.json`
- [ ] `scenarios/episodes/ep_08.json`
- [ ] `scenarios/episodes/ep_08_prime.json`

---

## shared

- [ ] `scenarios/shared/shared_day_1010_c.json`
- [ ] `scenarios/shared/shared_ep_3_after.json`
- [ ] `scenarios/shared/shared_ep_7_shrine.json`
- [ ] `scenarios/shared/shared_warabeuta.json`

---

## 備考欄

差分が見つかった場合はここに記載する。

| ファイル | 対応 | 内容 |
|----------|------|------|
| `main.json` | 修正済 | 3件修正（`必要なんてない`→`必要もない`、ロボット文構造、`とはいっても`→`もっとも`） |
| `main.json` | MD側で対応 | `地蔵焚西口` のルビ表記（MD側を修正予定） |
