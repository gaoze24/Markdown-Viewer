import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    var onOpenFiles: (([URL]) -> Void)?

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        onOpenFiles?(filenames.map(URL.init(fileURLWithPath:)))
    }
}
