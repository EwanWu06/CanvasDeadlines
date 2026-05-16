# 03 · 模块架构与数据流

## 分层

```
┌─────────────────────────────────────────────┐
│             Views (SwiftUI)                  │  ← 表现层
│  MenuBarRootView / DeadlineListView /        │
│  DeadlineRow / SettingsView / OnboardingView │
└──────────────────┬──────────────────────────┘
                   │ @StateObject / @ObservedObject
                   ▼
┌─────────────────────────────────────────────┐
│         ViewModel (@MainActor)               │  ← 状态层
│           DeadlineStore                       │
│  @Published items / isLoading / lastError    │
│  refresh / skip / restore / markSubmitted    │
└─────────┬──────────────────┬────────────────┘
          │                  │
          ▼                  ▼
┌──────────────────┐  ┌──────────────────────┐
│   CanvasAPI      │  │  Storage             │  ← 服务层
│   (URLSession)   │  │  KeychainStore       │
│                  │  │  SkipStore           │
└──────────────────┘  └──────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────┐
│             Models                           │  ← 数据层
│  Course / DeadlineItem / ItemKind            │
│  CanvasDTOs (Decodable)                      │
└─────────────────────────────────────────────┘
```

## 文件职责

### Models/
- **Course.swift**：课程模型（id、name、course_code）
- **ItemKind.swift**：枚举 `assignment` / `quiz`
- **DeadlineItem.swift**：UI 统一展示的数据结构（含倒计时计算）
- **CanvasDTOs.swift**：从 Canvas API 反序列化的原始结构（不直接暴露给 View）

### Services/
- **ICalParser.swift**：自实现 RFC 5545 解析器，零依赖
- **ICalService.swift**：拉取 + 解析 .ics 订阅，映射为 [DeadlineItem]（唯一数据源）
- **KeychainStore.swift**：凭据读写。多校订阅以 JSON 数组存 account=`canvas-ical-feeds-json`；自动迁移旧单条 `canvas-ical-feed-url`
- **Models/Feed.swift**：`Feed{id,label,url}`，一个学校一条订阅
- **SkipStore.swift**：含 `SkipStore`(跳过) / `SubmittedStore`(已提交，持久化) / `AppSettings`(URL+逆期天数+课程名覆盖)
- **CLIRunner.swift**：`CANVAS_CLI=1` 测试模式（`--dump-ical` / `--test-keychain` / `--test-skipstore`）

> Token/REST 相关文件（`CanvasAPI.swift`/`CanvasDTOs.swift`/`Course.swift`）已于 2026-05-16 删除。

### ViewModels/
- **DeadlineStore.swift**：唯一状态源。组合 CanvasAPI + SkipStore，输出已过滤排序的 `[DeadlineItem]`

### Views/
- **CanvasDeadlinesApp.swift**：`@main` 入口，决定走 CLI 还是 GUI；GUI 用 `MenuBarExtra`
- **MenuBarRootView.swift**：菜单展开后的根视图，根据是否有 Token 切换 Onboarding / List
- **OnboardingView.swift**：首次配置 Token 引导
- **DeadlineListView.swift**：主列表，含视图切换按钮、底部工具栏
- **DeadlineRow.swift**：单行 UI
- **SettingsView.swift**：设置面板（Token、URL、已跳过列表）

## 数据流（典型场景：用户点开菜单）

```
1. MenuBarExtra 展开
   ↓
2. MenuBarRootView .task { await store.refresh() }
   ↓
3. DeadlineStore.refresh()
   ├─ KeychainStore.load() → token
   ├─ CanvasAPI.fetchAllDeadlines() → [DeadlineItem]（原始）
   ├─ SkipStore.all() → Set<String>
   └─ 过滤 (isSubmitted == false && id ∉ skipped) → 排序 → 取前 10
       ↓
4. @Published items 更新 → View 重新渲染
```

## 错误处理

- API 错误 → `CanvasAPIError` → DeadlineStore.lastError → View 显示
- Keychain 错误 → 视为"未配置 Token" → 跳 Onboarding
- 网络失败 → 显示"请检查网络" + 保留上次成功的数据

## 并发约定

- 所有 `@Published` 属性更新走主线程（`@MainActor`）
- 网络请求在后台线程并发（TaskGroup）
- UI 不直接构造 `URLSession`，必须经 `CanvasAPI`

## 测试边界

- **CanvasAPI**：可独立通过 CLI 模式验证
- **KeychainStore / SkipStore**：可独立通过 CLI 模式验证
- **DeadlineStore**：可通过 CLI dump 验证过滤排序
- **Views**：手动 UI 测试（无自动化测试，本期）
