class_name UIConstants

## 全画面共通のデザイントークン
## 色・フォントサイズ・レイアウト定数を一元管理する

# === Theme Colors ===
# 提案A: 感動・郷愁重視 — 白(#ffffff) × 深紅(#b92a4f) × 深い青紫(#1a1a2e)

# テーマカラー
const COLOR_ACCENT = Color(0.725, 0.165, 0.31)           # 深紅 #b92a4f
const COLOR_ACCENT_LIGHT = Color(0.851, 0.29, 0.435)     # 薄紅 #d94a6f（ホバー用）
const COLOR_ACCENT_DARK = Color(0.541, 0.122, 0.231)     # 暗紅 #8a1f3b（pressed用）
const COLOR_BASE_DARK = Color(0.102, 0.102, 0.18)        # 深い青紫 #1a1a2e

# サブアクセント（提案A固有）
const COLOR_SUB_ACCENT = Color(0.553, 0.643, 0.722)      # 薄青灰 #8da4b8（郷愁、10月の空）
const COLOR_SPIRIT = Color(0.784, 0.835, 0.878)          # 淡青白 #c8d5e0（霊体）

# === Color Palette ===

# テキスト
const COLOR_TEXT_PRIMARY = Color(1.0, 1.0, 1.0, 1.0)       # 白
const COLOR_TEXT_SECONDARY = Color(0.553, 0.643, 0.722, 1.0) # 薄青灰
const COLOR_TEXT_DISABLED = Color(0.4, 0.4, 0.4, 1.0)      # 無効
const COLOR_TEXT_ACCENT = Color(0.851, 0.29, 0.435, 1.0)   # 薄紅（ホバー）
const COLOR_TEXT_TITLE_DARK = Color(0.224, 0.196, 0.2, 1.0) # タイトル用ダーク

# 背景（深い青紫ベース）
const COLOR_BG_OVERLAY = Color(0.102, 0.102, 0.18, 0.5)    # 半透明青紫（ゲーム画面テキストパネル）
const COLOR_BG_PANEL = Color(0.102, 0.102, 0.18, 0.85)     # パネル背景
const COLOR_BG_DARK = Color(0.102, 0.102, 0.18, 0.9)       # 設定/メニュー背景
const COLOR_BG_BUTTON = Color(0.165, 0.165, 0.306, 0.8)    # ボタン通常（やや明るい青紫）
const COLOR_BG_BUTTON_HOVER = Color(0.2, 0.2, 0.35, 0.9)   # ボタンホバー

# ボーダー
const COLOR_BORDER_NORMAL = Color(0.553, 0.643, 0.722)     # 薄青灰
const COLOR_BORDER_HOVER = Color(0.725, 0.165, 0.31, 1.0)  # ホバーボーダー（深紅）

# スキップ
const COLOR_SKIP_ACTIVE = Color(0.725, 0.165, 0.31, 1.0)   # スキップ中（深紅）

# 和風UIパーツ（足跡・メニュー共通）
const COLOR_ENTRY_BG = Color(0.13, 0.13, 0.22, 0.6)        # エントリ背景（深い青紫系、微透過）
const COLOR_RULE = Color(0.725, 0.165, 0.31, 0.5)          # 装飾線（深紅）
const COLOR_ENTRY_BORDER = Color(0.725, 0.165, 0.31, 0.4)  # 左ボーダー（深紅、控えめ）
const COLOR_SEPARATOR = Color(0.725, 0.165, 0.31, 0.15)    # 区切り線（深紅、極薄）
const COLOR_BUTTON_HOVER_TINT = Color(0.725, 0.165, 0.31, 0.08) # ボタンホバー背景（深紅、極薄）

# アウトライン（縁取り）
const COLOR_OUTLINE = Color(0, 0, 0, 0.9)                  # 黒縁取り
const OUTLINE_SIZE = 2                                      # 縁取りの太さ（px）

# === Font Sizes ===
const FONT_SIZE_TITLE = 36
const FONT_SIZE_HEADING = 28
const FONT_SIZE_BODY = 24
const FONT_SIZE_BUTTON_LARGE = 32
const FONT_SIZE_BUTTON_NORMAL = 20
const FONT_SIZE_CAPTION = 16

# === Layout ===
const MARGIN_TEXT = 0.1       # テキスト表示エリアのマージン（アンカー比率）
const CORNER_RADIUS = 8
const BORDER_WIDTH = 2
const BUTTON_MIN_SIZE_LARGE = Vector2(250, 50)
const BUTTON_MIN_SIZE_NORMAL = Vector2(120, 40)