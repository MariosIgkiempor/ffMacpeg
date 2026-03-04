import Foundation

/// A video container format that FFmacPeg can convert to.
/// Duplicated from the main app target's FormatRegistry — the extension only
/// needs the enum and the target-format lookup, not conversion profiles or
/// ffmpeg argument building.
enum VideoFormat: String, CaseIterable, Sendable {
    case mp4
    case mov
    case mkv
    case webm
    case avi
    case gif
}

/// Minimal format lookup for the Action Extension.
enum VideoFormats {

    static let supportedSourceExtensions: Set<String> = [
        "mov", "mp4", "avi", "mkv", "webm", "flv", "wmv",
        "mpg", "mpeg", "ts", "m4v",
    ]

    /// Returns the target formats available for a given source extension.
    /// The source's own format is excluded from the list.
    static func targetFormats(forSourceExtension ext: String) -> [VideoFormat] {
        let normalized = ext.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))

        guard supportedSourceExtensions.contains(normalized) else {
            return []
        }

        let sourceFormat: VideoFormat? = switch normalized {
        case "mp4": .mp4
        case "mov": .mov
        case "mkv": .mkv
        case "webm": .webm
        case "avi": .avi
        default: nil
        }

        let noGif: Set<String> = ["flv", "wmv", "mpg", "mpeg", "ts", "m4v"]
        let allTargets: [VideoFormat] =
            noGif.contains(normalized)
            ? [.mp4, .mov, .mkv, .webm, .avi]
            : VideoFormat.allCases

        return allTargets.filter { $0 != sourceFormat }
    }
}
