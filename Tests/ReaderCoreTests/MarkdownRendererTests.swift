import Foundation
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
        XCTAssertEqual(flattenedTitles(in: document.tableOfContents), ["Calm Reader", "Details"])
        XCTAssertTrue(document.bodyHTML.contains("<strong>bold</strong>"))
        XCTAssertTrue(document.bodyHTML.contains("<em>italic</em>"))
        XCTAssertTrue(document.bodyHTML.contains("<a href=\"https://example.com\">link</a>"))
    }

    func testRendererBuildsHierarchicalTableOfContents() {
        let markdown = """
        # Intro
        ## Context
        ### Details
        ## Summary
        # Appendix
        """

        let document = MarkdownRenderer().render(markdown: markdown, sourceURL: nil)

        XCTAssertEqual(document.tableOfContents.map(\.title), ["Intro", "Appendix"])
        XCTAssertEqual(document.tableOfContents[0].children.map(\.title), ["Context", "Summary"])
        XCTAssertEqual(document.tableOfContents[0].children[0].children.map(\.title), ["Details"])
    }

    func testRendererAssignsSkippedHeadingLevelsToNearestValidAncestor() {
        let markdown = """
        # Parent
        ### Grandchild
        #### Great Grandchild
        ## Sibling
        """

        let document = MarkdownRenderer().render(markdown: markdown, sourceURL: nil)
        let root = document.tableOfContents[0]

        XCTAssertEqual(root.title, "Parent")
        XCTAssertEqual(root.children.map(\.title), ["Grandchild", "Sibling"])
        XCTAssertEqual(root.children[0].children.map(\.title), ["Great Grandchild"])
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

    func testRendererPreservesInlineMathWithoutMarkdownMangling() {
        let markdown = """
        The variance term is $\\sigma^2$ and the expectation is \\(\\mathbb{E}[X_t^2]\\).
        """

        let document = MarkdownRenderer().render(markdown: markdown, sourceURL: nil)

        XCTAssertTrue(document.bodyHTML.contains("class=\"math-placeholder inline\""))
        XCTAssertTrue(document.bodyHTML.contains(Data(#"\sigma^2"#.utf8).base64EncodedString()))
        XCTAssertTrue(document.bodyHTML.contains(Data(#"\mathbb{E}[X_t^2]"#.utf8).base64EncodedString()))
        XCTAssertFalse(document.bodyHTML.contains("&#39;"))
    }

    func testRendererLiftsDisplayMathIntoDedicatedBlocks() {
        let markdown = """
        $$
        \\int_0^t X(u)\\,dW(u)
        $$

        \\[
        dX_t = \\mu X_t\\,dt + \\sigma X_t\\,dW_t
        \\]
        """

        let document = MarkdownRenderer().render(markdown: markdown, sourceURL: nil)

        XCTAssertTrue(document.bodyHTML.contains("class=\"math-placeholder display\""))
        XCTAssertTrue(document.bodyHTML.contains(Data(#"\int_0^t X(u)\,dW(u)"#.utf8).base64EncodedString()))
        XCTAssertTrue(document.bodyHTML.contains(Data(#"dX_t = \mu X_t\,dt + \sigma X_t\,dW_t"#.utf8).base64EncodedString()))
    }

    func testRendererPreservesPrimesAndFractionsInDisplayMathSource() {
        let equation = #"d f(W(t)) = f'(W(t))\,dW(t) + \frac12 f''(W(t))\,dt"#
        let markdown = """
        $$
        \(equation)
        $$
        """

        let document = MarkdownRenderer().render(markdown: markdown, sourceURL: nil)

        XCTAssertTrue(document.bodyHTML.contains(Data(equation.utf8).base64EncodedString()))
        XCTAssertFalse(document.bodyHTML.contains("&#39;"))
    }

    func testRendererResetsOrderedListNumberingForSeparateLists() {
        let markdown = """
        ## Earlier Chain

        9. Ninth
        10. Tenth

        ## The main conceptual chain of the chapter

        1. First
        2. Second
        3. Third
        4. Fourth
        5. Fifth
        """

        let document = MarkdownRenderer().render(markdown: markdown, sourceURL: nil)
        let earlierListCount = document.bodyHTML.components(separatedBy: "<ol start=\"9\">").count - 1
        let resetListCount = document.bodyHTML.components(separatedBy: "<ol start=\"1\">").count - 1

        XCTAssertEqual(earlierListCount, 1)
        XCTAssertEqual(resetListCount, 1)
    }

    func testRendererCleansInlineMathDelimitersFromOutlineTitles() {
        let markdown = """
        ## 5. How the new measure is built when the numeraire is $N(t)$
        """

        let document = MarkdownRenderer().render(markdown: markdown, sourceURL: nil)

        XCTAssertEqual(
            flattenedTitles(in: document.tableOfContents),
            ["5. How the new measure is built when the numeraire is N(t)"]
        )
        XCTAssertFalse(document.tableOfContents[0].title.contains("$"))
    }

    private func flattenedTitles(in items: [TableOfContentsItem]) -> [String] {
        items.flatMap { $0.flattened().map(\.title) }
    }
}
