# -*- coding: utf-8 -*-
"""
Apply page breaks to scenarios/osekkai/main.json from documents/dev/scenarios/osekkai.md.

Rule: for each `> ⎘` in the MD, the dialogue line before it gets go_next: true,
and the dialogue line after it gets new_page: true.

Matching: walk JSON in array order; when consecutive dialogue texts (skipping
non-dialogue entries) match (prev, next) from MD, apply flags. Pair multiset
from MD supports rare duplicate transitions in JSON.
"""
from __future__ import annotations

import json
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MD_PATH = ROOT / "documents/dev/scenarios/osekkai.md"
JSON_PATH = ROOT / "scenarios/osekkai/main.json"


def normalize_md_line(s: str) -> str:
    s = s.strip()
    if s.startswith("\u3000"):
        s = s[1:]
    return s


def is_md_dialogue_line(line: str) -> bool:
    s = line.strip()
    if not s:
        return False
    if s.startswith("#"):
        return False
    if s.startswith("<!--"):
        return False
    if s.startswith("---"):
        return False
    if s.startswith("####"):
        return False
    if s.startswith(">"):
        return False
    return True


def extract_pagebreak_pairs() -> Counter[tuple[str, str]]:
    lines = MD_PATH.read_text(encoding="utf-8").splitlines()
    pairs: list[tuple[str, str]] = []
    for i, line in enumerate(lines):
        if line.strip() != "> ⎘":
            continue
        j = i - 1
        prev = None
        while j >= 0:
            if is_md_dialogue_line(lines[j]):
                prev = normalize_md_line(lines[j])
                break
            j -= 1
        k = i + 1
        nxt = None
        while k < len(lines):
            if is_md_dialogue_line(lines[k]):
                nxt = normalize_md_line(lines[k])
                break
            k += 1
        if prev is not None and nxt is not None:
            pairs.append((prev, nxt))
    return Counter(pairs)


def main() -> None:
    pair_counts = extract_pagebreak_pairs()
    total_pairs = sum(pair_counts.values())

    data = json.loads(JSON_PATH.read_text(encoding="utf-8"))

    for item in data:
        if item.get("type") != "dialogue":
            continue
        item.pop("go_next", None)
        item.pop("new_page", None)

    prev_obj: dict | None = None
    matched = 0
    for item in data:
        if item.get("type") != "dialogue":
            continue
        if prev_obj is not None:
            key = (prev_obj["text"], item["text"])
            if pair_counts.get(key, 0) > 0:
                prev_obj["go_next"] = True
                item["new_page"] = True
                pair_counts[key] -= 1
                matched += 1
        prev_obj = item

    # MD uses repeated「スグ。」lines and extra > ⎘ between them; JSON uses `sugu_horror`.
    # Map the whole block to: go_next on the last dialogue before the effect, new_page on
    # the first dialogue after it (equivalent to last MD break before「ひっ！」).
    for i, item in enumerate(data):
        if item.get("type") != "sugu_horror":
            continue
        j = i - 1
        while j >= 0 and data[j].get("type") != "dialogue":
            j -= 1
        k = i + 1
        while k < len(data) and data[k].get("type") != "dialogue":
            k += 1
        if j >= 0 and k < len(data):
            data[j]["go_next"] = True
            data[k]["new_page"] = True

    leftover = +pair_counts
    leftover = {k: v for k, v in leftover.items() if v > 0}

    # Pairs covered by sugu_horror (no consecutive dialogue in JSON).
    def horror_skipped_pair(k: tuple[str, str]) -> bool:
        a, b = k
        if a == "本を顔に近づけて、よく見ると――。" and b == "スグ。":
            return True
        if a == "スグ。" and b.startswith("スグスグ"):
            return True
        if a.startswith("スグスグ") and b == "「ひっ！」":
            return True
        return False

    leftover = {k: v for k, v in leftover.items() if not horror_skipped_pair(k)}

    JSON_PATH.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    print(f"MD page breaks: {total_pairs}")
    print(f"Applied in JSON: {matched}")
    if leftover:
        print(f"WARNING: {len(leftover)} MD pair(s) not found in JSON order:")
        for (a, b), n in sorted(leftover.items(), key=lambda x: -x[1])[:20]:
            print(f"  x{n}: ...{a[-20:]!r} -> {b[:30]!r}...")
        if len(leftover) > 20:
            print("  ...")


if __name__ == "__main__":
    main()
