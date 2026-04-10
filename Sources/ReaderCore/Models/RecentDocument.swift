import Foundation

public struct RecentDocument: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public let name: String
    public let path: String
    public let bookmarkData: Data?
    public let lastOpenedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        path: String,
        bookmarkData: Data?,
        lastOpenedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.bookmarkData = bookmarkData
        self.lastOpenedAt = lastOpenedAt
    }
}
