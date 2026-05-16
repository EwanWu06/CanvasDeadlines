# 04 · 数据源接入

## 数据源：iCal 日历订阅（多校）

支持多个学校的 Canvas 订阅（UCLA Extension / SMC / WLAC…）。每条 `Feed{id,label,url}` 存 Keychain（JSON 数组）。`DeadlineStore.refresh()` 用 `withTaskGroup` 并发拉取所有源，各自解析+映射后合并；跨校 UID 用 `feed.id` 前缀去重（`DeadlineItem.prefixingID`）。某源失败不影响其它源，错误合并提示。过滤/课程名规则对每个源一致（均为 Instructure Canvas，UID 结构相同；新校若无 `[注册号]` 横幅则课程名回退，可用手动覆盖）。

### 原（单源说明，逻辑同样适用于每个源）

UCLA Extension 管理员**禁止学生自助生成 Access Token**（报错：「Your Canvas administrators have chosen to limit your ability to generate your own access token」）。因此本项目**只用 iCal 日历订阅**这一种数据源。Token/REST 方案的代码已于 2026-05-16 整体删除（`CanvasAPI.swift`/`CanvasDTOs.swift`/`Course.swift`）。

功能与代价：倒计时、排序、按学科分组、手动跳过/标记提交均支持；**不支持自动检测已提交**（feed 无提交状态），靠本地持久化的手动「已交」标记。

### 获取方式
Canvas 网页 → 左侧 Calendar → 右下角「Calendar Feed」→ 复制 `webcal://` 或 `https://....ics` 链接。该链接含用户私密标识，**存入 Keychain**（account = `canvas-ical-feed-url`）。

### 拉取（`ICalService.swift`）
- `webcal://` 自动改写为 `https://` 后用 URLSession GET
- `Accept: text/calendar`
- 无需鉴权头（链接本身含私密标识）

### 解析（`ICalParser.swift`）
自实现的极简 RFC 5545 解析器，零依赖。处理：
- 行折叠（续行以空格/制表符开头）
- 属性参数（`DTSTART;TZID=America/Los_Angeles:...`）
- 三种 DTSTART：`VALUE=DATE`(全天→当天23:59本地) / 结尾`Z`(UTC) / 带`TZID`
- 文本转义（`\,` `\;` `\n` `\\`）

取用字段：`UID` `SUMMARY` `DESCRIPTION` `URL` `DTSTART`

### 映射规则（`ICalService.mapToItem`）
| 判定 | 结果 |
|---|---|
| `DTSTART` 缺失 | 丢弃 |
| 标题含 "lecture participation"（考勤）| 丢弃（用户要求）|
| UID/URL 含 "quiz" | `.quiz` |
| 含 "assignment" + 标题含 exam/midterm/考试 | `.quiz` |
| 含 "assignment" | `.assignment` |
| 标题含 exam/midterm/考试 等 | `.quiz`（考试录成日历事件的情况）|
| 标题含 due/deadline/截止/提交 等 | `.assignment` |
| 其它（lecture/上课时间/office hour/纯日历事件）| 丢弃 |
| 固定 | `isSubmitted = false` |

**课程名映射**：Canvas iCal 把"课程横幅"也作为日历事件导出（SUMMARY 形如 `407915: <课程名> ... [407915]`）。`buildCourseNameMap` 以末尾 `[注册号]` 为键提取课程名；作业 SUMMARY 同样带 `[注册号]` 后缀，据此关联。无横幅的课程回退显示「课程 <注册号>」。标题末尾 ` [注册号]` 由 `stripRegSuffix` 清除。课程内部 id 从 `course_(\d+)` 提取。

**课程名手动覆盖**：`AppSettings.courseNameOverrides`（内置默认 + UserDefaults 可改）覆盖自动抓取，用于 feed 里没有横幅的课程。当前内置：`407855 → Genetics, Evolution and Ecology LIFESCI XL 7B`。

### 过滤与排序（`DeadlineStore.applyFilters`）
- 砍掉 `dueAt < 今天 - overdueGraceDays`（默认 3 天）的历史项
- 排除已跳过（`SkipStore`）、已标记提交（`SubmittedStore`，持久化）
- 按 `dueAt` 升序，取前 `displayLimit`（默认 10）

### 时区与日期
- iCal `DTSTART` 三种形态见上；全天事件视为当天 23:59 本地
- 倒计时：本地时区"今天 00:00"与到期"当天 00:00"差值（`DeadlineItem.daysRemaining`）

### CLI 调试
```bash
CANVAS_CLI=1 CANVAS_ICAL='<ics链接>' swift run -- --dump-ical
```
打印解析到的 VEVENT 样例（每个标注✅保留/❌排除）+ 映射后的 DeadlineItem 列表。
