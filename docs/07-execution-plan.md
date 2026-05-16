# 07 · 分阶段执行计划

每个阶段结束时必须满足：
1. ✅ `swift build` 编译通过、无 warning
2. ✅ 当天 dev-log 已写完
3. ✅ 用户已确认，方可进入下一阶段

---

## 阶段 0 · 标准基线（约 30 min）

**产出**：`docs/` 全套规范 + `dev-log/` 首篇 + 项目根 `CLAUDE.md`

**检查点**：
- `ls docs/` 列出 9 份 .md
- `ls dev-log/` 至少一份
- `CLAUDE.md` 可读

---

## 阶段 1 · API 客户端 + CLI 验证（约 1h）

**产出**：
- 完善 `Sources/CanvasDeadlines/Services/CanvasAPI.swift`（加 `ping`、收尾错误处理）
- 临时 `main.swift`（或在 `CanvasDeadlinesApp` 中分流）：检测 `CANVAS_CLI=1` 进 CLI

**CLI 命令**：
```bash
CANVAS_CLI=1 CANVAS_URL=https://my.uclaextension.edu CANVAS_TOKEN=xxx swift run -- --ping
CANVAS_CLI=1 CANVAS_URL=https://my.uclaextension.edu CANVAS_TOKEN=xxx swift run -- --list-courses
```

**检查点**：
- `swift build` 通过
- 用户提供 Token → CLI 跑通，能看到课程名

---

## 阶段 2 · 存储层（约 30 min）

**产出**：
- `Services/KeychainStore.swift`：save / load / delete
- `Services/SkipStore.swift`：add / remove / all
- CLI 子命令：`--test-keychain`

**检查点**：
- `swift build` 通过
- CLI 写入 → 读出值一致
- `security find-generic-password -s "CanvasDeadlines"` 能查到

---

## 阶段 3 · ViewModel（约 30 min）

**产出**：
- `ViewModels/DeadlineStore.swift`
- CLI 子命令：`--dump-list`（输出过滤排序后的前 10 项）

**检查点**：
- `swift build` 通过
- CLI dump 出的列表符合需求 F2

---

## 阶段 4 · 基础 UI（约 1.5h）

**产出**：
- `CanvasDeadlinesApp.swift` 完整（`@main` + `MenuBarExtra`）
- `MenuBarRootView.swift`：分流 Onboarding / List
- `OnboardingView.swift`：4 步引导
- `DeadlineListView.swift`：只读列表
- `DeadlineRow.swift`：单行

**检查点**：
- `swift build` 通过
- 在 Xcode 中按 ▶️ → 菜单栏出现图标 → 点开看到数据
- 🎯 **此阶段完成时通知用户首次可在 Xcode 中跑起来**

---

## 阶段 5 · 完整交互（约 1.5h）

**产出**：
- DeadlineRow 加 hover 按钮（提交 / 跳过）
- DeadlineListView 顶部 Segmented `[全部] [按学科]`
- `SettingsView.swift`：URL / Token / 已跳过 / 关于
- 错误态 / 空态 UI

**检查点**：
- `swift build` 通过
- 跑通 `docs/08-testing-checklist.md` 中 1-9 项

---

## 阶段 6 · 打包分发（约 30 min）

**产出**：
- `build.sh`：`swift build -c release` → 构造 `.app` → 输出 `dist/CanvasDeadlines.app`
- `README.md`：用户使用手册

**检查点**：
- `./build.sh` 跑完
- 双击 `dist/CanvasDeadlines.app` → 工作流端到端通

---

## 总进度跟踪

| 阶段 | 状态 | 完成日期 |
|---|---|---|
| 0 | ⏳ | - |
| 1 | ⏳ | - |
| 2 | ⏳ | - |
| 3 | ⏳ | - |
| 4 | ⏳ | - |
| 5 | ⏳ | - |
| 6 | ⏳ | - |
