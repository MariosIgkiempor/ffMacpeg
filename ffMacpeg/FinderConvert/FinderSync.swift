import Cocoa
import FinderSync

class FinderSync: FIFinderSync {

    override init() {
        super.init()
        // Monitor all volumes so we can offer context menus anywhere
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    // MARK: - Context Menu

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard menuKind == .contextualMenuForItems else { return nil }

        guard let items = FIFinderSyncController.default().selectedItemURLs(),
              let firstItem = items.first else {
            return nil
        }

        let ext = firstItem.pathExtension.lowercased()
        let formats = FormatLookup.targetFormats(forSourceExtension: ext)

        guard !formats.isEmpty else { return nil }

        let menu = NSMenu(title: "")
        let convertItem = NSMenuItem(title: "Convert to", action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: "Convert to")

        for format in formats {
            let item = NSMenuItem(
                title: format.rawValue.uppercased(),
                action: #selector(convertToFormat(_:)),
                keyEquivalent: ""
            )
            item.representedObject = format.rawValue
            item.target = self
            submenu.addItem(item)
        }

        convertItem.submenu = submenu
        menu.addItem(convertItem)
        return menu
    }

    // MARK: - Actions

    @objc private func convertToFormat(_ sender: NSMenuItem) {
        guard let formatString = sender.representedObject as? String,
              let items = FIFinderSyncController.default().selectedItemURLs() else {
            return
        }

        for fileURL in items {
            var components = URLComponents()
            components.scheme = "ffmacpeg"
            components.host = "convert"
            components.queryItems = [
                URLQueryItem(name: "file", value: fileURL.path),
                URLQueryItem(name: "format", value: formatString),
            ]

            if let url = components.url {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
