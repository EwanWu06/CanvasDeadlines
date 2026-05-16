# 02 · 技术栈与依赖

## 核心栈

| 层 | 选型 |
|---|---|
| 语言 | Swift 5.9+ |
| UI | SwiftUI（`MenuBarExtra`） |
| 并发 | async/await + TaskGroup |
| 网络 | URLSession（系统自带，零依赖） |
| 持久化 - Token | Keychain（`Security` framework，系统自带） |
| 持久化 - 设置 | UserDefaults |
| 构建系统 | Swift Package Manager（SwiftPM） |
| 目标系统 | macOS 13+（Ventura，因 `MenuBarExtra` 起步版本） |

## 外部依赖

**当前：零**。所有功能均用系统库实现，包括 iCalendar (RFC 5545) 解析器（`ICalParser.swift` 自实现，未引入 ICS 第三方库）。引入新依赖前必须先在本文档登记并经用户同意。

## 工具链

| 工具 | 用途 | 用户是否需装 |
|---|---|---|
| Xcode（完整）| 开发 + 运行 | ✅ 用户已装 |
| Xcode Command Line Tools | 命令行 `swift build` | 装 Xcode 后已包含 |
| `security` CLI | 调试 Keychain | 系统自带 |

## 构建与运行

### 开发期（推荐）
1. 在 Xcode 中打开 `Package.swift`（直接双击或 File → Open → 选 `Package.swift`）
2. 顶部 Scheme 选 `CanvasDeadlines` → 点 ▶️
3. 菜单栏出现图标

### 命令行
```bash
swift build              # 编译
swift run                # 运行
swift run -c release     # release 模式运行
```

### 发布打包（阶段 6 实现）
```bash
./build.sh               # 产出 dist/CanvasDeadlines.app
```

## CLI 测试模式（开发期）

App 支持通过环境变量进入命令行测试模式：

```bash
CANVAS_CLI=1 CANVAS_ICAL='<ics链接>' swift run -- --dump-ical   # 解析诊断
CANVAS_CLI=1 swift run -- --test-keychain                       # Keychain 自检
CANVAS_CLI=1 swift run -- --test-skipstore                      # 跳过列表自检
```

GUI 模式（不带 `CANVAS_CLI`）走 SwiftUI App 入口。

## 文件类型约定

| 类型 | 后缀 | 位置 |
|---|---|---|
| 源代码 | `.swift` | `Sources/CanvasDeadlines/<层名>/` |
| 资源 | 任意 | `Resources/` |
| 规范文档 | `.md` | `docs/` |
| 日志 | `.md` | `dev-log/` |
| 脚本 | `.sh` | 项目根 |

## 系统要求（用户侧）
- macOS 13.0 或更高
- 已生成的 Canvas Personal Access Token
- ~10 MB 磁盘空间（含 App）
