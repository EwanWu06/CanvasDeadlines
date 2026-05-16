import Foundation

enum CLIError: LocalizedError {
    case missingEnv(String)
    case unknownCommand(String)
    case usage

    var errorDescription: String? {
        switch self {
        case .missingEnv(let key):
            return "缺少环境变量 \(key)。请设置后重试，例如：\(key)=...  swift run -- --dump-ical"
        case .unknownCommand(let cmd):
            return "未知子命令：\(cmd)"
        case .usage:
            return CLIRunner.usageText
        }
    }
}

enum CLIRunner {
    static let usageText = """
    Canvas Deadlines · CLI 测试模式

      swift run -- --dump-ical        # 解析 iCal 订阅（需环境变量 CANVAS_ICAL）
      swift run -- --test-keychain    # Keychain 读写自检
      swift run -- --test-skipstore   # 跳过列表读写自检

    示例：
      CANVAS_CLI=1 CANVAS_ICAL='<你的ics链接>' swift run -- --dump-ical
    """

    static func run(arguments: [String]) async throws {
        let args = Array(arguments.dropFirst())
        guard let cmd = args.first else {
            print(usageText)
            return
        }

        switch cmd {
        case "--help", "-h":
            print(usageText)
        case "--test-keychain":
            try testKeychainCommand()
        case "--test-skipstore":
            testSkipStoreCommand()
        case "--dump-ical":
            try await dumpICalCommand()
        default:
            throw CLIError.unknownCommand(cmd)
        }
    }

    // MARK: - Commands

    private static func dumpICalCommand() async throws {
        let env = ProcessInfo.processInfo.environment
        guard let feed = env["CANVAS_ICAL"], !feed.isEmpty else {
            throw CLIError.missingEnv("CANVAS_ICAL")
        }
        guard let url = URL(string: feed) else { throw ICalError.invalidURL }
        let service = ICalService(feedURL: url)
        let dump = try await service.debugDump()
        print(dump)
        let items = try await service.fetchDeadlines()
        print("映射为 DeadlineItem：\(items.count) 项")
        for item in items.prefix(10) {
            print("  [\(item.kind.label)] \(item.title) — \(item.courseCode) — \(item.countdownText)")
        }
    }

    private static func testKeychainCommand() throws {
        let sample = "https://example.com/feed-\(Int.random(in: 1000...9999)).ics"
        try KeychainStore.saveFeedURL(sample)
        guard let loaded = KeychainStore.loadFeedURL() else {
            print("❌ 写入后无法读回。")
            return
        }
        print(loaded == sample ? "✅ Keychain 读写一致：\(sample)"
                               : "❌ 不一致。写入 \(sample) 读到 \(loaded)")
        try KeychainStore.deleteFeedURL()
        print(KeychainStore.loadFeedURL() == nil ? "✅ 删除成功。" : "❌ 删除失败，仍能读到。")
    }

    private static func testSkipStoreCommand() {
        let id = "test-\(Int.random(in: 1000...9999))"
        SkipStore.add(id)
        print(SkipStore.contains(id) ? "✅ 已加入跳过列表：\(id)" : "❌ 加入后未在列表中。")
        SkipStore.remove(id)
        print(!SkipStore.contains(id) ? "✅ 已移除：\(id)" : "❌ 移除失败。")
        print("当前跳过列表（应为空）：\(SkipStore.all())")
    }
}
