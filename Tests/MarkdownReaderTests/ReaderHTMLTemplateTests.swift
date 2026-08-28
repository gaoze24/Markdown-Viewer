import XCTest
@testable import MarkdownReader

final class ReaderHTMLTemplateTests: XCTestCase {
    func testReaderScriptCachesCurrentSearchAndHeadingStateForLargeDocuments() {
        let html = ReaderHTMLTemplate.makeDocument(
            bodyHTML: "<h1 id=\"intro\">Intro</h1><p>Hello reader.</p>",
            settings: ReaderDisplaySettings(baseFontSize: 18, readingWidth: 820, colorTheme: .auto)
        )

        XCTAssertTrue(html.contains("lastCurrentMatchIndex"))
        XCTAssertTrue(html.contains("activeHeadingIndex"))
    }

    func testReaderTemplateIncludesOfflineSyntaxHighlightingForMainstreamLanguages() {
        let html = ReaderHTMLTemplate.makeDocument(
            bodyHTML: """
            <pre class="code-block"><code class="language-go">for {}</code></pre>
            """,
            settings: ReaderDisplaySettings(baseFontSize: 18, readingWidth: 820, colorTheme: .auto)
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
            settings: ReaderDisplaySettings(baseFontSize: 18, readingWidth: 820, colorTheme: .auto)
        )

        XCTAssertTrue(html.contains("function inferSyntaxLanguage(source, documentHint)"))
        XCTAssertTrue(html.contains("golang cheat sheet"))
        XCTAssertTrue(html.contains("return \"go\""))
        XCTAssertTrue(html.contains("normalizedCodeLanguage(code) || inferSyntaxLanguage"))
    }

    func testReaderTemplateDrawsMermaidDiagramsOfflineAndReactsToThemeChanges() {
        let html = ReaderHTMLTemplate.makeDocument(
            bodyHTML: """
            <div class="mermaid-diagram" data-mermaid-source="Zmxvd2NoYXJ0IExS"><pre class="mermaid-source"><code>flowchart LR</code></pre></div>
            """,
            settings: ReaderDisplaySettings(baseFontSize: 18, readingWidth: 820, colorTheme: .auto)
        )

        XCTAssertTrue(html.contains("async function renderDiagrams()"))
        XCTAssertTrue(html.contains("function mermaidThemeName()"))
        XCTAssertTrue(html.contains("data-mermaid-source"))
        XCTAssertTrue(html.contains(".mermaid-diagram svg"))
        XCTAssertTrue(html.contains("if (resolvedColorScheme() !== previousScheme)"))
        XCTAssertTrue(html.contains(".mermaid-diagram.rendered"), "Drawn diagrams must be skipped by in-page search.")
        XCTAssertTrue(html.contains("globalThis[\"mermaid\"]"), "The Mermaid runtime should be inlined so diagrams draw offline.")
    }

    func testReaderTemplateOmitsMermaidRuntimeForDocumentsWithoutDiagrams() {
        let html = ReaderHTMLTemplate.makeDocument(
            bodyHTML: "<p>No diagrams here.</p>",
            settings: ReaderDisplaySettings(baseFontSize: 18, readingWidth: 820, colorTheme: .auto)
        )

        XCTAssertFalse(html.contains("globalThis[\"mermaid\"]"))
    }
}
