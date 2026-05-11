#!/usr/bin/env bash
# Velvet · App Store 截图自动归档（macOS / iOS Simulator）
# 用法：bash scripts/take-appstore-shots.sh 6.7 zhHans
# 第一参数：尺寸标签（6.7 / 6.5 / 5.5 / ipad）
# 第二参数：语言（zhHans / enUS）
#
# 前置：在 macOS Simulator 启动对应尺寸的设备并启动 Velvet App。
# 输出：./appstore-screenshots/${SIZE}_${LANG}/${SIZE}_${LANG}_NN_page.png

set -euo pipefail

SIZE="${1:-6.7}"
LANG="${2:-zhHans}"
OUT_DIR="$(pwd)/appstore-screenshots/${SIZE}_${LANG}"
mkdir -p "$OUT_DIR"

DEVICE="$(xcrun simctl list devices booted | grep -oE '\([A-F0-9-]+\)' | head -1 | tr -d '()')"

if [[ -z "${DEVICE:-}" ]]; then
  echo "[!] 未检测到 booted simulator。请先 open -a Simulator 并 boot 对应尺寸的设备。" >&2
  exit 1
fi

echo "[+] Device: $DEVICE → $OUT_DIR"

# 把状态栏调成 9:41 + 满信号 + 满电（Apple 截图惯例）
xcrun simctl status_bar "$DEVICE" override \
  --time "9:41" \
  --dataNetwork wifi \
  --wifiMode active \
  --wifiBars 3 \
  --cellularMode active \
  --cellularBars 4 \
  --batteryState charged \
  --batteryLevel 100 || true

PAGES=(
  "01_feed:Feed 首页 · 同城 tab"
  "02_moment_detail:Moment 详情页"
  "03_wishlist:想要清单 · 个人主页"
  "04_chat:私聊详情页"
  "05_publish:发布页（先审后发提示）"
  "06_settings:设置 / 客服入口（可选）"
)

i=1
for entry in "${PAGES[@]}"; do
  NAME="${entry%%:*}"
  DESC="${entry##*:}"
  echo
  echo "─────────────────────────────────────────"
  echo "  截图 ${i}/${#PAGES[@]} · ${DESC}"
  echo "  → 把 App 切到这一页，然后按 Enter 拍摄..."
  read -r _

  FILE="${OUT_DIR}/${SIZE}_${LANG}_${NAME}.png"
  xcrun simctl io "$DEVICE" screenshot "$FILE"
  echo "  ✓ 保存：$FILE"
  i=$((i+1))
done

xcrun simctl status_bar "$DEVICE" clear || true

echo
echo "✓ 全部完成。归档：$OUT_DIR"
ls -la "$OUT_DIR"
