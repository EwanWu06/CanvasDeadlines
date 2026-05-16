import SwiftUI

struct DeadlineRow: View {
    let item: DeadlineItem
    var onSubmit: () -> Void
    var onSkip: () -> Void

    @State private var hovering = false

    var body: some View {
        HStack(spacing: 0) {
            // 左侧竖向紧迫度彩条
            Rectangle()
                .fill(urgencyColor)
                .frame(width: 4)

            HStack(spacing: 11) {
                Image(systemName: item.kind.symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(urgencyColor)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text(item.courseCode)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                if hovering {
                    HStack(spacing: 6) {
                        actionButton("checkmark.circle.fill", .green,
                                     help: "标记为已提交（永久记住，可在设置恢复）",
                                     action: onSubmit)
                        actionButton("xmark.circle.fill", .secondary,
                                     help: "跳过此项（可在设置恢复）",
                                     action: onSkip)
                    }
                    .transition(.opacity)
                } else {
                    Text(shortCountdown)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(urgencyColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(urgencyColor.opacity(0.15))
                        )
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
        }
        .background(hovering ? Color.primary.opacity(0.06) : Color.clear)
        .contentShape(Rectangle())
        .onHover { h in
            withAnimation(.easeOut(duration: 0.12)) { hovering = h }
        }
        .onTapGesture {
            if let url = item.htmlURL { NSWorkspace.shared.open(url) }
        }
    }

    private func actionButton(_ symbol: String, _ color: Color,
                              help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16))
                .foregroundStyle(color)
        }
        .buttonStyle(.plain)
        .help(help)
    }

    /// 胶囊里的精简倒计时文案
    private var shortCountdown: String {
        guard let d = item.daysRemaining else { return "无期限" }
        if d < 0 { return "逾期\(-d)天" }
        if d == 0 { return "今天" }
        if d == 1 { return "明天" }
        return "\(d) 天"
    }

    private var urgencyColor: Color {
        guard let d = item.daysRemaining else { return .gray }
        if d < 0 { return .red }
        if d <= 1 { return .orange }
        if d <= 3 { return .yellow }
        return .green
    }
}
