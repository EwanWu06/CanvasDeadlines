import Foundation

struct DeadlineItem: Identifiable, Hashable {
    let id: String
    let kind: ItemKind
    let title: String
    let courseId: Int
    let courseCode: String
    let dueAt: Date?
    let isSubmitted: Bool
    let htmlURL: URL?

    var isOverdue: Bool {
        guard let due = dueAt else { return false }
        return due < Date()
    }

    /// Whole days remaining (negative if overdue). nil if no due date.
    var daysRemaining: Int? {
        guard let due = dueAt else { return nil }
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfDue = calendar.startOfDay(for: due)
        return calendar.dateComponents([.day], from: startOfToday, to: startOfDue).day
    }

    var countdownText: String {
        guard let days = daysRemaining else { return "无截止" }
        if days < 0 { return "已逾期 \(-days) 天" }
        if days == 0 { return "今天截止" }
        if days == 1 { return "明天截止" }
        return "还剩 \(days) 天"
    }

    /// 多校合并时给 id 加来源前缀，避免不同 Canvas 实例的 UID 撞号。
    func prefixingID(_ prefix: String) -> DeadlineItem {
        DeadlineItem(
            id: "\(prefix)::\(id)",
            kind: kind,
            title: title,
            courseId: courseId,
            courseCode: courseCode,
            dueAt: dueAt,
            isSubmitted: isSubmitted,
            htmlURL: htmlURL
        )
    }
}
