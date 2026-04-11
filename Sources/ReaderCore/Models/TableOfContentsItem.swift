import Foundation

public struct TableOfContentsItem: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: String
    public let level: Int
    public let title: String
    public let children: [TableOfContentsItem]

    public init(id: String, level: Int, title: String, children: [TableOfContentsItem] = []) {
        self.id = id
        self.level = level
        self.title = title
        self.children = children
    }

    public var hasChildren: Bool {
        !children.isEmpty
    }

    public func flattened() -> [TableOfContentsItem] {
        [self] + children.flatMap { $0.flattened() }
    }
}
