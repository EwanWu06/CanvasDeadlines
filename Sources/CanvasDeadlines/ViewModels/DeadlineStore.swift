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
        (KeychainStore.loadFeedURL() ?? "").isEmpty == false
    }

    // MARK: - Public actions

    func refresh() async {
        guard let feed = KeychainStore.loadFeedURL(), !feed.isEmpty,
              let url = URL(string: feed) else {
            isConfigured = false
            items = []
            return
        }
        isConfigured = true
        isLoading = true
        lastError = nil
        let service = ICalService(feedURL: url)
        do {
            cachedRaw = try await service.fetchDeadlines()
            applyFilters()
        } catch {
            lastError = error.localizedDescription
        }
        isLoading = false
    }

    /// 临时诊断：把 iCal 原始解析结果写到桌面文件，便于排查过滤规则
    @Published var diagnosticsMessage: String? = nil

    func exportDiagnostics() async {
        guard let feed = KeychainStore.loadFeedURL(),
              let url = URL(string: feed) else {
            diagnosticsMessage = "未配置日历订阅，无法导出。"
            return
        }
        let service = ICalService(feedURL: url)
        do {
            let report = try await service.debugDump()
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

    // MARK: - Derived views

    /// 按课程分组的视图数据
    var groupedByCourse: [(courseCode: String, items: [DeadlineItem])] {
        let groups = Dictionary(grouping: items, by: { $0.courseCode })
        return groups
            .map { (key, value) in (courseCode: key, items: value.sorted(by: Self.dueOrder)) }
            .sorted { lhs, rhs in lhs.courseCode < rhs.courseCode }
    }

    var skippedItems: [DeadlineItem] {
        let skippedIds = SkipStore.all()
        return cachedRaw
            .filter { skippedIds.contains($0.id) }
            .sorted(by: Self.dueOrder)
    }

    // MARK: - Filtering

    private func applyFilters() {
        let skipped = SkipStore.all()
        let submitted = SubmittedStore.all()
        let cutoff = Calendar.current.date(
            byAdding: .day,
            value: -AppSettings.overdueGraceDays,
            to: Calendar.current.startOfDay(for: Date())
        ) ?? Date()

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
}
