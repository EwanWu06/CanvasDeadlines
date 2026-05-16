# 06 · 编码规范

## 命名

| 类型 | 风格 | 例 |
|---|---|---|
| 类型（class/struct/enum） | UpperCamelCase | `DeadlineItem` |
| 协议 | UpperCamelCase | `Storable` |
| 方法 / 变量 | lowerCamelCase | `fetchAllDeadlines` |
| 常量 | lowerCamelCase | `defaultBaseURL` |
| 文件 | 与主类型同名 | `DeadlineItem.swift` |
| API DTO | `Canvas` 前缀 | `CanvasAssignment` |
| Error 类型 | `xxxError` | `CanvasAPIError` |

## 目录约定

```
Sources/CanvasDeadlines/
├── CanvasDeadlinesApp.swift     ← @main 入口
├── Models/                      ← 纯数据，无业务逻辑
├── Services/                    ← 与外部世界通信（网络、磁盘、Keychain）
├── ViewModels/                  ← @MainActor，UI 状态来源
└── Views/                       ← SwiftUI，不持有业务状态
```

- **不允许** Views 直接调用 Services
- **不允许** Services 引用 SwiftUI
- **不允许** Models 引用任何上层

## 注释

- **默认不写注释**。命名要好到不需要注释解释 *是什么*
- 只在以下情况写注释，且写"**为什么**"而不是"是什么"：
  - 算法非显然
  - 绕过 SDK bug / 系统约束
  - 接口契约（如 "调用方必须在主线程"）
- 不写 PR 描述、不写 TODO 提及具体人名
- Doc comments（`///`）仅用于公开 API

**反例**：
```swift
// 设置 i 等于 0  ← ❌ 废话
var i = 0
```

**正例**：
```swift
// Canvas 的 upcoming bucket 不含过期项，需要单独再拉一次 overdue 才完整
let overdue = try? await fetchOverdue()
```

## 并发

- ViewModel 加 `@MainActor`
- 网络层方法用 `async throws`
- 并发拉取用 `withThrowingTaskGroup`
- **禁止** `DispatchQueue.main.async { ... }`（用 `@MainActor` 代替）
- **禁止** completion handler 风格新代码

## 错误处理

- 自定义 Error 实现 `LocalizedError`，提供中文 `errorDescription`
- View 层只展示 `error.localizedDescription`，不自己解析错误结构
- Service 层捕获底层异常 → 包装成自己的 Error 类型再抛

## 安全

- Token：**只能** 经 `KeychainStore` 读写
- 不在日志/打印中泄漏 Token
- 不写死 Token 到代码或测试

## 测试模式

- 通过环境变量 `CANVAS_CLI=1` 启用 CLI 模式
- CLI 模式参数：`--ping` / `--list-courses` / `--dump-list` / `--test-keychain`
- 加新子命令需更新 `docs/02-tech-spec.md` 中"CLI 测试模式"小节

## Git（如果将来引入）
- commit 信息中文，祈使句
- 一个阶段对应一个 commit，标题格式：`阶段 N · <概要>`

---

## dev-log 模板

每天一份 `dev-log/YYYY-MM-DD.md`，结构固定：

```markdown
# YYYY-MM-DD

## 今日已完成
- 阶段 X：xxx
- 文件：A.swift / B.md

## 决策记录（含理由）
- 决策：xxx
  - 理由：xxx
  - 影响：xxx

## 遗留问题
- [ ] xxx（计划在阶段 Y 解决）

## 明日待办
- 阶段 X+1：xxx
- 需用户配合：xxx（如果有）
```
