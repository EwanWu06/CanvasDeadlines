#!/bin/bash
# 一键把项目打包成可双击运行的 Canvas Deadlines.app
# 用法：在「终端」里执行   ./build.sh
set -euo pipefail
cd "$(dirname "$0")"

BIN_NAME="CanvasDeadlines"
DIST="dist"
APP="$DIST/CanvasDeadlines.app"

echo "==> 1/4 编译 release（首次稍慢，请耐心等）..."
swift build -c release

echo "==> 2/4 构造 .app 包结构..."
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

BIN_PATH="$(swift build -c release --show-bin-path)/$BIN_NAME"
cp "$BIN_PATH" "$APP/Contents/MacOS/$BIN_NAME"
cp "Resources/Info.plist" "$APP/Contents/Info.plist"
chmod +x "$APP/Contents/MacOS/$BIN_NAME"

echo "==> 3/4 代码签名（ad-hoc，本机运行用）..."
codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || \
  echo "   （签名跳过，不影响本机运行）"

echo "==> 4/4 完成"
echo ""
echo "✅ 已生成：$(pwd)/$APP"
echo ""
echo "下一步："
echo "  • 双击 dist/CanvasDeadlines.app 即可运行（图标出现在屏幕顶部菜单栏）"
echo "  • 想常驻使用：把它拖到「应用程序」文件夹，再拖到 Dock 或设为登录启动"
echo "  • 首次打开若提示「无法验证开发者」：右键点它 → 打开 → 再点打开"
