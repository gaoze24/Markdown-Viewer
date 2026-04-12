import Foundation

extension String {
    func htmlEscaped() -> String {
        self
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    func htmlUnescaped() -> String {
        guard contains("&") else { return self }

        guard let value = CFXMLCreateStringByUnescapingEntities(nil, self as CFString, nil) else {
            return self
        }

        return value as String
    }

    func removingMarkdownArtifacts() -> String {
        self
            .replacingOccurrences(of: #"\!\[([^\]]*)\]\([^)]+\)"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"\[([^\]]+)\]\([^)]+\)"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"\[\^([^\]]+)\]"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"`([^`]+)`"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"\\\((.+?)\\\)"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"\\\[(.+?)\\\]"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"(?<!\\)\$\$(.+?)(?<!\\)\$\$"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"(?<!\\)\$(?!\$)(.+?)(?<!\\)\$"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(
                of: #"\\(mathbb|mathbf|mathrm|mathit|mathsf|mathtt|mathcal|operatorname|text)\{([^{}]+)\}"#,
                with: "$2",
                options: .regularExpression
            )
            .replacingOccurrences(of: #"\\(left|right|displaystyle|textstyle|scriptstyle|scriptscriptstyle)\b"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\\([{}\[\]()])"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"\\[,;:!]"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"[*_~#>`]"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func trimmingLeadingSpaces(_ count: Int) -> String {
        guard count > 0 else { return self }

        var remaining = count
        var index = startIndex

        while index < endIndex, remaining > 0, self[index] == " " {
            index = self.index(after: index)
            remaining -= 1
        }

        return String(self[index...])
    }
}
