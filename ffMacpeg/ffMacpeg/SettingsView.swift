import SwiftUI

struct SettingsView: View {

    var body: some View {
        VStack(spacing: 24) {
            headerSection
            Divider()
            finderExtensionSection
            Spacer()
        }
        .padding(32)
        .frame(width: 400, height: 300)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "video.badge.waveform")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("FFmacPeg")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Finder Extension

    private var finderExtensionSection: some View {
        VStack(spacing: 16) {
            Text("Finder Extension")
                .font(.headline)

            Text("Enable the Finder extension to convert videos directly from the right-click menu.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Open Extensions Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    SettingsView()
}
