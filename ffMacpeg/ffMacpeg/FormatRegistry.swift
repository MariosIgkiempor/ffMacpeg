import Foundation

/// A video container format that FFmacPeg can convert to.
enum VideoFormat: String, CaseIterable, Sendable {
    case mp4
    case mov
    case mkv
    case webm
    case avi
    case gif
}

/// Encapsulates the ffmpeg arguments needed to convert to a specific format.
struct ConversionProfile: Sendable {
    let format: VideoFormat
    let fileExtension: String
    let videoCodec: String
    let audioCodec: String? // nil for GIF (no audio)
    let additionalArgs: [String]
}

/// Maps source file extensions to available target formats and provides
/// the ffmpeg arguments for each conversion.
enum FormatRegistry {

    /// All source extensions this app can accept as input.
    static let supportedSourceExtensions: Set<String> = [
        "mov", "mp4", "avi", "mkv", "webm", "flv", "wmv",
        "mpg", "mpeg", "ts", "m4v",
    ]

    private static let profiles: [VideoFormat: ConversionProfile] = [
        .mp4: ConversionProfile(
            format: .mp4,
            fileExtension: "mp4",
            videoCodec: "libx264",
            audioCodec: "aac",
            additionalArgs: ["-crf", "20", "-preset", "medium", "-movflags", "+faststart"]
        ),
        .mov: ConversionProfile(
            format: .mov,
            fileExtension: "mov",
            videoCodec: "libx264",
            audioCodec: "aac",
            additionalArgs: ["-crf", "20", "-preset", "medium"]
        ),
        .mkv: ConversionProfile(
            format: .mkv,
            fileExtension: "mkv",
            videoCodec: "libx264",
            audioCodec: "copy",
            additionalArgs: ["-crf", "20", "-preset", "medium"]
        ),
        .webm: ConversionProfile(
            format: .webm,
            fileExtension: "webm",
            videoCodec: "libvpx-vp9",
            audioCodec: "libvorbis",
            additionalArgs: ["-crf", "20", "-b:v", "0"]
        ),
        .avi: ConversionProfile(
            format: .avi,
            fileExtension: "avi",
            videoCodec: "libx264",
            audioCodec: "copy",
            additionalArgs: ["-crf", "20", "-preset", "medium"]
        ),
        .gif: ConversionProfile(
            format: .gif,
            fileExtension: "gif",
            videoCodec: "gif",
            audioCodec: nil,
            additionalArgs: ["-vf", "fps=15,scale=480:-1:flags=lanczos", "-loop", "0"]
        ),
    ]

    /// Returns the target formats available for a given source extension.
    /// The source's own format is excluded from the list.
    static func targetFormats(forSourceExtension ext: String) -> [VideoFormat] {
        let normalized = ext.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))

        guard supportedSourceExtensions.contains(normalized) else {
            return []
        }

        // Map source extension to the VideoFormat it already is
        let sourceFormat: VideoFormat? = switch normalized {
        case "mp4": .mp4
        case "mov": .mov
        case "mkv": .mkv
        case "webm": .webm
        case "avi": .avi
        default: nil // flv, wmv, mpg, mpeg, ts, m4v have no matching VideoFormat
        }

        // Legacy/uncommon formats don't offer GIF as a target
        let noGif: Set<String> = ["flv", "wmv", "mpg", "mpeg", "ts", "m4v"]
        let allTargets: [VideoFormat] =
            noGif.contains(normalized)
            ? [.mp4, .mov, .mkv, .webm, .avi]
            : VideoFormat.allCases

        return allTargets.filter { $0 != sourceFormat }
    }

    /// Returns the full ConversionProfile for a target format.
    static func profile(for format: VideoFormat) -> ConversionProfile {
        profiles[format]!
    }

    /// Builds the complete ffmpeg argument array for a conversion.
    static func ffmpegArguments(
        inputPath: String,
        outputPath: String,
        format: VideoFormat
    ) -> [String] {
        let profile = profiles[format]!
        var args: [String] = ["-i", inputPath]

        args += ["-c:v", profile.videoCodec]

        if let audioCodec = profile.audioCodec {
            args += ["-c:a", audioCodec]
        } else {
            args += ["-an"]
        }

        args += profile.additionalArgs
        args += ["-y", outputPath]

        return args
    }
}
