class_name UIConstants

## 全画面共通のデザイントークン
## 色・フォントサイズ・レイアウト定数を一元管理する

# === Color Palette ===

# テキスト
const COLOR_TEXT_PRIMARY = Color(1.0, 1.0, 1.0, 1.0)       # 白
const COLOR_TEXT_SECONDARY = Color(0.7, 0.7, 0.7, 1.0)     # グレー
const COLOR_TEXT_DISABLED = Color(0.4, 0.4, 0.4, 1.0)      # 無効
const COLOR_TEXT_ACCENT = Color(1.0, 0.8, 0.0, 1.0)        # ゴールド（ホバー）
const COLOR_TEXT_TITLE_DARK = Color(0.224, 0.196, 0.2, 1.0) # タイトル用ダーク

# 背景
const COLOR_BG_OVERLAY = Color(0, 0, 0, 0.5)               # 半透明黒（ゲーム画面テキストパネル）
const COLOR_BG_PANEL = Color(0, 0, 0, 0.8)                 # パネル背景
const COLOR_BG_DARK = Color(0.1, 0.1, 0.1, 0.9)            # 設定/メニュー背景
const COLOR_BG_BUTTON = Color(0.2, 0.2, 0.2, 0.8)          # ボタン通常
const COLOR_BG_BUTTON_HOVER = Color(0.3, 0.3, 0.3, 0.9)    # ボタンホバー

# ボーダー
const COLOR_BORDER_NORMAL = Color(0.5, 0.5, 0.5)           # 通常ボーダー
const COLOR_BORDER_HOVER = Color(1.0, 0.8, 0.0, 1.0)       # ホバーボーダー（ゴールド）

# スキップインジケータ
const COLOR_SKIP_INDICATOR = Color.RED

# === Font Sizes ===
const FONT_SIZE_TITLE = 36
const FONT_SIZE_HEADING = 28
const FONT_SIZE_BODY = 24
const FONT_SIZE_BUTTON_LARGE = 32
const FONT_SIZE_BUTTON_NORMAL = 20
const FONT_SIZE_CAPTION = 16
const FONT_SIZE_SKIP_INDICATOR = 28

# === Layout ===
const MARGIN_TEXT = 0.1       # テキスト表示エリアのマージン（アンカー比率）
const CORNER_RADIUS = 8
const BORDER_WIDTH = 2
const BUTTON_MIN_SIZE_LARGE = Vector2(250, 50)
const BUTTON_MIN_SIZE_NORMAL = Vector2(120, 40)
