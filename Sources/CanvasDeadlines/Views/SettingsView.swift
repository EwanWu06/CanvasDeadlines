import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: DeadlineStore
    var onClose: () -> Void

    @State private var canvasURL: String = AppSettings.canvasURL
    @State private var graceDays: Int = AppSettings.overdueGraceDays
    @State private var launchAtLogin: Bool = LaunchAtLogin.isEnabled
    @State private var launchError: String? = nil
    @State private var feedList: [Feed] = []
    @State private var newFeedLabel: String = ""
    @State private var newFeedURL: String = ""
    @State private var feedResult: String? = nil
    @State private var testingFeed = false

    @State private var overrides: [String: String] = AppSettings.courseNameOverrides
    @State private var newReg: String = ""
    @State private var newName: String = ""

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    generalSection
                    Divider()
                    feedSection
                    Divider()
                    skippedSection
                    Divider()
                    submittedSection
                    Divider()
                    courseNameSection
                    Divider()
                    aboutSection
                }
                .padding(14)
            }
        }
        .frame(width: 380)
        .frame(maxHeight: 560)
        .onAppear { feedList = store.feeds }
    }

    private var header: some View {
        HStack {
            Button {
                persistAndClose()
            } label: {
                Label("返回", systemImage: "chevron.left")
            }
            .buttonStyle(.borderless)
            Spacer()
            Text("设置").font(.headline)
            Spacer()
            Color.clear.frame(width: 44, height: 1) // 居中占位
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - 通用

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("通用").font(.subheadline.weight(.semibold))

            Text("Canvas 网站地址（用于 Onboarding 的「打开 Canvas」按钮）")
                .font(.caption).foregroundStyle(.secondary)
            TextField("https://my.uclaextension.edu", text: $canvasURL)
                .textFieldStyle(.roundedBorder)
                .font(.caption)

            Stepper(value: $graceDays, in: 0...30) {
                Text("逆期项最多往前看 **\(graceDays)** 天")
                    .font(.caption)
            }
            Text("日历订阅看不到是否已交，太久远的历史项默认隐藏。0 = 不显示任何逆期项。")
                .font(.caption2).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider().padding(.vertical, 2)

            Toggle(isOn: $launchAtLogin) {
                Text("开机时自动启动").font(.caption)
            }
            .toggleStyle(.switch)
            .controlSize(.small)
            .onChange(of: launchAtLogin) { newValue in
                do {
                    try LaunchAtLogin.setEnabled(newValue)
                    launchError = nil
                } catch {
                    launchError = error.localizedDescription
                    launchAtLogin = LaunchAtLogin.isEnabled // 回退到真实状态
                }
            }
            Text("勾选后开机登录会自动启动。注意：需从打包好的 App 运行才生效，Xcode 调试运行无效。")
                .font(.caption2).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if let e = launchError {
                Text("设置失败：\(e)")
                    .font(.caption2).foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - 日历订阅（多校）

    private var feedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("日历订阅（\(feedList.count) 个学校）")
                .font(.subheadline.weight(.semibold))
            Text("每个学校的 Canvas 各加一条订阅，作业/考试会合并显示。")
                .font(.caption2).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(feedList) { feed in
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(feed.label).font(.caption.weight(.medium)).lineLimit(1)
                        Text(feed.url).font(.caption2).foregroundStyle(.secondary)
                            .lineLimit(1).truncationMode(.middle)
                    }
                    Spacer()
                    Button("删除") {
                        store.removeFeed(feed.id)
                        feedList = store.feeds
                        Task { await store.refresh() }
                    }
                    .font(.caption).buttonStyle(.borderless)
                }
            }

            Divider().padding(.vertical, 2)
            Text("添加学校：").font(.caption)
            TextField("学校名（如 SMC / WLAC / UCLA Extension）", text: $newFeedLabel)
                .textFieldStyle(.roundedBorder).font(.caption)
            TextField("该校 Canvas 的 .ics / webcal 链接", text: $newFeedURL)
                .textFieldStyle(.roundedBorder).font(.caption)
            HStack {
                if testingFeed { ProgressView().controlSize(.small) }
                Spacer()
                Button("测试并添加") {
                    Task { await addNewFeed() }
                }
                .disabled(testingFeed
                          || newFeedLabel.trimmingCharacters(in: .whitespaces).isEmpty
                          || newFeedURL.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            if let r = feedResult {
                Text(r).font(.caption2).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - 已跳过

    private var skippedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("已跳过的项（\(store.skippedItems.count)）")
                .font(.subheadline.weight(.semibold))
            if store.skippedItems.isEmpty {
                Text("暂无").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(store.skippedItems) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.title).font(.caption).lineLimit(1)
                            Text(item.courseCode).font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("恢复") {
                            withAnimation { store.restore(item.id) }
                        }
                        .font(.caption)
                        .buttonStyle(.borderless)
                    }
                }
            }
        }
    }

    // MARK: - 已标记提交

    private var submittedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("已标记提交的项（\(store.submittedItems.count)）")
                .font(.subheadline.weight(.semibold))
            Text("点错了「已交」可在这里恢复回列表。")
                .font(.caption2).foregroundStyle(.secondary)
            if store.submittedItems.isEmpty {
                Text("暂无").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(store.submittedItems) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.title).font(.caption).lineLimit(1)
                            Text(item.courseCode).font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("恢复") {
                            withAnimation { store.unmarkSubmitted(item.id) }
                        }
                        .font(.caption)
                        .buttonStyle(.borderless)
                    }
                }
            }
        }
    }

    // MARK: - 课程名覆盖

    private var courseNameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("课程名自定义").font(.subheadline.weight(.semibold))
            Text("某些课在日历里没有课程名，会显示「课程 注册号」。可在此手动指定。")
                .font(.caption2).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(overrides.sorted(by: { $0.key < $1.key }), id: \.key) { reg, name in
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(reg).font(.caption2).foregroundStyle(.secondary)
                        Text(name).font(.caption).lineLimit(1)
                    }
                    Spacer()
                    Button("删除") {
                        overrides.removeValue(forKey: reg)
                    }
                    .font(.caption)
                    .buttonStyle(.borderless)
                }
            }

            HStack(spacing: 6) {
                TextField("注册号", text: $newReg)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
                    .frame(width: 80)
                TextField("课程名", text: $newName)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
                Button("添加") {
                    let r = newReg.trimmingCharacters(in: .whitespaces)
                    let n = newName.trimmingCharacters(in: .whitespaces)
                    guard !r.isEmpty, !n.isEmpty else { return }
                    overrides[r] = n
                    newReg = ""; newName = ""
                }
                .font(.caption)
                .disabled(newReg.isEmpty || newName.isEmpty)
            }
        }
    }

    // MARK: - 关于

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("关于").font(.subheadline.weight(.semibold))
            Text("Canvas Deadlines v1.0").font(.caption)
            Text("数据源：Canvas 日历订阅（iCal），无需 Token")
                .font(.caption2).foregroundStyle(.secondary)

            Divider().padding(.vertical, 2)

            Text("排查工具").font(.caption.weight(.medium)).foregroundStyle(.secondary)
            Text("如果某个作业没出现或分类不对，可导出诊断文件发给开发者。")
                .font(.caption2).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                Task { await store.exportDiagnostics() }
            } label: {
                Label("导出诊断信息到桌面", systemImage: "ladybug")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            if let msg = store.diagnosticsMessage {
                Text(msg).font(.caption2).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Actions

    private func addNewFeed() async {
        testingFeed = true
        feedResult = nil
        defer { testingFeed = false }
        let label = newFeedLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        let urlStr = newFeedURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: urlStr) else {
            feedResult = "链接格式无效。"
            return
        }
        do {
            let items = try await ICalService(feedURL: url).fetchDeadlines()
            try store.addFeed(label: label, url: urlStr)
            feedList = store.feeds
            feedResult = "✅ 已添加「\(label)」，解析到 \(items.count) 项。"
            newFeedLabel = ""; newFeedURL = ""
            await store.refresh()
        } catch {
            feedResult = "❌ \(error.localizedDescription)"
        }
    }

    private func persistAndClose() {
        AppSettings.canvasURL = canvasURL.trimmingCharacters(in: .whitespaces)
        AppSettings.overdueGraceDays = graceDays
        AppSettings.courseNameOverrides = overrides
        onClose()
    }
}
