import SwiftUI

struct MenuBarView: View {

    @Bindable var appState: AppState
    var extensionStatus: ExtensionStatus
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            if !extensionStatus.isEnabled {
                extensionBanner
                    .padding(.horizontal, 12)
                    .padding(.top, 12)

                Divider()
                    .padding(.top, 8)
            }

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

    // MARK: - Extension Banner

    private var extensionBanner: some View {
        VStack(spacing: 8) {
            Text("Enable the Finder extension to convert videos from the right-click menu.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Enable in Settings\u{2026}") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(.yellow.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
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
