import AppKit
import SwiftUI
import WebKit

struct MarkdownWebView: NSViewRepresentable {
    private enum Layout {
        static let topInset: CGFloat = 12
        static let bottomInset: CGFloat = 18
    }

    let bodyHTML: String
    let baseURL: URL?
    let displaySettings: ReaderDisplaySettings
    let searchQuery: String
    let searchNavigationRequest: SearchNavigationRequest?
    let anchorNavigationRequest: AnchorNavigationRequest?
    let onSearchUpdate: (Int, Int) -> Void
    let onProgressUpdate: (Double) -> Void
    let onOpenMarkdownLink: (URL) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.userContentController.add(context.coordinator, name: Coordinator.progressHandlerName)

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.setValue(false, forKey: "drawsBackground")
        webView.navigationDelegate = context.coordinator
        webView.allowsMagnification = false
        configureScrollInsets(for: webView)
        context.coordinator.loadIfNeeded(in: webView, parent: self)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        configureScrollInsets(for: webView)
        context.coordinator.parent = self
        context.coordinator.loadIfNeeded(in: webView, parent: self)
        context.coordinator.applyDisplaySettingsIfNeeded(on: webView)
        context.coordinator.applySearchIfNeeded(on: webView)
        context.coordinator.applySearchNavigationIfNeeded(on: webView)
        context.coordinator.applyAnchorNavigationIfNeeded(on: webView)
    }

    private func configureScrollInsets(for webView: WKWebView) {
        let insets = NSEdgeInsets(top: Layout.topInset, left: 0, bottom: Layout.bottomInset, right: 0)
        guard let scrollView = webView.subviews.first(where: { $0 is NSScrollView }) as? NSScrollView else {
            return
        }
        scrollView.contentInsets = insets
        scrollView.scrollerInsets = insets
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        static let progressHandlerName = "readerProgress"

        var parent: MarkdownWebView
        private var lastHTML = ""
        private var lastSearchQuery = ""
        private var lastSearchNavigationID: UUID?
        private var lastAnchorNavigationID: UUID?
        private var lastDisplaySettings: ReaderDisplaySettings?
        private var isLoaded = false

        init(parent: MarkdownWebView) {
            self.parent = parent
        }

        func loadIfNeeded(in webView: WKWebView, parent: MarkdownWebView) {
            let html = ReaderHTMLTemplate.makeDocument(bodyHTML: parent.bodyHTML, settings: parent.displaySettings)
            guard html != lastHTML else { return }
            lastHTML = html
            isLoaded = false
            webView.loadHTMLString(html, baseURL: parent.baseURL)
        }

        func applyDisplaySettingsIfNeeded(on webView: WKWebView) {
            guard isLoaded, lastDisplaySettings != parent.displaySettings else { return }
            lastDisplaySettings = parent.displaySettings
            let script = "window.reader.applyDisplaySettings(\(parent.displaySettings.baseFontSize), \(parent.displaySettings.readingWidth));"
            webView.evaluateJavaScript(script)
        }

        func applySearchIfNeeded(on webView: WKWebView) {
            guard isLoaded, parent.searchQuery != lastSearchQuery else { return }
            lastSearchQuery = parent.searchQuery

            let script = "window.reader.performSearch(\(quoted(parent.searchQuery)));"
            webView.evaluateJavaScript(script) { [weak self] result, _ in
                self?.parent.onSearchUpdate(
                    Self.int(from: result, key: "count"),
                    Self.int(from: result, key: "current")
                )
            }
        }

        func applySearchNavigationIfNeeded(on webView: WKWebView) {
            guard
                isLoaded,
                let request = parent.searchNavigationRequest,
                request.id != lastSearchNavigationID
            else {
                return
            }

            lastSearchNavigationID = request.id
            let direction = request.direction == .previous ? -1 : 1
            let script = "window.reader.stepSearch(\(direction));"
            webView.evaluateJavaScript(script) { [weak self] result, _ in
                self?.parent.onSearchUpdate(
                    Self.int(from: result, key: "count"),
                    Self.int(from: result, key: "current")
                )
            }
        }

        func applyAnchorNavigationIfNeeded(on webView: WKWebView) {
            guard
                isLoaded,
                let request = parent.anchorNavigationRequest,
                request.id != lastAnchorNavigationID
            else {
                return
            }

            lastAnchorNavigationID = request.id
            let script = "window.reader.scrollToAnchor(\(quoted(request.anchor)));"
            webView.evaluateJavaScript(script)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoaded = true
            lastDisplaySettings = nil
            lastSearchQuery = ""
            applyDisplaySettingsIfNeeded(on: webView)
            applySearchIfNeeded(on: webView)
            applyAnchorNavigationIfNeeded(on: webView)
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
            guard navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url else {
                return .allow
            }

            if url.fragment != nil, url.pathExtension.isEmpty || url.deletingFragment() == parent.baseURL {
                return .allow
            }

            if url.scheme == "http" || url.scheme == "https" {
                NSWorkspace.shared.open(url)
                return .cancel
            }

            if url.isFileURL {
                let extensionSet = Set(["md", "markdown", "mdown", "mkd", "mkdn"])
                if extensionSet.contains(url.pathExtension.lowercased()) {
                    parent.onOpenMarkdownLink(url)
                    return .cancel
                }

                NSWorkspace.shared.open(url)
                return .cancel
            }

            return .allow
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == Self.progressHandlerName, let value = message.body as? Double else { return }
            parent.onProgressUpdate(value)
        }

        private static func int(from result: Any?, key: String) -> Int {
            guard let dictionary = result as? [String: Any], let value = dictionary[key] as? Int else { return 0 }
            return value
        }

        private func quoted(_ string: String) -> String {
            guard
                let data = try? JSONEncoder().encode([string]),
                let payload = String(data: data, encoding: .utf8)
            else {
                return "\"\""
            }

            return String(payload.dropFirst().dropLast())
        }
    }
}

private extension URL {
    func deletingFragment() -> URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else { return self }
        components.fragment = nil
        return components.url ?? self
    }
}
