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
    private var headings: [TableOfContentsItem] = []
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
        let title = headings.first?.title ?? sourceURL?.deletingPathExtension().lastPathComponent ?? "Untitled"
        return RenderedDocument(
            title: title,
            bodyHTML: body + footnotes,
            tableOfContents: headings
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
        let plainText = text.removingMarkdownArtifacts()
        let id = slugifier.slug(for: plainText)
        headings.append(TableOfContentsItem(id: id, level: level, title: plainText))
        let html = renderInline(text)
        return """
        <h\(level) id="\(id)" class="heading-level-\(level)">
            <a class="heading-anchor" href="#\(id)" aria-label="Jump to \(plainText.htmlEscaped())">#</a>
            <span>\(html)</span>
        </h\(level)>
        """
    }

    private func parseHorizontalRule(from input: [String], index: inout Int) -> String? {
        let trimmed = input[index].trimmingCharacters(in: .whitespaces)
        guard trimmed.range(of: #"^((\*\s*){3,}|(-\s*){3,}|(_\s*){3,})$"#, options: .regularExpression) != nil else {
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
            index += 1

            while index < input.count {
                let line = input[index]
                if line.trimmingCharacters(in: .whitespaces).isEmpty {
                    itemLines.append("")
                    index += 1
                    continue
                }

                if let nextMarker = listMarker(for: line), nextMarker.indent == listIndent, nextMarker.isOrdered == ordered {
                    break
                }

                let dedent = min(leadingSpaces(in: line), listIndent + markerWidth)
                itemLines.append(line.trimmingLeadingSpaces(dedent))
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
        let codeSpans = PlaceholderStore()
        let media = PlaceholderStore()

        var html = text.htmlEscaped()
        var source = html
        html = replaceMatches(
            in: html,
            pattern: #"`([^`]+)`"#,
            options: []
        ) { match in
            let value = capture(match, in: source, group: 1).htmlEscaped()
            return codeSpans.store("<code>\(value)</code>")
        }

        source = html
        html = replaceMatches(
            in: html,
            pattern: #"\!\[([^\]]*)\]\(([^)\s]+)(?:\s+&quot;([^&]*)&quot;)?\)"#
        ) { match in
            let altText = capture(match, in: source, group: 1)
            let url = capture(match, in: source, group: 2)
            let title = capture(match, in: source, group: 3)
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
            pattern: #"\[([^\]]+)\]\(([^)\s]+)(?:\s+&quot;([^&]*)&quot;)?\)"#
        ) { match in
            let title = capture(match, in: source, group: 3)
            let titleAttribute = !title.isEmpty
                ? " title=\"\(title.htmlEscaped())\""
                : ""
            let label = renderInline(capture(match, in: source, group: 1))
            let destination = capture(match, in: source, group: 2)
            return media.store("<a href=\"\(destination.htmlEscaped())\"\(titleAttribute)>\(label)</a>")
        }

        source = html
        html = replaceMatches(
            in: html,
            pattern: #"\[\^([^\]]+)\]"#
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
            pattern: #"(\*\*|__)(.+?)\1"#
        ) { match in
            "<strong>\(renderInline(capture(match, in: source, group: 2)))</strong>"
        }

        source = html
        html = replaceMatches(
            in: html,
            pattern: #"(?<!\*)\*(?!\s)(.+?)(?<!\s)\*(?!\*)"#
        ) { match in
            "<em>\(renderInline(capture(match, in: source, group: 1)))</em>"
        }

        source = html
        html = replaceMatches(
            in: html,
            pattern: #"(?<!_)_(?!\s)(.+?)(?<!\s)_(?!_)"#
        ) { match in
            "<em>\(renderInline(capture(match, in: source, group: 1)))</em>"
        }

        html = media.restore(in: html)
        html = codeSpans.restore(in: html)
        return html
    }

    private func replaceMatches(
        in input: String,
        pattern: String,
        options: NSRegularExpression.Options = [],
        transform: (NSTextCheckingResult) -> String
    ) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return input }

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
        if line.trimmingCharacters(in: .whitespaces).range(of: #"^(#{1,6})\s+"#, options: .regularExpression) != nil {
            return true
        }
        if line.trimmingCharacters(in: .whitespaces).range(of: #"^((\*\s*){3,}|(-\s*){3,}|(_\s*){3,})$"#, options: .regularExpression) != nil {
            return true
        }
        if line.trimmingCharacters(in: .whitespaces).hasPrefix("<details") {
            return true
        }
        return false
    }

    private func listMarker(for line: String) -> ListMarker? {
        guard let regex = try? NSRegularExpression(pattern: #"^(\s*)([-+*]|\d+\.)\s+(.+)$"#) else { return nil }
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
        line.trimmingCharacters(in: .whitespaces)
            .range(of: #"^\|?(\s*:?-{3,}:?\s*\|)+\s*:?-{3,}:?\s*\|?$"#, options: .regularExpression) != nil
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

        while index < lines.count {
            let line = lines[index]
            if let regex = try? NSRegularExpression(pattern: #"^\[\^([^\]]+)\]:\s*(.*)$"#),
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
}

private final class PlaceholderStore {
    private var values: [String] = []

    func store(_ value: String) -> String {
        let placeholder = "%%PLACEHOLDER_\(values.count)%%"
        values.append(value)
        return placeholder
    }

    func restore(in input: String) -> String {
        values.enumerated().reduce(input) { partial, pair in
            partial.replacingOccurrences(of: "%%PLACEHOLDER_\(pair.offset)%%", with: pair.element)
        }
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
