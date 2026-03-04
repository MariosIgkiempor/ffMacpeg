//
//  ffMacpegApp.swift
//  ffMacpeg
//
//  Created by Marios Igkiempor on 03/03/2026.
//

import SwiftUI
import os

@Observable
final class AppState {
    var isConverting = false
}

@main
struct ffMacpegApp: App {

    @State private var appState = AppState()

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "ffMacpeg",
        category: "URLHandler"
    )

    var body: some Scene {
        WindowGroup {
            ContentView(appState: appState)
                .onOpenURL { url in
                    handleConversionURL(url)
                }
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

        Task {
            appState.isConverting = true
            defer { appState.isConverting = false }

            do {
                try await ConversionService.convert(inputURL: inputURL, to: format)
            } catch {
                Self.logger.error("Conversion failed: \(error.localizedDescription)")
            }
        }
    }
}
