import Foundation

enum ICalError: LocalizedError {
    case invalidURL
    case http(status: Int)
    case empty
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "日历订阅链接无效。请重新从 Canvas 复制 Calendar Feed 地址。"
        case .http(let status): return "拉取日历失败（HTTP \(status)）。链接可能已失效，请到 Canvas 重新复制。"
        case .empty: return "日历内容为空，没有解析到任何作业/测验。"
        case .transport(let e): return "网络错误：\(e.localizedDescription)"
        }
    }
}

final class ICalService {
    private let feedURL: URL
    private let session: URLSession

    init(feedURL: URL, session: URLSession = .shared) {
        // webcal:// 是 iCal 订阅协议，实际用 https 拉取
        if feedURL.scheme == "webcal" {
            var comps = URLComponents(url: feedURL, resolvingAgainstBaseURL: false)
            comps?.scheme = "https"
            self.feedURL = comps?.url ?? feedURL
        } else {
            self.feedURL = feedURL
        }
        self.session = session
    }

    func fetchDeadlines() async throws -> [DeadlineItem] {
        var request = URLRequest(url: feedURL)
        request.setValue("text/calendar", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw ICalError.transport(error)
        }

        if let http = response as? HTTPURLResponse,
           !(200..<300).contains(http.statusCode) {
            throw ICalError.http(status: http.statusCode)
        }

        guard let text = String(data: data, encoding: .utf8), !text.isEmpty else {
            throw ICalError.empty
        }

        let events = ICalParser.parse(text)
        let courseNames = Self.buildCourseNameMap(events)
            .merging(AppSettings.courseNameOverrides) { _, override in override }
        let items = events.compactMap { Self.mapToItem($0, courseNames: courseNames) }
        return items
    }

    /// 仅用于 CLI 调试：返回原始解析事件数量与样例
    func debugDump() async throws -> String {
        var request = URLRequest(url: feedURL)
        request.setValue("text/calendar", forHTTPHeaderField: "Accept")
        let (data, _) = try await session.data(for: request)
        guard let text = String(data: data, encoding: .utf8) else { return "(无法解码为文本)" }
        let events = ICalParser.parse(text)
        let courseNames = Self.buildCourseNameMap(events)
            .merging(AppSettings.courseNameOverrides) { _, override in override }

        let iso = ISO8601DateFormatter()
        var out = "=== Canvas Deadlines 诊断报告 ===\n"
        out += "原始字节数：\(data.count)\n"
        out += "解析到 VEVENT 总数：\(events.count)\n"
        out += "课程名映射：\(courseNames)\n\n"
        out += "提示：UID/URL 不含你的私密订阅标识，可安全分享给开发者。\n\n"
        out += "----- 全部事件（最多前 40 个）-----\n"

        for (i, ev) in events.prefix(40).enumerated() {
            let mapped = Self.mapToItem(ev, courseNames: courseNames)
            let verdict: String
            if let m = mapped {
                verdict = "✅ 保留为【\(m.kind.label)】"
            } else {
                verdict = "❌ 被过滤排除"
            }
            out += """
            [\(i + 1)] \(verdict)
              UID:     \(ev.uid ?? "nil")
              SUMMARY: \(ev.summary ?? "nil")
              URL:     \(ev.url ?? "nil")
              START:   \(ev.start.map { iso.string(from: $0) } ?? "nil")

            """
        }

        let kept = events.compactMap { Self.mapToItem($0, courseNames: courseNames) }
        out += "\n----- 过滤后保留 \(kept.count) 项 -----\n"
        for item in kept.prefix(30) {
            out += "  [\(item.kind.label)] \(item.title) — \(item.courseCode) — "
            out += (item.dueAt.map { iso.string(from: $0) } ?? "无截止") + "\n"
        }
        return out
    }

    // MARK: - Mapping

