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

    var label: String {
        switch self {
        case .assignment: return "作业"
        case .quiz: return "测验"
        }
    }
}
