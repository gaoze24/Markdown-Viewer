import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    var onOpenFiles: (([URL]) -> Void)? {
        didSet {
            deliverPendingFilesIfPossible()
        }
    }

    private var pendingOpenFileURLs: [URL] = []

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        let urls = filenames.map(URL.init(fileURLWithPath:))

        if let onOpenFiles {
            onOpenFiles(urls)
        } else {
            pendingOpenFileURLs.append(contentsOf: urls)
        }

        sender.reply(toOpenOrPrint: .success)
    }

    private func deliverPendingFilesIfPossible() {
        guard let onOpenFiles, !pendingOpenFileURLs.isEmpty else { return }
        let urls = pendingOpenFileURLs
        pendingOpenFileURLs.removeAll()
        onOpenFiles(urls)
    }
}
