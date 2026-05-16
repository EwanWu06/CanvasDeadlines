# 01 · 需求规范

## 用户故事

> 作为一个 UCLA Extension 在读学生，我希望在 Mac 菜单栏有一个常驻的小图标，
> 点开就能立刻看到所有课程里"最近要交的作业和考试"，
> 按时间由近到远列出来，
> 不用每次手动登录 Canvas 网站翻多个课程页面，
> 这样我就不会再忘记或漏交。

## 功能需求

### F1 · 数据拉取（多校 iCal，详见 04-api-spec.md）
- F1.1 解析 Canvas 个人日历订阅（.ics），无需 Token
- F1.2 **多校**：可添加多个学校的 Canvas 订阅（UCLA Extension / SMC / WLAC…），并发拉取后合并，统一过滤排序；每条带自定义学校名
- F1.3 跨校 UID 可能撞号，合并时用 feed UUID 前缀保证 id 全局唯一
- F1.4 F5.3「自动检测已提交」**不可用**，改为本地持久化的手动「标记提交」
- F1.5 起因：UCLA Extension 管理员禁止学生自助生成 Access Token
- F1.6 Token/REST 方案代码已于 2026-05-16 删除

### F2 · 显示规则
- F2.1 默认显示**最近 10 个未提交且未跳过**的项目
- F2.2 排序：按 `due_at` 升序（最近的最先）
- F2.3 过期项（`due_at < now` 且未提交）**仍然显示**，但**整行标红** + 文字显示「已逾期 N 天」
- F2.4 没有 `due_at` 的项目不显示
- F2.5 倒计时文案：
  - `daysRemaining > 1` → "还剩 N 天"
  - `daysRemaining == 1` → "明天截止"
  - `daysRemaining == 0` → "今天截止"
  - `daysRemaining < 0` → "已逾期 N 天"

### F3 · 视图切换
- F3.1 顶部 Segmented Control：`[全部] [按学科]`
- F3.2 "全部" = 单列扁平列表
- F3.3 "按学科" = 按课程代码分组，每组有 Section header

### F4 · 操作
- F4.1 每行 hover 出现两个按钮：「标记提交」「跳过」
- F4.2 「标记提交」= 立即从列表移除（本地标记，不调 Canvas API）
- F4.3 「跳过」= 加入跳过列表，从主列表隐藏
- F4.4 主面板底部：🔄 刷新 · ⚙️ 设置 · 退出
- F4.5 点击行主体（不点按钮）→ 浏览器打开该项的 Canvas 页面

### F5 · 同步
- F5.1 打开菜单时自动刷新一次
- F5.2 点 🔄 手动刷新
- F5.3 已检测到 submission 的项目自动从列表移除（无需手动）
- F5.4 加载时显示 ProgressView，错误时显示友好提示

### F6 · 设置
- F6.1 Canvas URL（默认填 `https://my.uclaextension.edu/`）
- F6.2 Access Token（SecureField + 「测试连接」按钮）
- F6.3 已跳过项列表（每项一个「恢复」按钮）
- F6.4 关于 / 版本号

### F7 · 首次启动
- F7.1 检测到 Keychain 中无 Token → 显示 Onboarding
- F7.2 Onboarding 分 4 步图文教用户：登录 Canvas → Settings → Approved Integrations → New Access Token → 粘贴回 App
- F7.3 提供"打开 Canvas 设置页"按钮（用浏览器直跳）

## 非功能需求

### N1 · 性能
- 课程数 ≤ 20 时，菜单展开到数据加载完成应在 **3 秒内**
- 用 `TaskGroup` 并发拉取课程数据

### N2 · 安全
- Token **必须存 Keychain**，不能存 UserDefaults / Plist / 明文文件
- 跳过列表可存 UserDefaults（非敏感）

### N3 · 隐私
- 不上传任何数据到第三方
- App 只与用户输入的 Canvas URL 通信

### N4 · 可观测性
- 网络错误显示 HTTP 状态码 + 友好文案（401→"Token 失效"、403→"权限不足"、5xx→"服务器问题"）
- 加载状态、空状态、错误状态三种 UI 都要有

### N5 · 平台
- 支持 macOS 13+（MenuBarExtra 要求）
- 暗黑模式自动跟随系统

## 验收标准
见 `08-testing-checklist.md`。
