import Foundation
import os

@Observable
final class ExtensionStatus {

    private(set) var isEnabled = false

    private static let extensionID = "com.ffmacpeg.ffMacpeg.FinderConvert"
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "ffMacpeg",
        category: "ExtensionStatus"
    )

    private var timer: Timer?

    func startMonitoring() {
        check()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.check()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func check() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pluginkit")
        process.arguments = ["-m", "-i", Self.extensionID]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            // pluginkit output starts with "+" when enabled, "-" when disabled
            let enabled = output.hasPrefix("+")
            if enabled != isEnabled {
                Self.logger.info("Finder extension enabled: \(enabled)")
            }
            isEnabled = enabled
        } catch {
            Self.logger.error("Failed to check extension status: \(error.localizedDescription)")
            isEnabled = false
        }
    }
}
