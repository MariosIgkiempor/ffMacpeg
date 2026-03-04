import SwiftUI
import os

@Observable
final class AppState {
    var isConverting = false
    let history = ConversionHistory()

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "ffMacpeg",
        category: "AppState"
    )

    func runConversion(inputURL: URL, format: VideoFormat) {
        Task {
            isConverting = true
            defer { isConverting = false }

            do {
                let result = try await ConversionService.convert(inputURL: inputURL, to: format)
                history.addRecord(ConversionRecord(
                    inputFileName: inputURL.lastPathComponent,
                    sourceExtension: inputURL.pathExtension.lowercased(),
                    targetFormat: format.rawValue,
                    success: true,
                    outputFileName: result.outputURL.lastPathComponent,
                    durationSeconds: result.duration
                ))
            } catch {
                Self.logger.error("Conversion failed: \(error.localizedDescription)")
                history.addRecord(ConversionRecord(
                    inputFileName: inputURL.lastPathComponent,
                    sourceExtension: inputURL.pathExtension.lowercased(),
                    targetFormat: format.rawValue,
                    success: false,
                    errorMessage: error.localizedDescription
                ))
            }
        }
    }
}

// MARK: - App Delegate (URL handling)

final class AppDelegate: NSObject, NSApplicationDelegate {

    var appState: AppState?

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "ffMacpeg",
        category: "URLHandler"
    )

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            handleConversionURL(url)
        }
    }

    private func handleConversionURL(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme == "ffmacpeg",
              components.host == "convert" else {
            Self.logger.warning("Ignored URL with unexpected scheme/host: \(url)")
            return
        }

        let queryItems = components.queryItems ?? []
        guard let filePath = queryItems.first(where: { $0.name == "file" })?.value,
              let formatString = queryItems.first(where: { $0.name == "format" })?.value else {
            Self.logger.warning("Missing file or format query parameter: \(url)")
            return
        }

        guard let format = VideoFormat(rawValue: formatString) else {
            Self.logger.warning("Unknown format '\(formatString)' in URL: \(url)")
            return
        }

        let inputURL = URL(fileURLWithPath: filePath)
        appState?.runConversion(inputURL: inputURL, format: format)
    }
}

// MARK: - App

@main
struct ffMacpegApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(appState: appState)
                .task {
                    await ConversionNotifier.requestPermission()
                    appDelegate.appState = appState
                }
        } label: {
            Image(systemName: appState.isConverting
                  ? "film.circle"
                  : "video.badge.waveform")
        }
        .menuBarExtraStyle(.window)

        Window("Settings", id: "settings") {
            SettingsView()
        }
        .defaultSize(width: 400, height: 300)
        .windowResizability(.contentSize)
    }
}
