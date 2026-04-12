import Foundation

public struct MarkdownRenderer: Sendable {
    public init() {}

    public func render(markdown: String, sourceURL: URL?) -> RenderedDocument {
        var parser = Parser(markdown: markdown, sourceURL: sourceURL)
        return parser.render()
    }
}

private struct Parser {
    private let sourceURL: URL?
    private let lines: [String]
    private let footnoteDefinitions: [String: String]
    private var slugifier = Slugifier()
    private var flatHeadings: [TableOfContentsItem] = []
    private var footnoteOrder: [String] = []
    private var footnoteNumbers: [String: Int] = [:]

    init(markdown: String, sourceURL: URL?) {
        let normalized = markdown
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "\t", with: "    ")

        let extraction = Self.extractFootnotes(from: normalized)
        self.lines = extraction.lines
        self.footnoteDefinitions = extraction.definitions
        self.sourceURL = sourceURL
    }

    mutating func render() -> RenderedDocument {
        let body = renderBlocks(lines)
        let footnotes = renderFootnotes()
        let title = flatHeadings.first?.title ?? sourceURL?.deletingPathExtension().lastPathComponent ?? "Untitled"
        return RenderedDocument(
            title: title,
            bodyHTML: body + footnotes,
            tableOfContents: Self.buildHeadingTree(from: flatHeadings)
        )
    }

    private mutating func renderBlocks(_ input: [String]) -> String {
        var html: [String] = []
        var index = 0

        while index < input.count {
            let line = input[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                index += 1
                continue
            }

            if let codeBlock = parseCodeBlock(from: input, index: &index) {
                html.append(codeBlock)
                continue
            }

            if let detailsBlock = parseDetailsBlock(from: input, index: &index) {
                html.append(detailsBlock)
                continue
            }

            if let mathBlock = parseMathBlock(from: input, index: &index) {
                html.append(mathBlock)
                continue
            }

            if let heading = parseHeading(from: input, index: &index) {
                html.append(heading)
                continue
            }

            if let horizontalRule = parseHorizontalRule(from: input, index: &index) {
                html.append(horizontalRule)
                continue
            }

            if let table = parseTable(from: input, index: &index) {
                html.append(table)
                continue
            }

            if let blockquote = parseBlockquote(from: input, index: &index) {
                html.append(blockquote)
                continue
            }

            if let list = parseList(from: input, index: &index) {
                html.append(list)
                continue
            }

            html.append(parseParagraph(from: input, index: &index))
        }

        return html.joined(separator: "\n")
    }

    private func parseCodeBlock(from input: [String], index: inout Int) -> String? {
        guard let fence = fenceInfo(for: input[index]) else { return nil }
        index += 1

        var codeLines: [String] = []
        while index < input.count {
            let line = input[index]
            if line.trimmingCharacters(in: .whitespaces).hasPrefix(String(repeating: String(fence.character), count: fence.length)) {
                index += 1
                break
            }
            codeLines.append(line)
            index += 1
        }

        let code = codeLines.joined(separator: "\n").htmlEscaped()
        let languageClass = fence.language.map { " class=\"language-\($0.htmlEscaped())\"" } ?? ""
        return """
        <pre class="code-block"><code\(languageClass)>\(code)</code></pre>
        """
    }

    private func parseDetailsBlock(from input: [String], index: inout Int) -> String? {
        guard input[index].trimmingCharacters(in: .whitespaces).hasPrefix("<details") else { return nil }

        var lines: [String] = []
        while index < input.count {
            let line = input[index]
            lines.append(line)
            index += 1
            if line.trimmingCharacters(in: .whitespaces).contains("</details>") {
                break
            }
        }

        return """
        <div class="details-block">
        \(lines.joined(separator: "\n"))
        </div>
        """
    }

    private func parseMathBlock(from input: [String], index: inout Int) -> String? {
        let trimmed = input[index].trimmingCharacters(in: .whitespaces)
        guard let delimiter = mathBlockDelimiter(for: trimmed) else { return nil }

        var mathLines = [trimmed]
        let firstLine = trimmed
        index += 1

        if delimiter.isClosed(on: firstLine, isFirstLine: true) {
            return mathBlockHTML(from: mathLines, delimiter: delimiter)
        }

        while index < input.count {
            let line = input[index]
            mathLines.append(line)
            index += 1

            if delimiter.isClosed(on: line, isFirstLine: false) {
                break
            }
        }

        return mathBlockHTML(from: mathLines, delimiter: delimiter)
    }

    private func mathBlockHTML(from lines: [String], delimiter: MathBlockDelimiter) -> String {
        mathPlaceholderHTML(source: delimiter.extractSource(from: lines), display: true)
    }

    private mutating func parseHeading(from input: [String], index: inout Int) -> String? {
        let current = input[index]

        if let atxRange = current.range(of: #"^(#{1,6})\s+(.+?)\s*#*\s*$"#, options: .regularExpression) {
            let headingText = String(current[atxRange])
            let level = headingText.prefix { $0 == "#" }.count
            let content = headingText.dropFirst(level).trimmingCharacters(in: .whitespaces)
            index += 1
            return headingHTML(text: content, level: level)
        }

        guard index + 1 < input.count else { return nil }

        let next = input[index + 1].trimmingCharacters(in: .whitespaces)
        let level: Int
        if next.range(of: #"^=+\s*$"#, options: .regularExpression) != nil {
            level = 1
        } else if next.range(of: #"^-+\s*$"#, options: .regularExpression) != nil {
            level = 2
        } else {
            return nil
        }

        index += 2
        return headingHTML(text: current.trimmingCharacters(in: .whitespaces), level: level)
    }

    private mutating func headingHTML(text: String, level: Int) -> String {
        let plainText = text.removingMarkdownArtifacts().htmlUnescaped()
        let id = slugifier.slug(for: plainText)
        flatHeadings.append(TableOfContentsItem(id: id, level: level, title: plainText))
        let html = renderInline(text)
        return """
        <h\(level) id="\(id)" class="heading-level-\(level)">
            <a class="heading-anchor" href="#\(id)" aria-label="Jump to \(plainText.htmlEscaped())">#</a>
            <span>\(html)</span>
        </h\(level)>
        """
    }

    private static func buildHeadingTree(from headings: [TableOfContentsItem]) -> [TableOfContentsItem] {
        final class Node {
            let id: String
            let level: Int
            let title: String
            var children: [Node] = []

            init(item: TableOfContentsItem) {
                self.id = item.id
                self.level = item.level
                self.title = item.title
            }

            func asItem() -> TableOfContentsItem {
                TableOfContentsItem(
                    id: id,
                    level: level,
                    title: title,
                    children: children.map { $0.asItem() }
                )
            }
        }

        var roots: [Node] = []
        var stack: [Node] = []

        for heading in headings {
            let node = Node(item: heading)

            while let last = stack.last, last.level >= node.level {
                stack.removeLast()
            }

            if let parent = stack.last {
                parent.children.append(node)
            } else {
                roots.append(node)
            }

            stack.append(node)
        }

        return roots.map { $0.asItem() }
    }

    private func parseHorizontalRule(from input: [String], index: inout Int) -> String? {
        let trimmed = input[index].trimmingCharacters(in: .whitespaces)
        guard matchesRegex(RegexPatterns.horizontalRule, in: trimmed) else {
            return nil
        }
        index += 1
        return "<hr />"
    }

    private mutating func parseTable(from input: [String], index: inout Int) -> String? {
        guard index + 1 < input.count else { return nil }
        let headerLine = input[index]
        let delimiterLine = input[index + 1]

        guard headerLine.contains("|"), isTableDelimiter(delimiterLine) else { return nil }

        let headers = splitTableRow(headerLine)
        let alignments = splitTableRow(delimiterLine).map(tableAlignment(for:))
        guard headers.count >= 2, headers.count == alignments.count else { return nil }

        index += 2
        var rows: [[String]] = []
        while index < input.count {
            let line = input[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, line.contains("|") else { break }
            rows.append(splitTableRow(line))
            index += 1
        }

        let headerHTML = zip(headers, alignments).map { header, alignment in
            "<th\(alignment.htmlAttribute)>\(renderInline(header))</th>"
        }.joined()

        let rowsHTML = rows.map { row in
            let padded = row + Array(repeating: "", count: max(0, headers.count - row.count))
            let cells = zip(padded.prefix(headers.count), alignments).map { value, alignment in
                "<td\(alignment.htmlAttribute)>\(renderInline(value))</td>"
            }.joined()
            return "<tr>\(cells)</tr>"
        }.joined(separator: "\n")

        return """
        <div class="table-wrap">
            <table>
                <thead><tr>\(headerHTML)</tr></thead>
                <tbody>
                    \(rowsHTML)
                </tbody>
            </table>
        </div>
        """
    }

    private mutating func parseBlockquote(from input: [String], index: inout Int) -> String? {
        guard input[index].trimmingCharacters(in: .whitespaces).hasPrefix(">") else { return nil }

        var quotedLines: [String] = []
        while index < input.count {
            let line = input[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                quotedLines.append("")
                index += 1
                continue
            }

            guard trimmed.hasPrefix(">") else { break }
            let content = trimmed.dropFirst().trimmingCharacters(in: .whitespaces)
            quotedLines.append(content)
            index += 1
        }

        let innerHTML = renderBlocks(quotedLines)
        return """
        <blockquote>
            \(innerHTML)
        </blockquote>
        """
    }

    private mutating func parseList(from input: [String], index: inout Int) -> String? {
        guard let firstMarker = listMarker(for: input[index]) else { return nil }
        let listIndent = firstMarker.indent
        let ordered = firstMarker.isOrdered
        let startValue = firstMarker.startNumber ?? 1
        var itemsHTML: [String] = []

        while index < input.count {
            if input[index].trimmingCharacters(in: .whitespaces).isEmpty {
                index += 1
                continue
            }

            guard let marker = listMarker(for: input[index]), marker.indent == listIndent, marker.isOrdered == ordered else {
                break
            }

            let markerWidth = marker.marker.count + 1
            var itemLines = [marker.content]
            var sawBlankLine = false
            index += 1

            while index < input.count {
                let line = input[index]
                if line.trimmingCharacters(in: .whitespaces).isEmpty {
                    itemLines.append("")
                    sawBlankLine = true
                    index += 1
                    continue
                }

                let lineIndent = leadingSpaces(in: line)
                if lineIndent <= listIndent {
                    if sawBlankLine || wouldStartNewBlock(line, nextLine: index + 1 < input.count ? input[index + 1] : nil) {
                        break
                    }
                }

                if let nextMarker = listMarker(for: line), nextMarker.indent == listIndent, nextMarker.isOrdered == ordered {
                    break
                }

                let dedent = min(leadingSpaces(in: line), listIndent + markerWidth)
                itemLines.append(line.trimmingLeadingSpaces(dedent))
                sawBlankLine = false
                index += 1
            }

            let itemHTML = renderListItem(from: itemLines)
            itemsHTML.append(itemHTML)
        }

        let listTag = ordered ? "ol start=\"\(startValue)\"" : "ul"
        return """
        <\(listTag)>
            \(itemsHTML.joined(separator: "\n"))
        </\(ordered ? "ol" : "ul")>
        """
    }

    private mutating func renderListItem(from lines: [String]) -> String {
        guard var firstLine = lines.first else { return "<li></li>" }

        let taskState: Bool?
        if firstLine.range(of: #"^\[( |x|X)\]\s+"#, options: .regularExpression) != nil {
            let checked = firstLine.lowercased().hasPrefix("[x]")
            firstLine = firstLine.replacingOccurrences(
                of: #"^\[( |x|X)\]\s+"#,
                with: "",
                options: .regularExpression
            )
            taskState = checked
        } else {
            taskState = nil
        }

        var normalized = lines
        normalized[0] = firstLine
        let rendered = renderBlocks(normalized)

        if let taskState {
            let taskClass = taskState ? " checked" : ""
            return """
            <li class="task-item\(taskClass)">
                <span class="task-box" aria-hidden="true"></span>
                <div class="task-content">\(rendered)</div>
            </li>
            """
        }

        return "<li>\(rendered)</li>"
    }

    private mutating func parseParagraph(from input: [String], index: inout Int) -> String {
        var collected: [String] = []

        while index < input.count {
            let line = input[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                break
            }

            if !collected.isEmpty, wouldStartNewBlock(line, nextLine: index + 1 < input.count ? input[index + 1] : nil) {
                break
            }

            collected.append(trimmed)
            index += 1
        }

        let joined = collected.joined(separator: " ")
        return "<p>\(renderInline(joined))</p>"
    }

    private mutating func renderFootnotes() -> String {
        guard !footnoteOrder.isEmpty else { return "" }

        let items = footnoteOrder.compactMap { key -> String? in
            guard let rawDefinition = footnoteDefinitions[key], footnoteNumbers[key] != nil else { return nil }
            let content = renderBlocks(rawDefinition.components(separatedBy: "\n"))
            return """
            <li id="fn-\(key.htmlEscaped())">
                \(content)
                <a class="footnote-backlink" href="#fnref-\(key.htmlEscaped())" aria-label="Back to content">↩</a>
            </li>
            """
        }.joined(separator: "\n")

        return """
        <section class="footnotes">
            <h2>Footnotes</h2>
            <ol>
                \(items)
            </ol>
        </section>
        """
    }

    private mutating func renderInline(_ text: String) -> String {
        if text.isEmpty {
            return ""
        }

        if !containsInlineMarkup(in: text) {
            return text.htmlUnescaped().htmlEscaped()
        }

        let codeSpans = PlaceholderStore()
        let mathSpans = PlaceholderStore()
        let media = PlaceholderStore()

        var html = text
        var source = html
        html = replaceMatches(
            in: html,
            pattern: RegexPatterns.inlineCode,
            options: []
        ) { match in
            let value = capture(match, in: source, group: 1)
            if shouldPromoteInlineCodeToMath(value, in: source, matchRange: match.range) {
                return mathSpans.store(mathPlaceholderHTML(source: value, display: false))
            }

            return codeSpans.store("<code>\(value.htmlEscaped())</code>")
        }

        source = html
        html = replaceMatches(
            in: html,
            pattern: RegexPatterns.inlineMathParen
        ) { match in
            mathSpans.store(mathPlaceholderHTML(
                source: capture(match, in: source, group: 1),
                display: false
            ))
        }

        source = html
        html = replaceMatches(
            in: html,
            pattern: RegexPatterns.inlineMathDollar
        ) { match in
            mathSpans.store(mathPlaceholderHTML(
                source: capture(match, in: source, group: 1),
                display: false
            ))
        }

        source = html
        html = replaceMatches(
            in: html,
            pattern: RegexPatterns.image
        ) { match in
            let altText = capture(match, in: source, group: 1).htmlUnescaped()
            let url = capture(match, in: source, group: 2).htmlUnescaped()
            let title = capture(match, in: source, group: 3).htmlUnescaped()
            let titleAttribute = !title.isEmpty
                ? " title=\"\(title.htmlEscaped())\""
                : ""
            let image = """
            <figure class="inline-image">
                <img src="\(url.htmlEscaped())" alt="\(altText.htmlEscaped())"\(titleAttribute) loading="lazy" />
            </figure>
            """
            return media.store(image)
        }

        source = html
        html = replaceMatches(
            in: html,
            pattern: RegexPatterns.link
        ) { match in
            let title = capture(match, in: source, group: 3).htmlUnescaped()
            let titleAttribute = !title.isEmpty
                ? " title=\"\(title.htmlEscaped())\""
                : ""
            let label = renderInline(capture(match, in: source, group: 1))
            let destination = capture(match, in: source, group: 2).htmlUnescaped()
            return media.store("<a href=\"\(destination.htmlEscaped())\"\(titleAttribute)>\(label)</a>")
        }

        // Decode known entities in prose first, then escape once for HTML output.
        html = html.htmlUnescaped().htmlEscaped()
        source = html
        html = replaceMatches(
            in: html,
            pattern: RegexPatterns.inlineFootnote
        ) { match in
            let key = capture(match, in: source, group: 1)
            guard footnoteDefinitions[key] != nil else { return "" }
            let number = footnoteNumbers[key] ?? {
                footnoteOrder.append(key)
                let value = footnoteOrder.count
                footnoteNumbers[key] = value
                return value
            }()

            return media.store("""
            <sup class="footnote-ref" id="fnref-\(key.htmlEscaped())"><a href="#fn-\(key.htmlEscaped())">\(number)</a></sup>
            """)
        }

        source = html
        html = replaceMatches(
            in: html,
            pattern: RegexPatterns.strong
        ) { match in
            "<strong>\(renderInline(capture(match, in: source, group: 2)))</strong>"
        }

        source = html
        html = replaceMatches(
            in: html,
            pattern: RegexPatterns.emphasisAsterisk
        ) { match in
            "<em>\(renderInline(capture(match, in: source, group: 1)))</em>"
        }

        source = html
        html = replaceMatches(
            in: html,
            pattern: RegexPatterns.emphasisUnderscore
        ) { match in
            "<em>\(renderInline(capture(match, in: source, group: 1)))</em>"
        }

        html = media.restore(in: html)
        html = mathSpans.restore(in: html)
        html = codeSpans.restore(in: html)
        return html
    }

    private func replaceMatches(
        in input: String,
        pattern: String,
        options: NSRegularExpression.Options = [],
        transform: (NSTextCheckingResult) -> String
    ) -> String {
        guard let regex = RegexCache.regex(for: pattern, options: options) else { return input }

        let matches = regex.matches(in: input, range: NSRange(input.startIndex..., in: input))
        guard !matches.isEmpty else { return input }

        var result = input
        for match in matches.reversed() {
            guard let range = Range(match.range, in: result) else { continue }
            result.replaceSubrange(range, with: transform(match))
        }
        return result
    }

    private func capture(_ match: NSTextCheckingResult, in source: String, group: Int) -> String {
        guard
            group < match.numberOfRanges,
            let range = Range(match.range(at: group), in: source)
        else {
            return ""
        }

        return String(source[range])
    }

    private func shouldPromoteInlineCodeToMath(_ value: String, in source: String, matchRange: NSRange) -> Bool {
        let candidate = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !candidate.isEmpty else { return false }
        guard candidate.count <= 80 else { return false }
        guard !candidate.contains("\n") else { return false }

        if matchesRegex(RegexPatterns.inlineCodeMathCommand, in: candidate) {
            // Avoid promoting common code escape forms and filesystem paths.
            if matchesRegex(RegexPatterns.inlineCodeBackslashLikelyCode, in: candidate) {
                return false
            }
            return true
        }

        if matchesRegex(RegexPatterns.inlineCodeLikelyProgramming, in: candidate) {
            return false
        }

        if candidate.contains("^") {
            return true
        }

        if candidate.contains("_") {
            if candidate.contains("{") || candidate.contains("}") {
                return true
            }

            if matchesRegex(RegexPatterns.inlineCodeShortSubscriptIdentifier, in: candidate) {
                return true
            }

            if matchesRegex(RegexPatterns.inlineCodeContainsShortSubscriptTerm, in: candidate) {
                return true
            }
        }

        if matchesRegex(RegexPatterns.inlineCodeSingleSymbol, in: candidate) {
            return contextLooksMathematical(in: source, matchRange: matchRange)
        }

        return false
    }

    private func contextLooksMathematical(in source: String, matchRange: NSRange) -> Bool {
        guard let range = Range(matchRange, in: source) else { return false }

        let prefix = String(source[..<range.lowerBound].suffix(64)).lowercased()
        let suffix = String(source[range.upperBound...].prefix(64)).lowercased()
        let context = "\(prefix) \(suffix)"

        if matchesRegex(RegexPatterns.inlineCodeContextLikelyProgramming, in: context) {
            return false
        }

        return matchesRegex(RegexPatterns.inlineCodeContextLikelyMath, in: context)
    }

    private func mathPlaceholderHTML(source: String, display: Bool) -> String {
        let normalized = source.trimmingCharacters(in: .whitespacesAndNewlines)
        let encoded = Data(normalized.utf8).base64EncodedString()
        let tag = display ? "div" : "span"
        let modeClass = display ? "display" : "inline"
        return """
        <\(tag) class="math-placeholder \(modeClass)" data-math-source="\(encoded)"></\(tag)>
        """
    }

    private func wouldStartNewBlock(_ line: String, nextLine: String?) -> Bool {
        if fenceInfo(for: line) != nil || listMarker(for: line) != nil {
            return true
        }
        if line.trimmingCharacters(in: .whitespaces).hasPrefix(">") {
            return true
        }
        if isTableDelimiter(nextLine ?? "") && line.contains("|") {
            return true
        }
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if matchesRegex(RegexPatterns.atxHeading, in: trimmed) {
            return true
        }
        if matchesRegex(RegexPatterns.horizontalRule, in: trimmed) {
            return true
        }
        if trimmed.hasPrefix("<details") {
            return true
        }
        if mathBlockDelimiter(for: trimmed) != nil {
            return true
        }
        return false
    }

    private func mathBlockDelimiter(for trimmedLine: String) -> MathBlockDelimiter? {
        if trimmedLine.hasPrefix("$$") {
            return .doubleDollar
        }

        if trimmedLine.hasPrefix("\\[") {
            return .bracket
        }

        return nil
    }

    private func listMarker(for line: String) -> ListMarker? {
        guard let regex = RegexCache.regex(for: RegexPatterns.listMarker) else { return nil }
        let nsRange = NSRange(line.startIndex..., in: line)
        guard
            let match = regex.firstMatch(in: line, range: nsRange),
            let indentRange = Range(match.range(at: 1), in: line),
            let markerRange = Range(match.range(at: 2), in: line),
            let contentRange = Range(match.range(at: 3), in: line)
        else {
            return nil
        }

        let marker = String(line[markerRange])
        let isOrdered = marker.hasSuffix(".")
        let startNumber = isOrdered ? Int(marker.dropLast()) : nil
        return ListMarker(
            indent: line[indentRange].count,
            marker: marker,
            content: String(line[contentRange]),
            isOrdered: isOrdered,
            startNumber: startNumber
        )
    }

    private func leadingSpaces(in line: String) -> Int {
        line.prefix { $0 == " " }.count
    }

    private func fenceInfo(for line: String) -> FenceInfo? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") else { return nil }
        let character = trimmed.first!
        let fenceLength = trimmed.prefix { $0 == character }.count
        let language = trimmed.dropFirst(fenceLength).trimmingCharacters(in: .whitespaces)
        return FenceInfo(
            character: character,
            length: fenceLength,
            language: language.isEmpty ? nil : language
        )
    }

    private func isTableDelimiter(_ line: String) -> Bool {
        matchesRegex(RegexPatterns.tableDelimiter, in: line.trimmingCharacters(in: .whitespaces))
    }

    private func splitTableRow(_ line: String) -> [String] {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let cleaned = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "|"))
        return cleaned
            .split(separator: "|", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }

    private func tableAlignment(for cell: String) -> TableAlignment {
        let trimmed = cell.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix(":"), trimmed.hasSuffix(":") {
            return .center
        }
        if trimmed.hasPrefix(":") {
            return .left
        }
        if trimmed.hasSuffix(":") {
            return .right
        }
        return .none
    }

    private static func extractFootnotes(from markdown: String) -> (lines: [String], definitions: [String: String]) {
        let lines = markdown.components(separatedBy: "\n")
        var result: [String] = []
        var definitions: [String: String] = [:]
        var index = 0
        let definitionRegex = RegexCache.regex(for: RegexPatterns.footnoteDefinition)

        while index < lines.count {
            let line = lines[index]
            if let regex = definitionRegex,
               let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
               let keyRange = Range(match.range(at: 1), in: line),
               let contentRange = Range(match.range(at: 2), in: line) {
                let key = String(line[keyRange])
                var contentLines = [String(line[contentRange])]
                index += 1

                while index < lines.count {
                    let next = lines[index]
                    if next.hasPrefix("    ") || next.hasPrefix("\t") {
                        contentLines.append(next.trimmingLeadingSpaces(4))
                        index += 1
                    } else if next.trimmingCharacters(in: .whitespaces).isEmpty {
                        contentLines.append("")
                        index += 1
                    } else {
                        break
                    }
                }

                definitions[key] = contentLines.joined(separator: "\n").trimmingCharacters(in: .newlines)
            } else {
                result.append(line)
                index += 1
            }
        }

        return (result, definitions)
    }

    private func containsInlineMarkup(in text: String) -> Bool {
        text.contains { Self.inlineTriggerCharacters.contains($0) }
    }

    private func matchesRegex(_ pattern: String, in text: String) -> Bool {
        guard let regex = RegexCache.regex(for: pattern) else { return false }
        return regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
    }

    private enum RegexPatterns {
        static let atxHeading = #"^(#{1,6})\s+"#
        static let horizontalRule = #"^((\*\s*){3,}|(-\s*){3,}|(_\s*){3,})$"#
        static let tableDelimiter = #"^\|?(\s*:?-{3,}:?\s*\|)+\s*:?-{3,}:?\s*\|?$"#
        static let listMarker = #"^(\s*)([-+*]|\d+\.)\s+(.+)$"#
        static let footnoteDefinition = #"^\[\^([^\]]+)\]:\s*(.*)$"#

        static let inlineCode = #"`([^`]+)`"#
        static let inlineCodeLikelyProgramming = #"(^|\s)(for|while|if|else|return|func|let|var|const|class|struct|import|from|range)\b|[.;]|->|::|\(|\)|\[|\]|\."#
        static let inlineCodeMathCommand = #"\\[A-Za-z]{2,}"#
        static let inlineCodeBackslashLikelyCode = #"[A-Za-z]:\\[A-Za-z]|\\[nrt0'\"\\]"#
        static let inlineCodeShortSubscriptIdentifier = #"^(?:[A-Za-z]{1,2}|\\[A-Za-z]+)_[A-Za-z0-9]{1,3}$"#
        static let inlineCodeContainsShortSubscriptTerm = #"(^|[^A-Za-z0-9\\])(?:[A-Za-z]{1,2}|\\[A-Za-z]+)_[A-Za-z0-9]{1,3}(?=$|[^A-Za-z0-9])"#
        static let inlineCodeSingleSymbol = #"^[A-Za-z]$"#
        static let inlineCodeContextLikelyMath = #"\b(let|suppose|assume|denote|where|factor|factors|portfolio|value|vector|matrix|covariance|variance|exposure|weight|weights|returns?)\b"#
        static let inlineCodeContextLikelyProgramming = #"\b(code|function|method|class|struct|loop|index|array|list|dictionary|string|integer|variable|call|compile|runtime|syntax|script)\b"#
        static let inlineMathParen = #"\\\(((?:\\.|[^\\])+?)\\\)"#
        static let inlineMathDollar = #"(?<!\\)\$(?![\s$])((?:\\.|[^$\\])+?)(?<!\\)\$"#
        static let image = #"\!\[([^\]]*)\]\(([^)\s]+)(?:\s+"([^"]*)")?\)"#
        static let link = #"\[([^\]]+)\]\(([^)\s]+)(?:\s+"([^"]*)")?\)"#
        static let inlineFootnote = #"\[\^([^\]]+)\]"#
        static let strong = #"(\*\*|__)(.+?)\1"#
        static let emphasisAsterisk = #"(?<!\*)\*(?!\s)(.+?)(?<!\s)\*(?!\*)"#
        static let emphasisUnderscore = #"(?<!_)_(?!\s)(.+?)(?<!\s)_(?!_)"#
    }

    private static let inlineTriggerCharacters: Set<Character> = ["`", "\\", "$", "[", "!", "*", "_", "&"]
}

