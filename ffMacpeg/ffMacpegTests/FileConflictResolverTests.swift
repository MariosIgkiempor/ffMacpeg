import XCTest
@testable import ffMacpeg

final class FileConflictResolverTests: XCTestCase {

    private var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(
            at: tempDir, withIntermediateDirectories: true
        )
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    func testNoConflictReturnsBaseName() {
        let input = tempDir.appendingPathComponent("video.mov")
        FileManager.default.createFile(atPath: input.path, contents: nil)

        let output = FileConflictResolver.resolveOutputURL(
            for: input, targetExtension: "mp4"
        )
        XCTAssertEqual(output.lastPathComponent, "video.mp4")
    }

    func testConflictAppendsSuffix() {
        let input = tempDir.appendingPathComponent("video.mov")
        FileManager.default.createFile(atPath: input.path, contents: nil)

        let existing = tempDir.appendingPathComponent("video.mp4")
        FileManager.default.createFile(atPath: existing.path, contents: nil)

        let output = FileConflictResolver.resolveOutputURL(
            for: input, targetExtension: "mp4"
        )
        XCTAssertEqual(output.lastPathComponent, "video (1).mp4")
    }

    func testMultipleConflictsIncrement() {
        let input = tempDir.appendingPathComponent("video.mov")
        FileManager.default.createFile(atPath: input.path, contents: nil)

        for name in ["video.mp4", "video (1).mp4", "video (2).mp4"] {
            let url = tempDir.appendingPathComponent(name)
            FileManager.default.createFile(atPath: url.path, contents: nil)
        }

        let output = FileConflictResolver.resolveOutputURL(
            for: input, targetExtension: "mp4"
        )
        XCTAssertEqual(output.lastPathComponent, "video (3).mp4")
    }

    func testOutputIsInSameDirectoryAsInput() {
        let input = tempDir.appendingPathComponent("video.mov")
        FileManager.default.createFile(atPath: input.path, contents: nil)

        let output = FileConflictResolver.resolveOutputURL(
            for: input, targetExtension: "mp4"
        )
        XCTAssertEqual(
            output.deletingLastPathComponent().path,
            input.deletingLastPathComponent().path
        )
    }

    func testSameExtensionConflictsWithSelf() {
        let input = tempDir.appendingPathComponent("video.mp4")
        FileManager.default.createFile(atPath: input.path, contents: nil)

        let output = FileConflictResolver.resolveOutputURL(
            for: input, targetExtension: "mp4"
        )
        XCTAssertEqual(output.lastPathComponent, "video (1).mp4")
    }
}
