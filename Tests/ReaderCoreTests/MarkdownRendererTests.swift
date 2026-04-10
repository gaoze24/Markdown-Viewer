import ReaderCore
import XCTest

final class MarkdownRendererTests: XCTestCase {
    func testRendererBuildsTableOfContentsAndInlineFormatting() {
        let markdown = """
        # Calm Reader

        A paragraph with **bold**, *italic*, and a [link](https://example.com).

        ## Details

        More copy here.
        """

        let document = MarkdownRenderer().render(markdown: markdown, sourceURL: nil)

        XCTAssertEqual(document.title, "Calm Reader")
        XCTAssertEqual(document.tableOfContents.map(\.title), ["Calm Reader", "Details"])
        XCTAssertTrue(document.bodyHTML.contains("<strong>bold</strong>"))
        XCTAssertTrue(document.bodyHTML.contains("<em>italic</em>"))
        XCTAssertTrue(document.bodyHTML.contains("<a href=\"https://example.com\">link</a>"))
    }

    func testRendererSupportsTablesTasksAndFootnotes() {
        let markdown = """
        | Name | State |
        | :--- | ---: |
        | Sidebar | Ready |

        - [x] Search
        - [ ] Export

        Footnote ref[^1]

        [^1]: A tidy note.
        """

        let document = MarkdownRenderer().render(markdown: markdown, sourceURL: nil)

        XCTAssertTrue(document.bodyHTML.contains("<table>"))
        XCTAssertTrue(document.bodyHTML.contains("text-align:left"))
        XCTAssertTrue(document.bodyHTML.contains("text-align:right"))
        XCTAssertTrue(document.bodyHTML.contains("task-item checked"))
        XCTAssertTrue(document.bodyHTML.contains("task-item"))
        XCTAssertTrue(document.bodyHTML.contains("class=\"footnotes\""))
        XCTAssertTrue(document.bodyHTML.contains("fnref-1"))
    }
}