private final class PlaceholderStore {
    private var values: [String] = []

    func store(_ value: String) -> String {
        let placeholder = "%%PLACEHOLDER\(values.count)%%"
        values.append(value)
        return placeholder
    }

    func restore(in input: String) -> String {
        values.enumerated().reduce(input) { partial, pair in
            partial.replacingOccurrences(of: "%%PLACEHOLDER\(pair.offset)%%", with: pair.element)
        }
    }
}

private enum RegexCache {
    private struct Key: Hashable {
        let pattern: String
        let optionsRawValue: UInt
    }

    nonisolated(unsafe) private static var cache: [Key: NSRegularExpression] = [:]
    private static let lock = NSLock()

    static func regex(for pattern: String, options: NSRegularExpression.Options = []) -> NSRegularExpression? {
        let key = Key(pattern: pattern, optionsRawValue: options.rawValue)

        lock.lock()
        defer { lock.unlock() }

        if let cached = cache[key] {
            return cached
        }

        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return nil
        }

        cache[key] = regex
        return regex
    }
}

private struct FenceInfo {
    let character: Character
    let length: Int
    let language: String?
}

private struct ListMarker {
    let indent: Int
    let marker: String
    let content: String
    let isOrdered: Bool
    let startNumber: Int?
}

private enum TableAlignment {
    case none
    case left
    case center
    case right

