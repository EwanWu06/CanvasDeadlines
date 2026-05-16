import SwiftUI

struct DeadlineListView: View {
    @ObservedObject var store: DeadlineStore
    @State private var showingSettings = false

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
                diagnosticsBar
                footer
            }
            .frame(width: 340)
            .frame(maxHeight: 520)
            .task { await store.refresh() }
        }
    }

    // MARK: - Sections

    private var header: some View {
        HStack(spacing: 8) {
            Picker("", selection: $store.viewMode) {
                ForEach(ViewMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            if store.isLoading {
                ProgressView().controlSize(.small)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var content: some View {
        if let err = store.lastError {
            errorView(message: err)
        } else if store.isLoading && store.items.isEmpty {
            loadingView
        } else if store.items.isEmpty {
            emptyView
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    switch store.viewMode {
                    case .all:
                        ForEach(store.items) { item in
                            DeadlineRow(
                                item: item,
                                onSubmit: { withAnimation { store.markSubmittedLocally(item) } },
                                onSkip: { withAnimation { store.skip(item) } }
                            )
                            Divider()
                        }
                    case .byCourse:
                        ForEach(store.groupedByCourse, id: \.courseCode) { group in
                            sectionHeader(group.courseCode)
                            ForEach(group.items) { item in
                                DeadlineRow(
                                    item: item,
                                    onSubmit: { withAnimation { store.markSubmittedLocally(item) } },
                                    onSkip: { withAnimation { store.skip(item) } }
                                )
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .background(Color.secondary.opacity(0.08))
    }

    private var loadingView: some View {
        VStack(spacing: 8) {
            ProgressView()
            Text("正在同步...").font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Text("🎉")
                .font(.system(size: 32))
            Text("暂无未提交项目")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 10) {
            Label("出错了", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .font(.headline)
            Text(message)
                .font(.caption)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
                .fixedSize(horizontal: false, vertical: true)
            Button("重试") {
                Task { await store.refresh() }
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
    }

    // 临时诊断条（排查 iCal 过滤规则用，问题解决后会移除）
    @ViewBuilder
    private var diagnosticsBar: some View {
        VStack(spacing: 4) {
            Button {
                Task { await store.exportDiagnostics() }
            } label: {
                Label("导出诊断信息到桌面", systemImage: "ladybug")
                    .font(.caption)
            }
            .buttonStyle(.borderless)

            if let msg = store.diagnosticsMessage {
                Text(msg)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity)
        .background(Color.yellow.opacity(0.12))
    }

    private var footer: some View {
        HStack {
            Button {
                Task { await store.refresh() }
            } label: {
                Label("刷新", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderless)

            Spacer()

            Button {
                showingSettings = true
            } label: {
                Label("设置", systemImage: "gearshape")
            }
            .buttonStyle(.borderless)

            Spacer()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("退出", systemImage: "power")
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}
