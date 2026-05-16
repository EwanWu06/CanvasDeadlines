import Foundation

enum ItemKind: String, Codable, Hashable {
    case assignment
    case quiz

    var icon: String {
        switch self {
        case .assignment: return "📝"
        case .quiz: return "📋"
        }
    }

    /// SF Symbol 名（UI 用，比 emoji 更原生）
    var symbol: String {
        switch self {
        case .assignment: return "doc.text.fill"
        case .quiz: return "checklist"
        }
    }

    var label: String {
        switch self {
        case .assignment: return "作业"
        case .quiz: return "测验"
        }
    }
}
