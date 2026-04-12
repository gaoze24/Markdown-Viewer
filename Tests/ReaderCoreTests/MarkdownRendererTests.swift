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

    func testRendererPromotesMathLikeInlineCodeSpansInMathProse() {
        let markdown = """
        Let `x_{i,t}` be dollar exposure to factor `i`.
        If `V_t` is portfolio value and `x = w_t` is the exposure vector.
        Suppose there are `N` risk factors and `C` is the covariance matrix.
        Returns follow `R \\sim N(\\mu,\\sigma^2)` in the Gaussian model.
        """

        let document = MarkdownRenderer().render(markdown: markdown, sourceURL: nil)

        XCTAssertTrue(document.bodyHTML.contains(Data("x_{i,t}".utf8).base64EncodedString()))
        XCTAssertTrue(document.bodyHTML.contains(Data("i".utf8).base64EncodedString()))
        XCTAssertTrue(document.bodyHTML.contains(Data("V_t".utf8).base64EncodedString()))
        XCTAssertTrue(document.bodyHTML.contains(Data("x = w_t".utf8).base64EncodedString()))
        XCTAssertTrue(document.bodyHTML.contains(Data("N".utf8).base64EncodedString()))
        XCTAssertTrue(document.bodyHTML.contains(Data("C".utf8).base64EncodedString()))
        XCTAssertTrue(document.bodyHTML.contains(Data(#"R \sim N(\mu,\sigma^2)"#.utf8).base64EncodedString()))
        XCTAssertFalse(document.bodyHTML.contains("<code>x_{i,t}</code>"))
        XCTAssertFalse(document.bodyHTML.contains("<code>V_t</code>"))
        XCTAssertFalse(document.bodyHTML.contains("<code>N</code>"))
        XCTAssertFalse(document.bodyHTML.contains("<code>R \\sim N(\\mu,\\sigma^2)</code>"))
    }

    func testRendererKeepsProgrammingInlineCodeAsCode() {
        let markdown = """
        Use `for i in range(n)` with `sigma_p2`, call `portfolio_var()`, and keep `let x = 3` as code.
        """

        let document = MarkdownRenderer().render(markdown: markdown, sourceURL: nil)

        XCTAssertTrue(document.bodyHTML.contains("<code>for i in range(n)</code>"))
        XCTAssertTrue(document.bodyHTML.contains("<code>sigma_p2</code>"))
        XCTAssertTrue(document.bodyHTML.contains("<code>portfolio_var()</code>"))
        XCTAssertTrue(document.bodyHTML.contains("<code>let x = 3</code>"))
        XCTAssertFalse(document.bodyHTML.contains(Data("sigma_p2".utf8).base64EncodedString()))
        XCTAssertFalse(document.bodyHTML.contains(Data("portfolio_var()".utf8).base64EncodedString()))
        XCTAssertFalse(document.bodyHTML.contains(Data("let x = 3".utf8).base64EncodedString()))
    }

    func testRendererDoesNotPromoteLongUnderscoreAssignments() {
        let markdown = """
        Keep `user_id = value` and `sigma_p2` as code in implementation notes.
        """

        let document = MarkdownRenderer().render(markdown: markdown, sourceURL: nil)

        XCTAssertTrue(document.bodyHTML.contains("<code>user_id = value</code>"))
        XCTAssertTrue(document.bodyHTML.contains("<code>sigma_p2</code>"))
        XCTAssertFalse(document.bodyHTML.contains(Data("user_id = value".utf8).base64EncodedString()))
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

    func testRendererDecodesEntitiesInProseWithoutLeakingEscapedHTML() {
        let markdown = """
        90% -&gt; α = 1.282
        a &gt; b
        x &lt; y
        Tom &amp; Jerry
        f&#39;(x)
        if a &gt; b then ...
        """

        let document = MarkdownRenderer().render(markdown: markdown, sourceURL: nil)

        XCTAssertTrue(document.bodyHTML.contains("90% -&gt; α = 1.282"), document.bodyHTML)
        XCTAssertTrue(document.bodyHTML.contains("a &gt; b"), document.bodyHTML)
        XCTAssertTrue(document.bodyHTML.contains("x &lt; y"), document.bodyHTML)
        XCTAssertTrue(document.bodyHTML.contains("Tom &amp; Jerry"), document.bodyHTML)
        XCTAssertTrue(document.bodyHTML.contains("f&#39;(x)"), document.bodyHTML)
        XCTAssertFalse(document.bodyHTML.contains("&amp;gt;"), document.bodyHTML)
        XCTAssertFalse(document.bodyHTML.contains("&amp;lt;"), document.bodyHTML)
        XCTAssertFalse(document.bodyHTML.contains("&amp;#39;"), document.bodyHTML)
    }

    func testRendererRendersPlainProseCharactersWithoutEntityLeakage() {
        let markdown = """
        90% -> α = 1.282
        a > b
        x < y
        Tom & Jerry
        f'(x)
        if a > b then ...
        """

        let document = MarkdownRenderer().render(markdown: markdown, sourceURL: nil)

        XCTAssertTrue(document.bodyHTML.contains("90% -&gt; α = 1.282"), document.bodyHTML)
        XCTAssertTrue(document.bodyHTML.contains("a &gt; b"), document.bodyHTML)
        XCTAssertTrue(document.bodyHTML.contains("x &lt; y"), document.bodyHTML)
        XCTAssertTrue(document.bodyHTML.contains("Tom &amp; Jerry"), document.bodyHTML)
        XCTAssertTrue(document.bodyHTML.contains("f&#39;(x)"), document.bodyHTML)
        XCTAssertFalse(document.bodyHTML.contains("&amp;gt;"), document.bodyHTML)
        XCTAssertFalse(document.bodyHTML.contains("&amp;lt;"), document.bodyHTML)
        XCTAssertFalse(document.bodyHTML.contains("&amp;#39;"), document.bodyHTML)
    }

    func testRendererDecodesEntitiesInsideEmphasis() {
        let markdown = """
        **a &gt; b** and *f&#39;(x)*
        """

        let document = MarkdownRenderer().render(markdown: markdown, sourceURL: nil)

        XCTAssertTrue(document.bodyHTML.contains("<strong>a &gt; b</strong>"), document.bodyHTML)
        XCTAssertTrue(document.bodyHTML.contains("<em>f&#39;(x)</em>"), document.bodyHTML)
        XCTAssertFalse(document.bodyHTML.contains("&amp;gt;"), document.bodyHTML)
        XCTAssertFalse(document.bodyHTML.contains("&amp;#39;"), document.bodyHTML)
    }

    func testRendererKeepsEntitiesLiteralInsideInlineCodeAndCodeBlocks() {
        let markdown = """
        `a &gt; b`

        ```text
        if a &gt; b then ...
        ```
        """

        let document = MarkdownRenderer().render(markdown: markdown, sourceURL: nil)

        XCTAssertTrue(document.bodyHTML.contains("<code>a &amp;gt; b</code>"))
        XCTAssertTrue(document.bodyHTML.contains("if a &amp;gt; b then ..."))
    }

    func testRendererDecodesEntitiesForOutlineTitles() {
        let markdown = """
        ## if a &gt; b then ...
        """

        let document = MarkdownRenderer().render(markdown: markdown, sourceURL: nil)

        XCTAssertEqual(document.tableOfContents[0].title, "if a > b then ...")
    }

    private func flattenedTitles(in items: [TableOfContentsItem]) -> [String] {
        items.flatMap { $0.flattened().map(\.title) }
    }
}
