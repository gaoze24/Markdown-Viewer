import XCTest
@testable import MarkdownReader

final class ReaderHTMLTemplateTests: XCTestCase {
    func testReaderTemplateIncludesOfflineSyntaxHighlightingForMainstreamLanguages() {
        let html = ReaderHTMLTemplate.makeDocument(
            bodyHTML: """
            <pre class="code-block"><code class="language-go">for {}</code></pre>
            """,
            settings: ReaderDisplaySettings(baseFontSize: 18, readingWidth: 820)
        )

        XCTAssertTrue(html.contains("function highlightCodeBlocks()"))
        XCTAssertTrue(html.contains("\"golang\":\"go\""))
        XCTAssertTrue(html.contains("\"tsx\":\"typescript\""))
        XCTAssertTrue(html.contains("\"c++\":\"cpp\""))
        XCTAssertTrue(html.contains("\"bash\":\"shell\""))
        XCTAssertTrue(html.contains("--syntax-keyword"))
        XCTAssertTrue(html.contains("syntax-token keyword"))
    }

    func testReaderTemplateCanInferLanguageForUnannotatedGoCheatSheetBlocks() {
        let html = ReaderHTMLTemplate.makeDocument(
            bodyHTML: """
            <h1 id="golang-cheat-sheet">Golang Cheat Sheet</h1>
            <pre class="code-block"><code>bool
            string
            byte // alias for uint8
            for {
                select {
                case msg := &lt;-channel:
                    fmt.Println(msg)
                }
            }</code></pre>
            """,
            settings: ReaderDisplaySettings(baseFontSize: 18, readingWidth: 820)
        )

        XCTAssertTrue(html.contains("function inferSyntaxLanguage(source, documentHint)"))
        XCTAssertTrue(html.contains("golang cheat sheet"))
        XCTAssertTrue(html.contains("return \"go\""))
        XCTAssertTrue(html.contains("normalizedCodeLanguage(code) || inferSyntaxLanguage"))
    }
}
