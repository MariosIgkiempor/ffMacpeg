import SwiftUI

struct FormatPickerView: View {
    let fileName: String
    let formats: [VideoFormat]
    let onSelect: (VideoFormat) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Convert")
                    .font(.headline)
                Text(fileName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(formats, id: \.self) { format in
                        Button {
                            onSelect(format)
                        } label: {
                            HStack {
                                Text(format.rawValue.uppercased())
                                    .font(.system(.body, design: .monospaced, weight: .medium))
                                Spacer()
                                Image(systemName: "arrow.right.circle")
                                    .foregroundStyle(.secondary)
                            }
                            .contentShape(Rectangle())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Divider()

            HStack {
                Spacer()
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.escape, modifiers: [])
                .padding(12)
            }
        }
        .frame(width: 320)
    }
}
