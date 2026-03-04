import Foundation

/// Errors that can occur during an ffmpeg conversion.
enum ConversionError: Error, LocalizedError, Sendable {
    case inputFileNotFound(URL)
    case unsupportedFormat(String)
    case ffmpegNotFound
    case conversionFailed(exitCode: Int32, stderr: String)
    case processError(String)

    var errorDescription: String? {
        switch self {
        case .inputFileNotFound(let url):
            "Input file not found: \(url.lastPathComponent)"
        case .unsupportedFormat(let ext):
            "Unsupported format: \(ext)"
        case .ffmpegNotFound:
            "ffmpeg binary not found in app bundle"
        case .conversionFailed(let code, let stderr):
            "ffmpeg exited with code \(code): \(String(stderr.suffix(200)))"
        case .processError(let message):
            "Process error: \(message)"
        }
    }
}

/// The result of a successful conversion.
struct ConversionResult: Sendable {
    let outputURL: URL
    let duration: TimeInterval
}

/// Runs the bundled ffmpeg binary as a subprocess.
///
/// Explicitly `nonisolated` to opt out of the project's MainActor default
/// isolation, since this type performs blocking I/O.
nonisolated final class FFmpegRunner: Sendable {

    /// Converts a video file to the specified format.
    func convert(
        inputURL: URL,
        to format: VideoFormat
    ) async throws -> ConversionResult {
        guard FileManager.default.fileExists(atPath: inputURL.path) else {
            throw ConversionError.inputFileNotFound(inputURL)
        }

        let sourceExt = inputURL.pathExtension.lowercased()
        guard FormatRegistry.supportedSourceExtensions.contains(sourceExt) else {
            throw ConversionError.unsupportedFormat(sourceExt)
        }

        let outputURL = FileConflictResolver.resolveOutputURL(
            for: inputURL,
            targetExtension: FormatRegistry.profile(for: format).fileExtension
        )

        let args = FormatRegistry.ffmpegArguments(
            inputPath: inputURL.path,
            outputPath: outputURL.path,
            format: format
        )

        let ffmpegURL = try Self.locateFFmpeg()

        let startTime = Date()
        let (exitCode, stderr) = try await Self.runProcess(
            executableURL: ffmpegURL,
            arguments: args
        )
        let duration = Date().timeIntervalSince(startTime)

        guard exitCode == 0 else {
            try? FileManager.default.removeItem(at: outputURL)
            throw ConversionError.conversionFailed(exitCode: exitCode, stderr: stderr)
        }

        return ConversionResult(outputURL: outputURL, duration: duration)
    }

    private static func locateFFmpeg() throws -> URL {
        guard let url = Bundle.main.url(forAuxiliaryExecutable: "ffmpeg") else {
            throw ConversionError.ffmpegNotFound
        }
        return url
    }

    /// Runs a process asynchronously, capturing stderr.
    /// FFmpeg writes all diagnostic output to stderr; stdout is unused.
    private static func runProcess(
        executableURL: URL,
        arguments: [String]
    ) async throws -> (exitCode: Int32, stderr: String) {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = executableURL
            process.arguments = arguments

            let stderrPipe = Pipe()
            process.standardError = stderrPipe
            process.standardOutput = FileHandle.nullDevice

            var stderrData = Data()
            let stderrLock = NSLock()

            stderrPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if !data.isEmpty {
                    stderrLock.lock()
                    stderrData.append(data)
                    stderrLock.unlock()
                }
            }

            process.terminationHandler = { process in
                stderrPipe.fileHandleForReading.readabilityHandler = nil

                let remaining = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                stderrLock.lock()
                stderrData.append(remaining)
                stderrLock.unlock()

                let stderrString = String(data: stderrData, encoding: .utf8) ?? ""
                continuation.resume(
                    returning: (process.terminationStatus, stderrString)
                )
            }

            do {
                try process.run()
            } catch {
                continuation.resume(
                    throwing: ConversionError.processError(error.localizedDescription)
                )
            }
        }
    }
}
