import Foundation

extension String {
    func htmlEscaped() -> String {
        var value = self
        let replacements = [
            "&": "&amp;",
            "<": "&lt;",
            ">": "&gt;",
            "\"": "&quot;",
            "'": "&#39;"
        ]

        for (character, entity) in replacements {
            value = value.replacingOccurrences(of: character, with: entity)
        }

        return value
    }

    func removingMarkdownArtifacts() -> String {
        self
            .replacingOccurrences(of: #"\!\[([^\]]*)\]\([^)]+\)"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"\[([^\]]+)\]\([^)]+\)"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"\[\^([^\]]+)\]"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"`([^`]+)`"#, with: "$1", options: .regularExpression)
            .replacingOccurrences(of: #"[*_~#>`]"#, with: "", options: .regularExpression)
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
