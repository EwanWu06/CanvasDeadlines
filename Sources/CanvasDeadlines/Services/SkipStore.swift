import Foundation

enum SkipStore {
    private static let defaultsKey = "skipped-deadline-ids"
    private static var defaults: UserDefaults { .standard }

    static func all() -> Set<String> {
        let arr = defaults.stringArray(forKey: defaultsKey) ?? []
        return Set(arr)
    }

    static func add(_ id: String) {
        var current = all()
        current.insert(id)
        defaults.set(Array(current), forKey: defaultsKey)
    }

    static func remove(_ id: String) {
        var current = all()
        current.remove(id)
        defaults.set(Array(current), forKey: defaultsKey)
    }

    static func contains(_ id: String) -> Bool {
        all().contains(id)
    }

    static func clear() {
        defaults.removeObject(forKey: defaultsKey)
    }
}

/// 用户手动「标记提交」的项。iCal 数据源没有提交状态，必须本地持久化，
/// 否则每次刷新已交的作业又会冒出来。Token 模式下也一并生效（无害）。
enum SubmittedStore {
    private static let key = "submitted-deadline-ids"
    private static var defaults: UserDefaults { .standard }

    static func all() -> Set<String> {
        Set(defaults.stringArray(forKey: key) ?? [])
    }

    static func add(_ id: String) {
        var c = all(); c.insert(id)
        defaults.set(Array(c), forKey: key)
    }

    static func remove(_ id: String) {
        var c = all(); c.remove(id)
        defaults.set(Array(c), forKey: key)
    }

    static func contains(_ id: String) -> Bool { all().contains(id) }
}

/// Canvas URL 与其它非敏感设置使用 UserDefaults，独立一个命名空间方便后续扩展。
enum AppSettings {
    private static let canvasURLKey = "canvas-base-url"
    static let defaultCanvasURL = "https://my.uclaextension.edu"

    static var canvasURL: String {
        get { UserDefaults.standard.string(forKey: canvasURLKey) ?? defaultCanvasURL }
        set { UserDefaults.standard.set(newValue, forKey: canvasURLKey) }
    }

    /// 逾期项最多往前看几天。iCal 模式没有提交状态，超过这个窗口的历史作业
    /// 极可能早已交完，没必要再刷屏。默认 3 天，可在设置里调整（阶段 5）。
    private static let overdueGraceKey = "overdue-grace-days"
    static let defaultOverdueGraceDays = 3

    static var overdueGraceDays: Int {
        get {
            let v = UserDefaults.standard.integer(forKey: overdueGraceKey)
            return v == 0 ? defaultOverdueGraceDays : v
        }
        set { UserDefaults.standard.set(newValue, forKey: overdueGraceKey) }
    }

    /// 课程名手动覆盖：键 = SUMMARY 末尾 `[注册号]` 里的注册号；值 = 显示名。
    /// 用于 iCal feed 里没有"课程横幅"事件、抓不到真实名的课程。
    /// 设置面板（阶段 5 后续）会提供编辑入口；这里内置用户已确认的默认项。
    private static let courseOverrideKey = "course-name-overrides"
    private static let builtinOverrides: [String: String] = [
        "407855": "Genetics, Evolution and Ecology LIFESCI XL 7B"
    ]

    static var courseNameOverrides: [String: String] {
        get {
            let saved = UserDefaults.standard
                .dictionary(forKey: courseOverrideKey) as? [String: String] ?? [:]
            // 用户保存的优先，内置默认兜底
            return builtinOverrides.merging(saved) { _, user in user }
        }
        set { UserDefaults.standard.set(newValue, forKey: courseOverrideKey) }
    }
}
