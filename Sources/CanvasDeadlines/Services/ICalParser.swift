import Foundation

struct ICalEvent {
    var uid: String?
    var summary: String?
    var description: String?
    var url: String?
    var start: Date?
}

/// 极简 iCalendar (RFC 5545) 解析器，只取我们需要的字段。
/// 不依赖任何第三方库。处理：行折叠、属性参数、常见 DTSTART 三种形态、文本转义。
enum ICalParser {

    static func parse(_ raw: String) -> [ICalEvent] {
        let lines = unfold(raw)
        var events: [ICalEvent] = []
        var current: ICalEvent?

        for line in lines {
            if line == "BEGIN:VEVENT" {
                current = ICalEvent()
                continue
            }
            if line == "END:VEVENT" {
                if let ev = current { events.append(ev) }
                current = nil
                continue
            }
            guard current != nil else { continue }

            let (name, params, value) = splitProperty(line)
            switch name.uppercased() {
            case "UID":
                current?.uid = unescapeText(value)
            case "SUMMARY":
                current?.summary = unescapeText(value)
            case "DESCRIPTION":
                current?.description = unescapeText(value)
            case "URL":
                current?.url = value
            case "DTSTART":
                current?.start = parseDate(value: value, params: params)
            default:
                break
            }
        }
        return events
    }

    // MARK: - Line unfolding

    /// RFC 5545：超过 75 字节的行会被折叠，续行以空格或制表符开头。
    private static func unfold(_ raw: String) -> [String] {
        let normalized = raw
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        var result: [String] = []
        for line in normalized.split(separator: "\n", omittingEmptySubsequences: false) {
            if let first = line.first, first == " " || first == "\t" {
                let continuation = String(line.dropFirst())
                if !result.isEmpty {
                    result[result.count - 1] += continuation
                }
            } else {
                result.append(String(line))
            }
        }
        return result
    }

    // MARK: - Property splitting

    /// 形如 `DTSTART;TZID=America/Los_Angeles:20260520T235900`
    /// 返回 (name, params 字典, value)
    private static func splitProperty(_ line: String) -> (String, [String: String], String) {
        guard let colonIdx = line.firstIndex(of: ":") else {
            return (line, [:], "")
        }
        let head = String(line[line.startIndex..<colonIdx])
        let value = String(line[line.index(after: colonIdx)...])

        let segments = head.split(separator: ";").map(String.init)
        let name = segments.first ?? head
        var params: [String: String] = [:]
        for seg in segments.dropFirst() {
            let kv = seg.split(separator: "=", maxSplits: 1).map(String.init)
            if kv.count == 2 { params[kv[0].uppercased()] = kv[1] }
        }
        return (name, params, value)
    }

    // MARK: - Date parsing

    private static func parseDate(value: String, params: [String: String]) -> Date? {
        // 形态 1：纯日期 VALUE=DATE  → 20260520
        if params["VALUE"]?.uppercased() == "DATE" || value.count == 8 {
            let f = DateFormatter()
            f.calendar = Calendar(identifier: .gregorian)
            f.dateFormat = "yyyyMMdd"
            f.timeZone = TimeZone.current
            if let day = f.date(from: value) {
                // 全天事件视为当天 23:59 本地时间截止
                return Calendar.current.date(bySettingHour: 23, minute: 59, second: 0, of: day)
            }
            return nil
        }

        // 形态 2：UTC，结尾带 Z  → 20260520T235900Z
        if value.hasSuffix("Z") {
            let f = DateFormatter()
            f.calendar = Calendar(identifier: .gregorian)
            f.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
            f.timeZone = TimeZone(identifier: "UTC")
            return f.date(from: value)
        }

        // 形态 3：带 TZID  → 20260520T235900
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = "yyyyMMdd'T'HHmmss"
        if let tzid = params["TZID"], let tz = TimeZone(identifier: tzid) {
            f.timeZone = tz
        } else {
            f.timeZone = TimeZone.current
        }
        return f.date(from: value)
    }

    // MARK: - Text unescaping

    private static func unescapeText(_ s: String) -> String {
        s.replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\N", with: "\n")
            .replacingOccurrences(of: "\\,", with: ",")
            .replacingOccurrences(of: "\\;", with: ";")
            .replacingOccurrences(of: "\\\\", with: "\\")
    }
}
