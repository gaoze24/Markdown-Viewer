import Foundation

public final class RecentFilesStore: @unchecked Sendable {
    private let userDefaults: UserDefaults
    private let storageKey = "recentDocuments.v1"
    private let maximumCount: Int

    public init(userDefaults: UserDefaults = .standard, maximumCount: Int = 12) {
        self.userDefaults = userDefaults
        self.maximumCount = maximumCount
    }

    public func load() -> [RecentDocument] {
        guard
            let data = userDefaults.data(forKey: storageKey),
            let documents = try? JSONDecoder().decode([RecentDocument].self, from: data)
        else {
            return []
        }

        return documents.sorted { $0.lastOpenedAt > $1.lastOpenedAt }
    }

    @discardableResult
    public func record(url: URL) -> [RecentDocument] {
        let standardized = url.standardizedFileURL
        let bookmark = try? standardized.bookmarkData(options: .minimalBookmark)
        let entry = RecentDocument(
            name: standardized.lastPathComponent,
            path: standardized.path,
            bookmarkData: bookmark,
            lastOpenedAt: .now
        )

        var documents = load()
        documents.removeAll { $0.path == entry.path }
        documents.insert(entry, at: 0)
        documents = Array(documents.prefix(maximumCount))
        save(documents)
        return documents
    }

    @discardableResult
    public func remove(documentID: UUID) -> [RecentDocument] {
        var documents = load()
        documents.removeAll { $0.id == documentID }
        save(documents)
        return documents
    }

    @discardableResult
    public func clear() -> [RecentDocument] {
        userDefaults.removeObject(forKey: storageKey)
        return []
    }

    public func resolveURL(for document: RecentDocument) -> URL? {
        if let bookmarkData = document.bookmarkData {
            var stale = false
            if let resolvedURL = try? URL(
                resolvingBookmarkData: bookmarkData,
                options: .withoutUI,
                relativeTo: nil,
                bookmarkDataIsStale: &stale
            ) {
                if stale {
                    _ = record(url: resolvedURL)
                }
                return resolvedURL
            }
        }

        return URL(fileURLWithPath: document.path)
    }

    private func save(_ documents: [RecentDocument]) {
        guard let data = try? JSONEncoder().encode(documents) else { return }
        userDefaults.set(data, forKey: storageKey)
    }
}
