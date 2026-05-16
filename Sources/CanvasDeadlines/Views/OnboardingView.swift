import SwiftUI

struct OnboardingView: View {
    @ObservedObject var store: DeadlineStore

    @State private var feedInput: String = ""
    @State private var testing: Bool = false
    @State private var testResult: TestResult? = nil

    enum TestResult {
        case success(String)
        case failure(String)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("欢迎使用 Canvas Deadlines")
                .font(.headline)

            Text("用 Canvas 的日历订阅链接，无需 Token：")
                .font(.subheadline).foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                step(1, "登录 Canvas")
                Button {
                    if let url = URL(string: AppSettings.canvasURL) {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Label("打开 Canvas 网站", systemImage: "arrow.up.right.square").font(.caption)
                }
                .buttonStyle(.borderless)
                .padding(.leading, 22)

                step(2, "左侧菜单点 Calendar（日历）")
                step(3, "页面右下角点「Calendar Feed」")
                step(4, "复制弹出的那个 .ics 链接")
                step(5, "粘贴到下方输入框")
            }

            TextField("粘贴 webcal:// 或 https://....ics 链接", text: $feedInput)
                .textFieldStyle(.roundedBorder)
                .font(.caption)

            Text("提示：这个链接含你的私密标识，本 App 会安全存进系统钥匙串，不会外传。")
                .font(.caption2).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                if testing {
                    ProgressView().controlSize(.small)
                    Text("正在测试...").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button("测试并保存") {
                    Task { await testAndSave() }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(testing || feedInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if let result = testResult {
                resultView(result)
            }
        }
        .padding(14)
        .frame(width: 360)
    }

    private func step(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("\(n).")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 16, alignment: .trailing)
            Text(text).font(.caption)
        }
    }

    @ViewBuilder
    private func resultView(_ result: TestResult) -> some View {
        switch result {
        case .success(let msg):
            Label(msg, systemImage: "checkmark.circle.fill")
                .font(.caption).foregroundStyle(.green)
                .fixedSize(horizontal: false, vertical: true)
        case .failure(let msg):
            Label(msg, systemImage: "exclamationmark.triangle.fill")
                .font(.caption).foregroundStyle(.red)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func testAndSave() async {
        testing = true
        testResult = nil
        defer { testing = false }

        let trimmed = feedInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed) else {
            testResult = .failure("链接格式无效，请重新复制。")
            return
        }
        let service = ICalService(feedURL: url)
        do {
            let items = try await service.fetchDeadlines()
            try store.setFeedURL(trimmed)
            testResult = .success("已连接，解析到 \(items.count) 个作业/测验。")
            await store.refresh()
        } catch {
            testResult = .failure(error.localizedDescription)
        }
    }
}
