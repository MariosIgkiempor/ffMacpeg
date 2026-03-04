import SwiftUI

struct RecentConversionsView: View {

    @Bindable var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()

            if appState.history.records.isEmpty {
                emptyState
            } else {
                recordsList
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Recent Conversions")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            if !appState.history.records.isEmpty {
                Button("Clear") {
                    appState.history.clearHistory()
                }
                .font(.caption)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 6)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        Text("No conversions yet")
            .font(.caption)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 16)
    }

    // MARK: - Records List

    private var recordsList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(appState.history.records) { record in
                    RecordRow(record: record)
                }
            }
            .padding(.vertical, 4)
        }
        .frame(maxHeight: 200)
    }
}

// MARK: - Record Row

private struct RecordRow: View {

    let record: ConversionRecord

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: record.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(record.success ? .green : .red)
                .font(.caption)

            VStack(alignment: .leading, spacing: 1) {
                Text(record.inputFileName)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(conversionLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(record.timestamp, style: .relative)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
    }

    private var conversionLabel: String {
        "\(record.sourceExtension.uppercased()) \u{2192} \(record.targetFormat.uppercased())"
    }
}
