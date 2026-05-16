import SwiftUI

struct CanvasDeadlinesApp: App {
    @StateObject private var store = DeadlineStore()

    var body: some Scene {
        MenuBarExtra {
            MenuBarRootView(store: store)
        } label: {
            Image(systemName: "calendar")
        }
        .menuBarExtraStyle(.window)
    }
}
