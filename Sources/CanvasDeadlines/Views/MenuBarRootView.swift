import SwiftUI

struct MenuBarRootView: View {
    @ObservedObject var store: DeadlineStore

    var body: some View {
        Group {
            if store.isConfigured {
                DeadlineListView(store: store)
            } else {
                OnboardingView(store: store)
            }
        }
    }
}
