import SwiftUI

struct DeadlineListView: View {
    @ObservedObject var store: DeadlineStore
    @State private var showingSettings = false
    @State private var expandedCourses: Set<String> = []

    var body: some View {
        if showingSettings {
            SettingsView(store: store, onClose: {
                showingSettings = false
                Task { await store.refresh() }
            })
        } else {
            VStack(spacing: 0) {
                header
                Divider()
                content
                Divider()
                footer
            }
            .frame(width: 340)
            .frame(maxHeight: 520)
            .task { await store.refresh() }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("截止提醒")
                .font(.system(size: 13, weight: .semibold))

            Spacer()

            if store.isLoading {
                ProgressView().controlSize(.small)
            }

            Picker("", selection: $store.viewMode) {
                ForEach(ViewMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 130)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if let err = store.lastError, store.items.isEmpty {
            errorView(message: err)
        } else if store.isLoading && store.items.isEmpty {
            loadingView
        } else if store.items.isEmpty {
            emptyView
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    switch store.viewMode {
                    case .all:
                        ForEach(Array(store.items.enumerated()), id: \.element.id) { idx, item in
                            row(item)
                            if idx < store.items.count - 1 {
                                Divider().padding(.leading, 16)
                            }
                        }
                    case .byCourse:
                        ForEach(store.groupedByCourse, id: \.courseCode) { group in
                            courseGroup(group.courseCode, items: group.items)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func row(_ item: DeadlineItem) -> some View {
        DeadlineRow(
            item: item,
            onSubmit: { withAnimation { store.markSubmittedLocally(item) } },
            onSkip: { withAnimation { store.skip(item) } }
        )
    }

    @ViewBuilder
    private func courseGroup(_ courseCode: String, items: [DeadlineItem]) -> some View {
        let isExpanded = expandedCourses.contains(courseCode)
        let nearest = items.first?.daysRemaining

        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                if isExpanded { expandedCourses.remove(courseCode) }
                else { expandedCourses.insert(courseCode) }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))

                Text(courseCode)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 6)

                // 收起时用小圆点提示该课最紧迫项的紧迫度
                if !isExpanded, let d = nearest {
                    Circle()
                        .fill(urgencyColor(forDays: d))
                        .frame(width: 6, height: 6)
                }
                Text("\(items.count)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(Color.secondary.opacity(0.15)))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .background(.bar)
        }
        .buttonStyle(.plain)

        if isExpanded {
            ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                row(item)
                if idx < items.count - 1 {
                    Divider().padding(.leading, 16)
                }
            }
            Divider()
        }
    }

    private func urgencyColor(forDays d: Int) -> Color {
        if d < 0 { return .red }
        if d <= 1 { return .orange }
        if d <= 3 { return .yellow }
        return .green
    }

    // MARK: - States

    private var loadingView: some View {
        VStack(spacing: 10) {
            ProgressView()
            Text("正在同步…").font(.system(size: 12)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 140)
    }

    private var emptyView: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 34))
                .foregroundStyle(.green.gradient)
            Text("全部清空")
                .font(.system(size: 14, weight: .semibold))
            Text("近期没有待交的作业或考试")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 140)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 28))
                .foregroundStyle(.orange.gradient)
            Text("加载失败")
                .font(.system(size: 14, weight: .semibold))
            Text(message)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                Task { await store.refresh() }
            } label: {
                Text("重试").frame(maxWidth: 80)
            }
            .controlSize(.small)
        }
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 0) {
            footerButton("刷新", "arrow.clockwise") {
                Task { await store.refresh() }
            }
            footerButton("设置", "gearshape") {
                showingSettings = true
            }
            footerButton("退出", "power") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
    }

    private func footerButton(_ title: String, _ symbol: String,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: symbol).font(.system(size: 13))
                Text(title).font(.system(size: 10))
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
    }
}
