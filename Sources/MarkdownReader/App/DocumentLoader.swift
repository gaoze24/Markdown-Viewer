import Foundation
import ReaderCore

enum DocumentLoader {
    static func renderDocument(
        from url: URL,
        renderer: MarkdownRenderer
    ) async throws -> RenderedDocument {
        try await renderDocument(
            from: url,
            loadMarkdown: readMarkdown(from:),
            render: { markdown, sourceURL in
                renderer.render(markdown: markdown, sourceURL: sourceURL)
            }
        )
    }

    static func renderDocument(
        from url: URL,
        loadMarkdown: @escaping @Sendable (URL) throws -> String,
        render: @escaping @Sendable (String, URL) throws -> RenderedDocument
    ) async throws -> RenderedDocument {
        let task = Task.detached(priority: .userInitiated) {
            let markdown = try loadMarkdown(url)
            try Task.checkCancellation()
            let rendered = try render(markdown, url)
            try Task.checkCancellation()
            return rendered
        }

        return try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }
    }

    private static func readMarkdown(from url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        let encodings: [String.Encoding] = [.utf8, .unicode, .utf16, .utf32, .ascii]

        for encoding in encodings {
            if let value = String(data: data, encoding: encoding) {
                return value
            }
        }

        throw NSError(
            domain: "MarkdownReader",
            code: 1001,
            userInfo: [NSLocalizedDescriptionKey: "The file could not be decoded as plain text."]
        )
    }
}
