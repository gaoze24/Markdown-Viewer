import XCTest
import Dispatch
import ReaderCore
@testable import MarkdownReader

final class DocumentLoaderTests: XCTestCase {
    func testDocumentLoaderReadsAndRendersMarkdownFile() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let url = directory.appendingPathComponent("Guide.md")
        try "# Guide\n\nHello **reader**.".write(to: url, atomically: true, encoding: .utf8)

        let rendered = try await DocumentLoader.renderDocument(from: url, renderer: MarkdownRenderer())

        XCTAssertEqual(rendered.title, "Guide")
        XCTAssertTrue(rendered.bodyHTML.contains("<strong>reader</strong>"))
    }

    func testDocumentLoaderCancelsBeforeRenderingObsoleteLoad() async {
        let url = URL(fileURLWithPath: "/tmp/cancelled.md")
        let loadStarted = DispatchSemaphore(value: 0)
        let releaseLoad = DispatchSemaphore(value: 0)
        let renderCounter = LockedCounter()

        let task = Task {
            try await DocumentLoader.renderDocument(
                from: url,
                loadMarkdown: { _ in
                    loadStarted.signal()
                    _ = releaseLoad.wait(timeout: .now() + .seconds(1))
                    return "# Cancelled"
                },
                render: { markdown, sourceURL in
                    renderCounter.increment()
                    return MarkdownRenderer().render(markdown: markdown, sourceURL: sourceURL)
                }
            )
        }

        XCTAssertEqual(loadStarted.wait(timeout: .now() + .seconds(1)), .success)
        task.cancel()
        releaseLoad.signal()

        do {
            _ = try await task.value
            XCTFail("Expected the document load to be cancelled.")
        } catch is CancellationError {
            XCTAssertEqual(renderCounter.value, 0)
        } catch {
            XCTFail("Expected CancellationError, got \(error).")
        }
    }
}

private final class LockedCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return count
    }

    func increment() {
        lock.lock()
        count += 1
        lock.unlock()
    }
}
