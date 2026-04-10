import Foundation

public struct TableOfContentsItem: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: String
    public let level: Int
    public let title: String

    public init(id: String, level: Int, title: String) {
        self.id = id
        self.level = level
        self.title = title
    }
}
