# 05 · UI 设计规范

## 整体原则
- **简洁**：信息密度高但留白足，不堆砌装饰
- **原生**：尽量用 SF Symbols + 系统色板，跟随暗黑模式
- **倒计时即焦点**：每行最显眼的部分是剩余天数

## 主面板尺寸
- 宽度：**340pt**
- 高度：自适应，最大 520pt（超出滚动）
- 最小高度：120pt（空状态）

## 色板（语义色，自动适配深浅色）

| 用途 | SwiftUI 颜色 |
|---|---|
| 主背景 | 跟随 MenuBarExtra 默认 |
| 主文本 | `.primary` |
| 次要文本（课程代码） | `.secondary` |
| 强调 - 紧迫（≤1 天） | `.orange` |
| 强调 - 过期 | `.red` |
| 强调 - 正常 | `.primary` |
| 错误背景 | `.red.opacity(0.1)` |
| 分隔线 | `Divider()` 系统默认 |

## 字体

| 用途 | Font |
|---|---|
| 行标题 | `.body` semibold |
| 课程代码 | `.caption` regular `.secondary` |
| 倒计时数字 | `.body` monospacedDigit semibold |
| Section header | `.caption` uppercase `.secondary` |
| 设置标题 | `.headline` |

## 单行布局（DeadlineRow）

```
┌────────────────────────────────────────────┐
│ [icon]  Title goes here          剩余 3 天 │
│         COURSE 101                          │
└────────────────────────────────────────────┘
```

- 行高：约 50pt（含 padding）
- 左 padding：12pt
- 右 padding：12pt
- 上下 padding：8pt
- 图标尺寸：18pt
- 图标到标题间距：10pt
- Hover 时：背景 `.gray.opacity(0.15)` + 右侧滑出两个按钮

### Hover 状态
```
┌────────────────────────────────────────────┐
│ [icon]  Title       [✓ 提交] [⊘ 跳过]  3天 │
│         COURSE 101                          │
└────────────────────────────────────────────┘
```

### 过期状态
- 整行背景：`.red.opacity(0.08)`
- 文本：`.red`
- 倒计时：`"已逾期 N 天"` bold

## 顶部工具栏

```
┌────────────────────────────────────────────┐
│  [ 全部 | 按学科 ]            🔄 刷新中... │
└────────────────────────────────────────────┘
```

- 高度：36pt
- Segmented Control 用 `Picker` + `.pickerStyle(.segmented)`
- 右侧刷新区：加载时显示 ProgressView + "刷新中..."

## 底部工具栏

```
┌────────────────────────────────────────────┐
│      🔄 刷新    ⚙️ 设置    ⏻ 退出           │
└────────────────────────────────────────────┘
```

- 高度：36pt
- 三个按钮平均分布，`.borderless` 风格

## Onboarding（首次启动）

```
┌────────────────────────────────────────────┐
│           欢迎使用 Canvas Deadlines        │
│                                            │
│   1. 登录 Canvas                           │
│      https://my.uclaextension.edu         │
│      [打开 Canvas 网站 ↗]                  │
│                                            │
│   2. 头像 → Settings                       │
│   3. 滚到 Approved Integrations            │
│   4. + New Access Token                    │
│   5. 复制生成的 Token                       │
│                                            │
│   ┌──────────────────────────────────┐    │
│   │ 粘贴 Token...                    │    │
│   └──────────────────────────────────┘    │
│              [测试并保存]                  │
└────────────────────────────────────────────┘
```

## 空状态

| 场景 | 文案 |
|---|---|
| 无 Token | （走 Onboarding，不展示空态） |
| 拉取中 | ProgressView + "正在同步..." |
| 无未提交项 | "🎉 暂无未提交项目" `.secondary` |
| 全部已跳过 | "所有项目已跳过，可在设置中恢复" |

## 错误状态

```
┌────────────────────────────────────────────┐
│  ⚠️ Token 失效或已过期                     │
│                                            │
│         [打开设置]    [重试]                │
└────────────────────────────────────────────┘
```

## 设置面板

- 用 `Form` 容器
- 段落：
  1. **服务器** — URL 输入
  2. **认证** — Token SecureField + 测试连接按钮
  3. **已跳过项** — 列表，每项右侧「恢复」按钮
  4. **关于** — 版本号

## 图标

- 作业 → 📝（或 SF Symbol `doc.text`）
- 测验 → 📋（或 SF Symbol `checklist`）
- 刷新 → SF Symbol `arrow.clockwise`
- 设置 → SF Symbol `gearshape`
- 退出 → SF Symbol `power`

> 本期先用 emoji，方便快速实现；阶段 5 可改用 SF Symbols 提升原生感。

## 动效
- 行进入/离开：`.transition(.opacity.combined(with: .move(edge: .top)))`
- 状态切换：`.animation(.easeInOut(duration: 0.2))`
- Hover 按钮显隐：opacity 渐变
