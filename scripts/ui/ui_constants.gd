class_name UIConstants

## 全画面共通のデザイントークン
## 色・フォントサイズ・レイアウト定数を一元管理する

# === Theme Colors ===
# Webサイトと統一: 白(#ffffff) × 深紅(#b92a4f) × 漆黒緑(#0a1a10)

# テーマカラー
const COLOR_ACCENT = Color(0.725, 0.165, 0.31)           # 深紅 #b92a4f
const COLOR_ACCENT_LIGHT = Color(0.851, 0.29, 0.435)     # 薄紅 #d94a6f（ホバー用）
const COLOR_ACCENT_DARK = Color(0.541, 0.122, 0.231)     # 暗紅 #8a1f3b（pressed用）
const COLOR_BASE_DARK = Color(0.039, 0.102, 0.063)       # 漆黒緑 #0a1a10

# === Color Palette ===

# テキスト
const COLOR_TEXT_PRIMARY = Color(1.0, 1.0, 1.0, 1.0)       # 白
const COLOR_TEXT_SECONDARY = Color(0.7, 0.7, 0.7, 1.0)     # グレー
const COLOR_TEXT_DISABLED = Color(0.4, 0.4, 0.4, 1.0)      # 無効
const COLOR_TEXT_ACCENT = Color(0.851, 0.29, 0.435, 1.0)   # 薄紅（ホバー）
const COLOR_TEXT_TITLE_DARK = Color(0.224, 0.196, 0.2, 1.0) # タイトル用ダーク

# 背景（漆黒緑ベース）
const COLOR_BG_OVERLAY = Color(0.039, 0.102, 0.063, 0.5)   # 半透明漆黒緑（ゲーム画面テキストパネル）
const COLOR_BG_PANEL = Color(0.039, 0.102, 0.063, 0.8)     # パネル背景
const COLOR_BG_DARK = Color(0.06, 0.12, 0.08, 0.9)         # 設定/メニュー背景
const COLOR_BG_BUTTON = Color(0.08, 0.15, 0.10, 0.8)       # ボタン通常
const COLOR_BG_BUTTON_HOVER = Color(0.12, 0.20, 0.15, 0.9) # ボタンホバー

# ボーダー
const COLOR_BORDER_NORMAL = Color(0.5, 0.5, 0.5)           # 通常ボーダー
const COLOR_BORDER_HOVER = Color(0.725, 0.165, 0.31, 1.0)  # ホバーボーダー（深紅）

# スキップ
const COLOR_SKIP_ACTIVE = Color(0.725, 0.165, 0.31, 1.0)   # スキップ中（深紅）

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
