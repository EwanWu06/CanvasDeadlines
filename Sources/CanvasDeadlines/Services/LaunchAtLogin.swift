import Foundation
import ServiceManagement

/// 开机自启动。用苹果官方 SMAppService（macOS 13+）把主 App 注册成登录项。
/// 注意：只有从打包好的 .app 运行才生效；Xcode 直接调试运行没有正式 bundle，会失败。
enum LaunchAtLogin {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            if SMAppService.mainApp.status != .enabled {
                try SMAppService.mainApp.register()
            }
        } else {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            }
        }
    }
}
