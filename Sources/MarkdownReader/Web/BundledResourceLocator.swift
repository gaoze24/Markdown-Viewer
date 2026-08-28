import Foundation

/// Locates files inside the SwiftPM resource bundle.
///
/// `Bundle.module` traps in the packaged `.app` because SwiftPM's generated
/// accessor expects the resource bundle beside `Bundle.main.bundleURL`, while
/// app bundles store it in `Contents/Resources`.
private final class BundleAnchor {}

enum BundledResourceLocator {
    private static let resourceBundleName = "MarkdownReader_MarkdownReader.bundle"

    /// Returns the directory that holds `probe`, checking `subdirectory` inside
    /// each candidate bundle root before the root itself.
    static func directory(named subdirectory: String, containing probe: String) -> URL? {
        for root in candidateRoots() {
            let nested = root.appending(path: subdirectory, directoryHint: .isDirectory)
            if FileManager.default.fileExists(atPath: nested.appending(path: probe).path) {
                return nested
            }

            if FileManager.default.fileExists(atPath: root.appending(path: probe).path) {
                return root
            }
        }

        return nil
    }

    private static func candidateRoots() -> [URL] {
        let mainBundle = Bundle.main
        let executableContainer = mainBundle.bundleURL.deletingLastPathComponent()
        // The anchor bundle covers hosts that do not load the app bundle as
        // `Bundle.main`, such as the test runner.
        let anchorContainer = Bundle(for: BundleAnchor.self).bundleURL.deletingLastPathComponent()

        return [
            mainBundle.resourceURL,
            mainBundle.resourceURL?.appending(path: resourceBundleName, directoryHint: .isDirectory),
            mainBundle.bundleURL.appending(path: resourceBundleName, directoryHint: .isDirectory),
            executableContainer.appending(path: "Resources", directoryHint: .isDirectory),
            executableContainer.appending(path: "Resources/\(resourceBundleName)", directoryHint: .isDirectory),
            anchorContainer.appending(path: resourceBundleName, directoryHint: .isDirectory)
        ].compactMap { $0 }
    }
}
