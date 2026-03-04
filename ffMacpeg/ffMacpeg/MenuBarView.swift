import SwiftUI

struct MenuBarView: View {

    @Bindable var appState: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            DropZoneView(appState: appState)
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 8)

            Divider()

            RecentConversionsView(appState: appState)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            Divider()

            footer
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .frame(width: 320)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Button("Settings\u{2026}") {
                openWindow(id: "settings")
                NSApplication.shared.activate()
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.secondary)

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}
