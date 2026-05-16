import Foundation
import SwiftUI

enum ViewMode: String, CaseIterable, Identifiable {
    case all
    case byCourse

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return "全部"
        case .byCourse: return "按学科"
        }
    }
}

@MainActor
final class DeadlineStore: ObservableObject {
    @Published var items: [DeadlineItem] = []
    @Published var isLoading: Bool = false
    @Published var lastError: String? = nil
    @Published var viewMode: ViewMode = .all
    /// 是否已配置任意一种数据源（iCal 链接或 Token）
    @Published var isConfigured: Bool = false

    /// 显示数量上限
    let displayLimit: Int = 10

    private var cachedRaw: [DeadlineItem] = []

    init() {
        self.isConfigured = Self.detectConfigured()
    }

    private static func detectConfigured() -> Bool {
        !KeychainStore.loadFeeds().isEmpty
    }

    // MARK: - Public actions

    func refresh() async {
        let feeds = KeychainStore.loadFeeds()
        guard !feeds.isEmpty else {
            isConfigured = false
            items = []
            return
        }
        isConfigured = true
        isLoading = true
        lastError = nil

        let results: [(items: [DeadlineItem], error: String?)] =
            await withTaskGroup(of: (items: [DeadlineItem], error: String?).self) { group in
                for feed in feeds {
                    group.addTask {
                        guard let url = URL(string: feed.url) else {
                            return ([], "「\(feed.label)」链接无效")
                        }
                        do {
                            let raw = try await ICalService(feedURL: url).fetchDeadlines()
                            // 跨校 UID 可能撞号，用 feed.id 前缀保证全局唯一
                            let prefixed = raw.map { $0.prefixingID(feed.id.uuidString) }
                            return (prefixed, nil)
                        } catch {
                            return ([], "「\(feed.label)」：\(error.localizedDescription)")
                        }
                    }
                }
                var acc: [(items: [DeadlineItem], error: String?)] = []
                for await r in group { acc.append(r) }
                return acc
            }

        cachedRaw = results.flatMap { $0.items }
        let errors = results.compactMap { $0.error }
        lastError = errors.isEmpty ? nil : errors.joined(separator: "\n")
        applyFilters()
        isLoading = false
    }

    /// 临时诊断：把所有 iCal 源的原始解析结果写到桌面文件
    @Published var diagnosticsMessage: String? = nil

    func exportDiagnostics() async {
        let feeds = KeychainStore.loadFeeds()
        guard !feeds.isEmpty else {
            diagnosticsMessage = "未配置日历订阅，无法导出。"
            return
        }
        do {
            var report = ""
            for feed in feeds {
                report += "\n========== 源：\(feed.label) ==========\n"
                guard let url = URL(string: feed.url) else {
                    report += "（链接无效）\n"
                    continue
                }
                report += try await ICalService(feedURL: url).debugDump()
            }
            let desktop = FileManager.default
                .urls(for: .desktopDirectory, in: .userDomainMask).first
            let fileURL = (desktop ?? FileManager.default.temporaryDirectory)
                .appendingPathComponent("CanvasDeadlines-诊断.txt")
            try report.write(to: fileURL, atomically: true, encoding: .utf8)
            diagnosticsMessage = "已导出到桌面：CanvasDeadlines-诊断.txt"
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        } catch {
            diagnosticsMessage = "导出失败：\(error.localizedDescription)"
        }
    }

    func skip(_ item: DeadlineItem) {
        SkipStore.add(item.id)
        applyFilters()
    }

    func restore(_ id: String) {
        SkipStore.remove(id)
        applyFilters()
    }

    func markSubmittedLocally(_ item: DeadlineItem) {
        SubmittedStore.add(item.id)
        applyFilters()
    }

    func unmarkSubmitted(_ id: String) {
        SubmittedStore.remove(id)
        applyFilters()
    }

    func setFeedURL(_ url: String) throws {
        try KeychainStore.saveFeedURL(url)
        isConfigured = true
    }

    func clearCredentials() {
        try? KeychainStore.deleteFeedURL()
        isConfigured = false
        items = []
        cachedRaw = []
    }

    // MARK: - 多校订阅管理

    var feeds: [Feed] { KeychainStore.loadFeeds() }

    func addFeed(label: String, url: String) throws {
        var list = KeychainStore.loadFeeds()
        list.append(Feed(label: label, url: url))
        try KeychainStore.saveFeeds(list)
        isConfigured = true
    }

    func removeFeed(_ id: UUID) {
        var list = KeychainStore.loadFeeds()
        list.removeAll { $0.id == id }
        try? KeychainStore.saveFeeds(list)
        isConfigured = !list.isEmpty
    }

    func renameFeed(_ id: UUID, to label: String) {
        var list = KeychainStore.loadFeeds()
        guard let idx = list.firstIndex(where: { $0.id == id }) else { return }
        list[idx].label = label
        try? KeychainStore.saveFeeds(list)
    }

    // MARK: - Derived views

    /// 按课程分组的视图数据
    var groupedByCourse: [(courseCode: String, items: [DeadlineItem])] {
        let groups = Dictionary(grouping: items, by: { $0.courseCode })
        return groups
            .map { (key, value) in (courseCode: key, items: value.sorted(by: Self.dueOrder)) }
            .sorted { lhs, rhs in lhs.courseCode < rhs.courseCode }
    }

    /// 设置里「已跳过/已标记提交」列表：同样套用逆期 3 天窗口（太久远的不再统计），
    /// 排序为最上面最新（截止日期最晚）→ 下面最远（最早）。
    var skippedItems: [DeadlineItem] {
        let ids = SkipStore.all()
        return cachedRaw
            .filter { ids.contains($0.id) && withinGraceWindow($0) }
            .sorted(by: Self.dueDescending)
    }

    var submittedItems: [DeadlineItem] {
        let ids = SubmittedStore.all()
        return cachedRaw
            .filter { ids.contains($0.id) && withinGraceWindow($0) }
            .sorted(by: Self.dueDescending)
    }

    // MARK: - Filtering

    private var overdueCutoff: Date {
        Calendar.current.date(
            byAdding: .day,
            value: -AppSettings.overdueGraceDays,
            to: Calendar.current.startOfDay(for: Date())
        ) ?? Date()
    }

    private func withinGraceWindow(_ item: DeadlineItem) -> Bool {
        guard let due = item.dueAt else { return false }
        return due >= overdueCutoff
    }

    private func applyFilters() {
        let skipped = SkipStore.all()
        let submitted = SubmittedStore.all()
        let cutoff = overdueCutoff

        let filtered = cachedRaw.filter { item in
            guard let due = item.dueAt else { return false }
            // 砍掉过于久远的历史项（iCal 模式无提交状态，旧作业多半已交）
            if due < cutoff { return false }
            if item.isSubmitted { return false }
            if submitted.contains(item.id) { return false }
            if skipped.contains(item.id) { return false }
            return true
        }
        let sorted = filtered.sorted(by: Self.dueOrder)
        items = Array(sorted.prefix(displayLimit))
    }

    private static func dueOrder(_ a: DeadlineItem, _ b: DeadlineItem) -> Bool {
        // 都有 due_at 时按时间升序；其它情况已被过滤
        guard let da = a.dueAt, let db = b.dueAt else { return false }
        return da < db
    }

    private static func dueDescending(_ a: DeadlineItem, _ b: DeadlineItem) -> Bool {
        guard let da = a.dueAt, let db = b.dueAt else { return false }
        return da > db
    }
}
