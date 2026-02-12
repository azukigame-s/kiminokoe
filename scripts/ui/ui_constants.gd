class_name UIConstants

## 全画面共通のデザイントークン
## 色・フォントサイズ・レイアウト定数を一元管理する
##
## テーマカラー（const）を変更すれば、派生色（static var）が自動で追従する

# === Theme Colors（3色 + サブ2色） ===
# 和風・古き良き日本 — 生成り(#f5f5dc) × 赤銅(#a04030) × 墨色(#1c1c1c)

const COLOR_ACCENT = Color(0.627, 0.251, 0.188)           # 赤銅 #a04030
const COLOR_BASE_DARK = Color(0.11, 0.11, 0.11)          # 墨色 #1c1c1c
const COLOR_BASE_LIGHT = Color(0.961, 0.961, 0.863)      # 生成り #f5f5dc
const COLOR_SUB_ACCENT = Color(0.549, 0.478, 0.420)       # 丁子茶 #8c7a6b
const COLOR_SPIRIT = Color(0.784, 0.761, 0.714)          # 灰白 #c8c2b6

# === 以下すべてテーマカラーから派生 ===

# テキスト
static var COLOR_TEXT_PRIMARY: Color = Color(COLOR_BASE_LIGHT, 1.0)
static var COLOR_TEXT_SECONDARY: Color = Color(COLOR_SUB_ACCENT, 1.0)
static var COLOR_TEXT_ACCENT: Color = Color(COLOR_ACCENT, 1.0)
static var COLOR_TEXT_DISABLED: Color = Color(COLOR_BASE_DARK.lightened(0.33), 1.0)
static var COLOR_TEXT_TITLE_DARK: Color = Color(COLOR_BASE_DARK.lightened(0.13), 1.0)

# 背景（墨色 × アルファ）
static var COLOR_BG_OVERLAY: Color = Color(COLOR_BASE_DARK, 0.5)
static var COLOR_BG_PANEL: Color = Color(COLOR_BASE_DARK, 0.85)
static var COLOR_BG_DARK: Color = Color(COLOR_BASE_DARK, 0.9)
static var COLOR_BG_BUTTON: Color = Color(COLOR_BASE_DARK.lightened(0.08), 0.8)
static var COLOR_BG_BUTTON_HOVER: Color = Color(COLOR_BASE_DARK.lightened(0.12), 0.9)

# ボーダー
static var COLOR_BORDER_NORMAL: Color = Color(COLOR_SUB_ACCENT, 1.0)
static var COLOR_BORDER_HOVER: Color = Color(COLOR_ACCENT, 1.0)

# スキップ
static var COLOR_SKIP_ACTIVE: Color = Color(COLOR_ACCENT, 1.0)

# 装飾パーツ（朱色 × アルファ）
static var COLOR_ENTRY_BG: Color = Color(COLOR_BASE_DARK.lightened(0.05), 0.6)
static var COLOR_RULE: Color = Color(COLOR_ACCENT, 0.5)
static var COLOR_ENTRY_BORDER: Color = Color(COLOR_ACCENT, 0.4)
static var COLOR_SEPARATOR: Color = Color(COLOR_ACCENT, 0.15)
static var COLOR_BUTTON_HOVER_TINT: Color = Color(COLOR_ACCENT, 0.08)

# アウトライン（縁取り）
static var COLOR_OUTLINE: Color = Color(COLOR_BASE_DARK.darkened(1.0), 0.9)
const OUTLINE_SIZE = 2

# === Font Sizes ===
const FONT_SIZE_TITLE = 36
const FONT_SIZE_HEADING = 28
const FONT_SIZE_BODY = 24
const FONT_SIZE_BUTTON_LARGE = 32
const FONT_SIZE_BUTTON_NORMAL = 20
const FONT_SIZE_CAPTION = 16

# === Layout ===
const MARGIN_TEXT = 0.1
const CORNER_RADIUS = 8
const BORDER_WIDTH = 2
const BUTTON_MIN_SIZE_LARGE = Vector2(250, 50)
const BUTTON_MIN_SIZE_NORMAL = Vector2(120, 40)