    /// Canvas iCal 把每门课的"课程横幅"也作为日历事件导出，SUMMARY 形如
    /// `407915: Introduction to Statistical Methods ... STATS XL 13 (Spring 2026) [407915]`。
    /// 利用末尾 `[注册号]` 把作业关联到课程名（作业 SUMMARY 也带同样的 `[注册号]` 后缀）。
    private static func buildCourseNameMap(_ events: [ICalEvent]) -> [String: String] {
        var map: [String: String] = [:]
        for ev in events {
            guard let summary = ev.summary,
                  let uid = ev.uid?.lowercased(),
                  uid.contains("calendar-event") else { continue }
            // 横幅特征：以「数字:」开头
            guard summary.range(of: #"^\s*\d+:\s"#, options: .regularExpression) != nil,
                  let reg = regNumber(from: summary) else { continue }
            let name = cleanCourseName(summary)
            guard !name.isEmpty else { continue }
            // 同一注册号可能有多个学期横幅，取最长（信息最全）的
            if let existing = map[reg], existing.count >= name.count { continue }
            map[reg] = name
        }
        return map
    }

    /// 取 SUMMARY 末尾 `[123456]` 里的注册号
    private static func regNumber(from summary: String) -> String? {
        guard let range = summary.range(of: #"\[(\d+)\]\s*$"#, options: .regularExpression) else {
            return nil
        }
        return summary[range]
            .trimmingCharacters(in: CharacterSet(charactersIn: "[] \t"))
    }

    private static func cleanCourseName(_ summary: String) -> String {
        var s = summary
        s = s.replacingOccurrences(of: #"^\s*\d+:\s*"#, with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: #"\s*\[\d+\]\s*$"#, with: "", options: .regularExpression)
        s = s.replacingOccurrences(
            of: #"\s*\((?:Winter|Spring|Summer|Fall)\s+\d{4}\)\s*"#,
            with: "", options: .regularExpression
        )
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 去掉作业标题末尾的 ` [注册号]` 后缀，让标题干净
    private static func stripRegSuffix(_ title: String) -> String {
        title.replacingOccurrences(of: #"\s*\[\d+\]\s*$"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func mapToItem(_ ev: ICalEvent, courseNames: [String: String]) -> DeadlineItem? {
        guard let due = ev.start else { return nil }
        guard let rawSummary = ev.summary?.trimmingCharacters(in: .whitespacesAndNewlines),
              !rawSummary.isEmpty else { return nil }

        let title = stripRegSuffix(rawSummary)
        let haystack = "\(ev.uid ?? "") \(ev.url ?? "") \(ev.description ?? "")".lowercased()
        let lowerTitle = title.lowercased()

        // 标题黑名单：考勤性质的项目，不是要交的作业，用户明确要求排除
        let excludeTitleKeywords = ["lecture participation"]
        if excludeTitleKeywords.contains(where: { lowerTitle.contains($0) }) {
            return nil
        }

        // 严格白名单：只保留明确是 quiz / 作业 / 考试的项。
        // 其它（lecture、上课时间、office hour、纯日历事件）一律排除——
        // Canvas iCal 把整个学期日程都塞进来，不过滤会刷屏。
        let examKeywords = ["exam", "midterm", "final exam", "考试", "期中", "期末", "测验"]
        // 用户要求：除作业/quiz/exam 外，凡是明确"要交东西/有截止"的也保留
        let dueKeywords = ["due", "deadline", "截止", "submit", "submission", "提交", "turn in", "hand in"]
        let kind: ItemKind
        if haystack.contains("quiz") {
            kind = .quiz
        } else if haystack.contains("assignment") {
            // Canvas 中带评分的 quiz/exam 本质也是 assignment；标题含考试词归为测验类
            kind = examKeywords.contains(where: { lowerTitle.contains($0) }) ? .quiz : .assignment
        } else if examKeywords.contains(where: { lowerTitle.contains($0) }) {
            // 考试被老师录成普通日历事件
            kind = .quiz
        } else if dueKeywords.contains(where: { lowerTitle.contains($0) }) {
            // 标题里明确带 due/deadline/提交 的日历事件也保留
            kind = .assignment
        } else {
            // lecture / 上课时间 / office hour / 纯日历事件 —— 排除
            return nil
        }

        let courseInternalId = extractCourseId(from: haystack) ?? 0
        let reg = regNumber(from: rawSummary)
        let courseLabel: String
        if let reg = reg, let name = courseNames[reg] {
            courseLabel = name
        } else if let reg = reg {
            courseLabel = "课程 \(reg)"
        } else if courseInternalId > 0 {
            courseLabel = "课程 #\(courseInternalId)"
        } else {
            courseLabel = "未分类"
        }
        let stableId = ev.uid ?? "ical-\(title)-\(due.timeIntervalSince1970)"

        return DeadlineItem(
            id: stableId,
            kind: kind,
            title: title,
            courseId: courseInternalId,
            courseCode: courseLabel,
            dueAt: due,
            isSubmitted: false, // iCal feed 不含提交状态
            htmlURL: ev.url.flatMap(URL.init(string:))
        )
    }

    /// 从 `?include_contexts=course_58623&...` 取 Canvas 内部课程 id
    private static func extractCourseId(from text: String) -> Int? {
        guard let range = text.range(of: #"course_(\d+)"#, options: .regularExpression) else {
            return nil
        }
        let digits = String(text[range]).replacingOccurrences(of: "course_", with: "")
        return Int(digits)
    }
}
