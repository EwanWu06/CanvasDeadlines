import SwiftUI

struct CanvasDeadlinesApp: App {
    @StateObject private var store = DeadlineStore()

    var body: some Scene {
        MenuBarExtra {
            MenuBarRootView(store: store)
        } label: {
            MenuBarLabel(store: store)
        }
        .menuBarExtraStyle(.window)
    }
}

private struct MenuBarLabel: View {
    @ObservedObject var store: DeadlineStore

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "calendar")
            if let nearest = store.items.first,
               let days = nearest.daysRemaining {
                Text(badgeText(days: days))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
        }
    }

    private func badgeText(days: Int) -> String {
        if days < 0 { return "逾期" }
        if days == 0 { return "今" }
        return "\(days)天"
    }
}
