#!/bin/bash
# publish.sh - 本地手动发布当天日报到 GitHub Pages
# 用法: bash publish.sh [YYYY-MM-DD]
#   不传日期则默认今天

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
DATE="${1:-$(date +%Y-%m-%d)}"
REPORT_FILE="$REPO_DIR/reports/${DATE}.html"
DESKTOP_FILE="$HOME/Desktop/steven-ai-daily-${DATE}.html"

cd "$REPO_DIR"

# 如果 reports 目录下没有当天日报，尝试从桌面复制
if [ ! -f "$REPORT_FILE" ]; then
  if [ -f "$DESKTOP_FILE" ]; then
    mkdir -p reports
    cp "$DESKTOP_FILE" "$REPORT_FILE"
    echo "Copied report from Desktop"
  else
    echo "Error: No report found for ${DATE}"
    echo "  Looked at: $REPORT_FILE"
    echo "  Looked at: $DESKTOP_FILE"
    exit 1
  fi
fi

# 更新 reports.json
node -e "
  const fs = require('fs');
  const data = JSON.parse(fs.readFileSync('reports.json', 'utf8'));
  const date = '${DATE}';
  if (!data.find(r => r.date === date)) {
    data.push({date, file: 'reports/${DATE}.html'});
    data.sort((a, b) => a.date.localeCompare(b.date));
  }
  fs.writeFileSync('reports.json', JSON.stringify(data, null, 2) + '\n');
"

# Git commit & push
git add reports/ reports.json
git diff --staged --quiet || {
  git commit -m "Add daily AI report for ${DATE}"
  git push
}

echo ""
echo "Published! View at: https://stevenhchang.github.io/steven-ai-daily/reports/${DATE}.html"
