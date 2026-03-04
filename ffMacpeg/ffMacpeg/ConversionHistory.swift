import Foundation
import Observation
import os

/// A single conversion event recorded in history.
struct ConversionRecord: Codable, Identifiable, Sendable {
    var id: UUID
    var inputFileName: String
    var sourceExtension: String
    var targetFormat: String
    var timestamp: Date
    var success: Bool
    var errorMessage: String?
    var outputFileName: String?
    var durationSeconds: Double?

    init(
        id: UUID = UUID(),
        inputFileName: String,
        sourceExtension: String,
        targetFormat: String,
        timestamp: Date = Date(),
        success: Bool,
        errorMessage: String? = nil,
        outputFileName: String? = nil,
        durationSeconds: Double? = nil
    ) {
        self.id = id
        self.inputFileName = inputFileName
        self.sourceExtension = sourceExtension
        self.targetFormat = targetFormat
        self.timestamp = timestamp
        self.success = success
        self.errorMessage = errorMessage
        self.outputFileName = outputFileName
        self.durationSeconds = durationSeconds
    }
}

/// Persisted history of recent conversions, capped at 50 records.
@Observable
final class ConversionHistory {

    private(set) var records: [ConversionRecord] = []

    private static let maxRecords = 50
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "ffMacpeg",
        category: "ConversionHistory"
    )

    private static var defaultStorageURL: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let dir = appSupport.appendingPathComponent("FFmacPeg", isDirectory: true)
        return dir.appendingPathComponent("conversion_history.json")
    }

    @ObservationIgnored
    private let storageURL: URL

    init(storageURL: URL? = nil) {
        self.storageURL = storageURL ?? Self.defaultStorageURL
        records = Self.load(from: self.storageURL)
    }

    func addRecord(_ record: ConversionRecord) {
        records.insert(record, at: 0)
        if records.count > Self.maxRecords {
            records = Array(records.prefix(Self.maxRecords))
        }
        save()
    }

    func clearHistory() {
        records.removeAll()
        save()
    }

    // MARK: - Persistence

    private func save() {
        do {
            let dir = storageURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(records)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            Self.logger.error("Failed to save history: \(error.localizedDescription)")
        }
    }

    private static func load(from url: URL) -> [ConversionRecord] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([ConversionRecord].self, from: data)
        } catch {
            logger.error("Failed to load history: \(error.localizedDescription)")
            return []
        }
    }
}
