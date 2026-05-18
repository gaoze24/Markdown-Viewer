import XCTest
@testable import MarkdownReader

@MainActor
final class ReaderStateTests: XCTestCase {
    func testReaderProgressStateQuantizesAndClampsScrollProgress() {
        let state = ReaderProgressState()

        state.updateScrollProgress(0.126)
        XCTAssertEqual(state.scrollProgress, 0.13)

        state.updateScrollProgress(2)
        XCTAssertEqual(state.scrollProgress, 1)

        state.updateScrollProgress(-1)
        XCTAssertEqual(state.scrollProgress, 0)
    }
}
