import XCTest
@testable import ffMacpeg

final class FormatRegistryTests: XCTestCase {

    // MARK: - targetFormats

    func testMP4SourceExcludesMP4Target() {
        let targets = FormatRegistry.targetFormats(forSourceExtension: "mp4")
        XCTAssertFalse(targets.contains(.mp4))
        XCTAssertTrue(targets.contains(.mov))
        XCTAssertTrue(targets.contains(.mkv))
        XCTAssertTrue(targets.contains(.webm))
        XCTAssertTrue(targets.contains(.avi))
        XCTAssertTrue(targets.contains(.gif))
    }

    func testMOVSourceExcludesMOVTarget() {
        let targets = FormatRegistry.targetFormats(forSourceExtension: "mov")
        XCTAssertFalse(targets.contains(.mov))
        XCTAssertTrue(targets.contains(.mp4))
    }

    func testMKVSourceExcludesMKVTarget() {
        let targets = FormatRegistry.targetFormats(forSourceExtension: "mkv")
        XCTAssertFalse(targets.contains(.mkv))
        XCTAssertTrue(targets.contains(.mp4))
    }

    func testWebMSourceExcludesWebMTarget() {
        let targets = FormatRegistry.targetFormats(forSourceExtension: "webm")
        XCTAssertFalse(targets.contains(.webm))
        XCTAssertTrue(targets.contains(.mp4))
    }

    func testAVISourceExcludesAVITarget() {
        let targets = FormatRegistry.targetFormats(forSourceExtension: "avi")
        XCTAssertFalse(targets.contains(.avi))
        XCTAssertTrue(targets.contains(.mp4))
    }

    func testM4VDoesNotExcludeMP4() {
        let targets = FormatRegistry.targetFormats(forSourceExtension: "m4v")
        XCTAssertTrue(targets.contains(.mp4))
        XCTAssertTrue(targets.contains(.mov))
    }

    func testLegacyFormatsExcludeGIF() {
        for ext in ["flv", "wmv", "mpg", "mpeg", "ts", "m4v"] {
            let targets = FormatRegistry.targetFormats(forSourceExtension: ext)
            XCTAssertFalse(targets.contains(.gif), "\(ext) should not offer GIF")
        }
    }

    func testLegacyFormatsIncludeAllNonGIF() {
        for ext in ["flv", "wmv", "mpg", "mpeg", "ts"] {
            let targets = FormatRegistry.targetFormats(forSourceExtension: ext)
            XCTAssertEqual(targets.count, 5, "\(ext) should have 5 targets")
            XCTAssertTrue(targets.contains(.mp4))
            XCTAssertTrue(targets.contains(.mov))
            XCTAssertTrue(targets.contains(.mkv))
            XCTAssertTrue(targets.contains(.webm))
            XCTAssertTrue(targets.contains(.avi))
        }
    }

    func testUnsupportedExtensionReturnsEmpty() {
        XCTAssertTrue(FormatRegistry.targetFormats(forSourceExtension: "pdf").isEmpty)
        XCTAssertTrue(FormatRegistry.targetFormats(forSourceExtension: "jpg").isEmpty)
        XCTAssertTrue(FormatRegistry.targetFormats(forSourceExtension: "").isEmpty)
    }

    func testExtensionIsCaseInsensitive() {
        let targets = FormatRegistry.targetFormats(forSourceExtension: "MP4")
        XCTAssertFalse(targets.isEmpty)
        XCTAssertFalse(targets.contains(.mp4))
    }

    func testExtensionWithLeadingDot() {
        let targets = FormatRegistry.targetFormats(forSourceExtension: ".mp4")
        XCTAssertFalse(targets.isEmpty)
        XCTAssertFalse(targets.contains(.mp4))
    }

    // MARK: - ffmpegArguments

    func testMP4ArgumentsContainExpectedFlags() {
        let args = FormatRegistry.ffmpegArguments(
            inputPath: "/input.mov", outputPath: "/output.mp4", format: .mp4
        )
        XCTAssertEqual(args[0], "-i")
        XCTAssertEqual(args[1], "/input.mov")
        XCTAssertTrue(args.contains("libx264"))
        XCTAssertTrue(args.contains("aac"))
        XCTAssertTrue(args.contains("-movflags"))
        XCTAssertTrue(args.contains("+faststart"))
        XCTAssertTrue(args.contains("-crf"))
        XCTAssertTrue(args.contains("20"))
        XCTAssertTrue(args.contains("-y"))
        XCTAssertEqual(args.last, "/output.mp4")
    }

    func testWebMArgumentsUseVP9() {
        let args = FormatRegistry.ffmpegArguments(
            inputPath: "/input.mov", outputPath: "/output.webm", format: .webm
        )
        XCTAssertTrue(args.contains("libvpx-vp9"))
        XCTAssertTrue(args.contains("libvorbis"))
    }

    func testGIFArgumentsHaveNoAudio() {
        let args = FormatRegistry.ffmpegArguments(
            inputPath: "/input.mov", outputPath: "/output.gif", format: .gif
        )
        XCTAssertTrue(args.contains("-an"))
        XCTAssertFalse(args.contains("-c:a"))
        XCTAssertTrue(args.contains("gif"))
    }

    func testMKVArgumentsCopyAudio() {
        let args = FormatRegistry.ffmpegArguments(
            inputPath: "/input.mov", outputPath: "/output.mkv", format: .mkv
        )
        XCTAssertTrue(args.contains("copy"))
    }

    // MARK: - profiles

    func testAllFormatsHaveProfiles() {
        for format in VideoFormat.allCases {
            let profile = FormatRegistry.profile(for: format)
            XCTAssertEqual(profile.format, format)
            XCTAssertFalse(profile.fileExtension.isEmpty)
            XCTAssertFalse(profile.videoCodec.isEmpty)
        }
    }
}
