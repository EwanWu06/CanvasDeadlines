# CanvasDeadlines — 项目工作守则

## 一句话简介
macOS 菜单栏小程序，拉取 UCLA Extension Canvas API 显示作业/测验倒计时。
**用户 Ewan 不写代码，所有改动由 Claude 完成。**

## 每次会话强制流程

1. **会话开始**：先读 `dev-log/` 中日期最新的一篇日志，了解上次进度与未决项。
2. **改动前**：若涉及偏离 `docs/` 中已定的规范，必须先告知用户并取得确认。
3. **会话结束**：在 `dev-log/` 追加或编辑当天日志，使用四节模板：
   - `## 今日已完成`
   - `## 决策记录（含理由）`
   - `## 遗留问题`
   - `## 明日待办`

## 文档索引

| 文档 | 路径 | 何时读 / 何时改 |
|---|---|---|
| 项目总览与当前状态 | `docs/00-overview.md` | 开始任何工作前先看 |
| 需求规范 | `docs/01-requirements.md` | 实现新功能前对照 |
| 技术栈与依赖 | `docs/02-tech-spec.md` | 引入新依赖前必须先更新 |
| 模块架构与数据流 | `docs/03-architecture.md` | 新增/移动模块前必须先更新 |
| Canvas API 接入 | `docs/04-api-spec.md` | 改 API 调用时必须同步更新 |
| UI 设计规范 | `docs/05-design-spec.md` | 改 UI 时必须同步更新 |
| 编码规范 | `docs/06-coding-standards.md` | 每次写代码都要遵守 |
| 分阶段执行计划 | `docs/07-execution-plan.md` | 每个阶段开始前对照 |
| E2E 验证清单 | `docs/08-testing-checklist.md` | 阶段验收 + 发布前必跑 |

## 红线（不可越过）

- ❌ 不擅自跳过任何阶段的验证检查点（`swift build` 通过 + dev-log 写完 + 用户确认）
- ❌ 不在 `dev-log/` 之外的位置记录"今天做了什么"
- ❌ 引入新依赖前不更新 `docs/02-tech-spec.md`
- ❌ 改 UI 不更新 `docs/05-design-spec.md`
- ❌ 改 API 调用不更新 `docs/04-api-spec.md`
- ❌ 每个阶段结束不暂停等用户确认

## 当前阶段
查看 `docs/00-overview.md` 的"当前状态"。

## 关键路径速查
- 源码根：`Sources/CanvasDeadlines/`
- 构建：`swift build` 或在 Xcode 中打开 `Package.swift`
- 发布打包：`./build.sh`（阶段 6 创建）