    var htmlAttribute: String {
        switch self {
        case .none:
            ""
        case .left:
            " style=\"text-align:left\""
        case .center:
            " style=\"text-align:center\""
        case .right:
            " style=\"text-align:right\""
        }
    }
}

private enum MathBlockDelimiter {
    case doubleDollar
    case bracket

    func extractSource(from lines: [String]) -> String {
        var value = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)

        switch self {
        case .doubleDollar:
            if value.hasPrefix("$$") {
                value.removeFirst(2)
            }
            if value.hasSuffix("$$") {
                value.removeLast(2)
            }
        case .bracket:
            if value.hasPrefix("\\[") {
                value.removeFirst(2)
            }
            if value.hasSuffix("\\]") {
                value.removeLast(2)
            }
        }

        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func isClosed(on line: String, isFirstLine: Bool) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        switch self {
        case .doubleDollar:
            let segments = trimmed.components(separatedBy: "$$")
            let occurrences = max(segments.count - 1, 0)

            if isFirstLine {
                guard occurrences >= 1 else { return false }
                let withoutOpening = trimmed.replacingOccurrences(of: "$$", with: "", options: [], range: trimmed.range(of: "$$"))
                return occurrences >= 2 || withoutOpening.contains("$$")
            }

            return occurrences >= 1

        case .bracket:
            if isFirstLine {
                return String(trimmed.dropFirst(2)).contains("\\]")
            }

            return trimmed.contains("\\]")
        }
    }
}
