import WebKit
import XCTest
@testable import MarkdownReader

/// Drives the reader page in a real `WKWebView`, which is the only place the
/// diagram zoom actually runs.
@MainActor
final class ReaderDiagramZoomTests: XCTestCase {
    private func makeReaderWebView() async throws -> WKWebView {
        let source = """
        flowchart LR
            A["One"] --> B["Two"]
        """
        let bodyHTML = """
        <div class="mermaid-diagram" data-mermaid-source="\(Data(source.utf8).base64EncodedString())">\
        <pre class="mermaid-source"><code>\(source)</code></pre></div>
        """
        let html = ReaderHTMLTemplate.makeDocument(
            bodyHTML: bodyHTML,
            settings: ReaderDisplaySettings(baseFontSize: 18, readingWidth: 820, colorTheme: .auto)
        )

        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 900, height: 700))
        webView.loadHTMLString(html, baseURL: nil)
        try await waitUntilTrue(webView, "document.querySelectorAll('.mermaid-diagram.rendered .mermaid-viewport').length === 1")
        return webView
    }

    private func waitUntilTrue(_ webView: WKWebView, _ script: String, timeout: TimeInterval = 20) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let satisfied = try? await webView.evaluateJavaScript(script) as? Bool, satisfied {
                return
            }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        XCTFail("Timed out waiting for: \(script)")
    }

    private func pinch(_ webView: WKWebView, magnification: Double, atCenterOfDiagram: Bool = true) async throws -> Bool {
        let point = atCenterOfDiagram
            ? "const r = document.querySelector('.mermaid-diagram').getBoundingClientRect(); const x = r.left + r.width / 2, y = r.top + r.height / 2;"
            : "const x = 2, y = 2;"
        let result = try await webView.evaluateJavaScript("""
        (() => { \(point) return window.reader.magnifyDiagram(x, y, \(magnification)); })()
        """)
        return (result as? Bool) ?? false
    }

    private func transform(_ webView: WKWebView) async throws -> String {
        let result = try await webView.evaluateJavaScript("document.querySelector('.mermaid-viewport').style.transform")
        return (result as? String) ?? ""
    }

    func testPinchScalesTheDiagramUnderThePointer() async throws {
        let webView = try await makeReaderWebView()

        let handled = try await pinch(webView, magnification: 0.5)

        XCTAssertTrue(handled)
        let transform = try await transform(webView)
        XCTAssertTrue(transform.contains("scale(1.5)"), "Expected a scaled diagram, got \(transform)")
    }

    func testPinchOutsideADiagramLeavesThePageAlone() async throws {
        let webView = try await makeReaderWebView()

        let handled = try await pinch(webView, magnification: 0.5, atCenterOfDiagram: false)

        XCTAssertFalse(handled)
        let transform = try await transform(webView)
        XCTAssertTrue(transform.contains("scale(1)"), "Expected an unscaled diagram, got \(transform)")
    }

    func testScaleIsBoundedAndPinchingBackInRestoresTheFittedDiagram() async throws {
        let webView = try await makeReaderWebView()

        for _ in 0..<12 {
            _ = try await pinch(webView, magnification: 0.5)
        }
        let zoomedIn = try await transform(webView)
        XCTAssertTrue(zoomedIn.contains("scale(5)"), "Expected the scale ceiling, got \(zoomedIn)")

        for _ in 0..<12 {
            _ = try await pinch(webView, magnification: -0.5)
        }
        let zoomedOut = try await transform(webView)
        XCTAssertTrue(zoomedOut.contains("scale(1)"), "Expected the diagram to fit again, got \(zoomedOut)")
        // WebKit collapses `translate(0px, 0px)` when it serializes the transform.
        XCTAssertTrue(zoomedOut.hasPrefix("translate(0px)"), "Expected the pan to reset, got \(zoomedOut)")
    }
}
