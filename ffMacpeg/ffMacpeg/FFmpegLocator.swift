import Foundation

/// Locates the bundled ffmpeg and ffprobe binaries.
enum FFmpegLocator {
    static var ffmpegURL: URL {
        guard let url = Bundle.main.url(forAuxiliaryExecutable: "ffmpeg") else {
            fatalError("ffmpeg binary not found in app bundle")
        }
        return url
    }

    static var ffprobeURL: URL {
        guard let url = Bundle.main.url(forAuxiliaryExecutable: "ffprobe") else {
            fatalError("ffprobe binary not found in app bundle")
        }
        return url
    }
}
