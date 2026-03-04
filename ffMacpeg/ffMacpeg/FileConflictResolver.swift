import Foundation

/// Resolves file naming conflicts by appending a numeric suffix.
/// Example: "video.mp4" → "video (1).mp4" → "video (2).mp4"
enum FileConflictResolver {

    /// Returns a URL for the output file, adding a numeric suffix if the
    /// path already exists. The file is placed in the same directory as the input file.
    static func resolveOutputURL(
        for inputURL: URL,
        targetExtension: String,
        fileManager: FileManager = .default
    ) -> URL {
        let directory = inputURL.deletingLastPathComponent()
        let baseName = inputURL.deletingPathExtension().lastPathComponent

        let candidate = directory.appendingPathComponent("\(baseName).\(targetExtension)")
        if !fileManager.fileExists(atPath: candidate.path) {
            return candidate
        }

        var counter = 1
        while true {
            let numbered = directory.appendingPathComponent(
                "\(baseName) (\(counter)).\(targetExtension)"
            )
            if !fileManager.fileExists(atPath: numbered.path) {
                return numbered
            }
            counter += 1
        }
    }
}
