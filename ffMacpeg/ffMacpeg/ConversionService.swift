import Foundation

/// High-level API for performing video conversions.
/// Orchestrates FFmpegRunner and ConversionNotifier.
///
/// This is the single entry point that the main app calls from `onOpenURL`.
enum ConversionService {

    private static let runner = FFmpegRunner()

    /// Converts a video file to the specified format.
    ///
    /// Runs ffmpeg asynchronously, then sends a macOS notification
    /// on success or failure.
    @discardableResult
    static func convert(
        inputURL: URL,
        to format: VideoFormat
    ) async throws -> ConversionResult {
        let inputFileName = inputURL.lastPathComponent

        do {
            let result = try await runner.convert(inputURL: inputURL, to: format)
            ConversionNotifier.notifySuccess(
                inputFileName: inputFileName,
                outputURL: result.outputURL
            )
            return result
        } catch {
            ConversionNotifier.notifyFailure(
                inputFileName: inputFileName,
                error: error
            )
            throw error
        }
    }
}
