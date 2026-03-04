import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {

    @Bindable var appState: AppState

    @State private var droppedFileURL: URL?
    @State private var availableFormats: [VideoFormat] = []
    @State private var isTargeted = false

    private enum Phase {
        case idle
        case pickingFormat
        case converting
    }

    private var phase: Phase {
        if appState.isConverting { return .converting }
        if droppedFileURL != nil { return .pickingFormat }
        return .idle
    }

    var body: some View {
        Group {
            switch phase {
            case .idle:
                idleView
            case .pickingFormat:
                formatPickerView
            case .converting:
                convertingView
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
    }

    // MARK: - Idle (Drop Target)

    private var idleView: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.down.doc")
                .font(.system(size: 28))
                .foregroundStyle(isTargeted ? .blue : .secondary)
            Text("Drop a video file here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    isTargeted ? Color.blue : Color.secondary.opacity(0.4),
                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                )
        )
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isTargeted ? Color.blue.opacity(0.05) : Color.clear)
        )
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers)
        }
    }

    // MARK: - Format Picker

    private var formatPickerView: some View {
        VStack(spacing: 10) {
            if let url = droppedFileURL {
                HStack(spacing: 6) {
                    Image(systemName: "film")
                        .foregroundStyle(.secondary)
                    Text(url.lastPathComponent)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            Text("Convert to:")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                ForEach(availableFormats, id: \.self) { format in
                    Button {
                        startConversion(format: format)
                    } label: {
                        Text(format.rawValue.uppercased())
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                    }
                    .buttonStyle(.bordered)
                }
            }

            Button("Cancel", role: .cancel) {
                droppedFileURL = nil
                availableFormats = []
            }
            .font(.caption)
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.secondary.opacity(0.4), lineWidth: 1)
        )
    }

    // MARK: - Converting

    private var convertingView: some View {
        VStack(spacing: 8) {
            ProgressView()
                .controlSize(.regular)
            Text("Converting\u{2026}")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.secondary.opacity(0.4), lineWidth: 1)
        )
    }

    // MARK: - Actions

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        _ = provider.loadObject(ofClass: URL.self) { url, _ in
            guard let url else { return }
            let ext = url.pathExtension.lowercased()
            let formats = FormatLookup.targetFormats(forSourceExtension: ext)
            Task { @MainActor in
                if !formats.isEmpty {
                    droppedFileURL = url
                    availableFormats = formats
                }
            }
        }
        return true
    }

    private func startConversion(format: VideoFormat) {
        guard let url = droppedFileURL else { return }
        droppedFileURL = nil
        availableFormats = []
        appState.runConversion(inputURL: url, format: format)
    }
}
