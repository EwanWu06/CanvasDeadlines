import AppKit
import Foundation
import SwiftUI

let env = ProcessInfo.processInfo.environment

if env["CANVAS_CLI"] == "1" {
    // CLI 测试模式：同步等待 async CLI 执行完成
    let semaphore = DispatchSemaphore(value: 0)
    var exitCode: Int32 = 0
    Task.detached {
        do {
            try await CLIRunner.run(arguments: CommandLine.arguments)
        } catch {
            FileHandle.standardError.write(
                Data("错误：\(error.localizedDescription)\n".utf8)
            )
            exitCode = 1
        }
        semaphore.signal()
    }
    semaphore.wait()
    exit(exitCode)
}

// GUI 模式：菜单栏小程序，不在 Dock 显示
NSApplication.shared.setActivationPolicy(.accessory)
CanvasDeadlinesApp.main()
