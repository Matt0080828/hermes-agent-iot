#!/bin/bash
# ============================================================
# fix-browser-import.sh
# 修復 Pi2 上 "No module named 'plugins.browser'" 錯誤
# 在 hermes-agent-iot 目錄下執行：bash fix-browser-import.sh
# ============================================================

set -e

BROWSER_TOOL="tools/browser_tool.py"

if [ ! -f "$BROWSER_TOOL" ]; then
  echo "錯誤：找不到 $BROWSER_TOOL，請在 repo 根目錄執行此腳本"
  exit 1
fi

echo "==> 備份原始檔案"
cp "$BROWSER_TOOL" "${BROWSER_TOOL}.bak"

echo "==> 替換 plugins.browser 的硬式 import 為 try/except"

python3 - <<'PYEOF'
import re

with open("tools/browser_tool.py", "r", encoding="utf-8") as f:
    content = f.read()

# 替換三個 plugins.browser import 為 try/except 版本
old = '''from plugins.browser.browserbase.provider import (
    BrowserbaseBrowserProvider as BrowserbaseProvider,
)
from plugins.browser.browser_use.provider import (
    BrowserUseBrowserProvider as BrowserUseProvider,
)
from plugins.browser.firecrawl.provider import (
    FirecrawlBrowserProvider as FirecrawlProvider,
)'''

new = '''try:
    from plugins.browser.browserbase.provider import (
        BrowserbaseBrowserProvider as BrowserbaseProvider,
    )
except ImportError:
    BrowserbaseProvider = None  # not available on this platform

try:
    from plugins.browser.browser_use.provider import (
        BrowserUseBrowserProvider as BrowserUseProvider,
    )
except ImportError:
    BrowserUseProvider = None  # not available on this platform

try:
    from plugins.browser.firecrawl.provider import (
        FirecrawlBrowserProvider as FirecrawlProvider,
    )
except ImportError:
    FirecrawlProvider = None  # not available on this platform'''

if old in content:
    content = content.replace(old, new)
    with open("tools/browser_tool.py", "w", encoding="utf-8") as f:
        f.write(content)
    print("==> 修改成功")
else:
    print("警告：找不到預期的 import 區塊，可能版本不同")
    print("請手動將下列內容加上 try/except:")
    print("  from plugins.browser.browserbase.provider import ...")
    print("  from plugins.browser.browser_use.provider import ...")
    print("  from plugins.browser.firecrawl.provider import ...")
PYEOF

echo ""
echo "==> 完成！重新啟動 agent 即可"
echo "    如需復原：cp ${BROWSER_TOOL}.bak $BROWSER_TOOL"
