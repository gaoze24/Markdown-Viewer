import Foundation

public struct RenderedDocument: Equatable, Sendable {
    public let title: String
    public let bodyHTML: String
    public let tableOfContents: [TableOfContentsItem]

    public init(title: String, bodyHTML: String, tableOfContents: [TableOfContentsItem]) {
        self.title = title
        self.bodyHTML = bodyHTML
        self.tableOfContents = tableOfContents
    }
}
