import Cocoa
import SwiftUI
import UniformTypeIdentifiers

class ActionViewController: NSViewController {

    private var sourceFileURL: URL?

    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 320, height: 300))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        extractFileURL { [weak self] url in
            DispatchQueue.main.async {
                self?.presentFormatPicker(for: url)
            }
        }
    }

    private func extractFileURL(completion: @escaping (URL?) -> Void) {
        guard let inputItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = inputItem.attachments else {
            completion(nil)
            return
        }

        let movieType = UTType.movie.identifier
        guard let provider = attachments.first(where: {
            $0.hasItemConformingToTypeIdentifier(movieType)
        }) else {
            completion(nil)
            return
        }

        provider.loadInPlaceFileRepresentation(forTypeIdentifier: movieType) { url, _, error in
            if let error {
                NSLog("FFmacPeg: failed to load file — \(error)")
            }
            completion(url)
        }
    }

    private func presentFormatPicker(for fileURL: URL?) {
        guard let fileURL else {
            presentError()
            return
        }

        self.sourceFileURL = fileURL
        let formats = VideoFormats.targetFormats(forSourceExtension: fileURL.pathExtension)

        guard !formats.isEmpty else {
            presentError()
            return
        }

        let pickerView = FormatPickerView(
            fileName: fileURL.lastPathComponent,
            formats: formats,
            onSelect: { [weak self] format in
                self?.handleFormatSelection(format)
            },
            onCancel: { [weak self] in
                self?.cancelRequest()
            }
        )

        embed(pickerView)
        self.preferredContentSize = NSSize(width: 320, height: 300)
    }

    private func handleFormatSelection(_ format: VideoFormat) {
        guard let sourceFileURL else { return }

        var components = URLComponents()
        components.scheme = "ffmacpeg"
        components.host = "convert"
        components.queryItems = [
            URLQueryItem(name: "file", value: sourceFileURL.path),
            URLQueryItem(name: "format", value: format.rawValue),
        ]

        if let url = components.url {
            NSWorkspace.shared.open(url)
        }

        extensionContext?.completeRequest(returningItems: nil)
    }

    private func cancelRequest() {
        let error = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError)
        extensionContext?.cancelRequest(withError: error)
    }

    private func presentError() {
        let errorView = Text("Unsupported file type")
            .font(.headline)
            .foregroundStyle(.secondary)
            .frame(width: 320, height: 100)
        embed(errorView)
    }

    private func embed<V: View>(_ swiftUIView: V) {
        let hostingView = NSHostingView(rootView: swiftUIView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: view.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
}
