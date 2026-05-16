import SwiftUI

struct DeadlineRow: View {
    let item: DeadlineItem
    var onSubmit: () -> Void
    var onSkip: () -> Void

    @State private var hovering = false

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Text(item.kind.icon)
                .font(.system(size: 18))
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(item.courseCode)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            if hovering {
                Button(action: onSubmit) {
                    Label("已交", systemImage: "checkmark.circle")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderless)
                .help("标记为已提交（从列表移除，永久记住）")

                Button(action: onSkip) {
                    Label("跳过", systemImage: "xmark.circle")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderless)
                .help("跳过此项（可在设置中恢复）")
            } else {
                Text(item.countdownText)
                    .font(.body.monospacedDigit().weight(.semibold))
                    .foregroundStyle(countdownColor)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(rowBackground)
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .onTapGesture {
            if let url = item.htmlURL { NSWorkspace.shared.open(url) }
        }
    }

    private var countdownColor: Color {
        if item.isOverdue { return .red }
        if let days = item.daysRemaining, days <= 1 { return .orange }
        return .primary
    }

    private var rowBackground: Color {
        if hovering { return Color.gray.opacity(0.15) }
        return item.isOverdue ? Color.red.opacity(0.08) : Color.clear
    }
}
