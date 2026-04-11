import Foundation
import ReaderCore
import XCTest

final class RecentFilesStoreTests: XCTestCase {
    private var userDefaults: UserDefaults!
    private var suiteName: String!
    private var temporaryDirectoryURL: URL!

    override func setUp() {
        super.setUp()
        suiteName = "RecentFilesStoreTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        userDefaults.removePersistentDomain(forName: suiteName)

        temporaryDirectoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: temporaryDirectoryURL, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let suiteName {
            userDefaults?.removePersistentDomain(forName: suiteName)
        }

        if let temporaryDirectoryURL {
            try? FileManager.default.removeItem(at: temporaryDirectoryURL)
        }

        userDefaults = nil
        suiteName = nil
        temporaryDirectoryURL = nil
        super.tearDown()
    }

    func testRemoveOnlyClearsRecentHistoryEntry() throws {
        let fileURL = try makeMarkdownFile(named: "Keep Me.md")
        let store = makeStore()

        _ = store.record(url: fileURL)
        let entry = try XCTUnwrap(store.load().first)

        _ = store.remove(documentID: entry.id)

        XCTAssertTrue(store.load().isEmpty)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertTrue(makeStore().load().isEmpty)
    }

    func testRemovingMissingEntryStillWorks() throws {
        let fileURL = try makeMarkdownFile(named: "Missing Later.md")
        let store = makeStore()

        _ = store.record(url: fileURL)
        let entry = try XCTUnwrap(store.load().first)
        try FileManager.default.removeItem(at: fileURL)

        _ = store.remove(documentID: entry.id)

        XCTAssertTrue(store.load().isEmpty)
    }

    func testClearedEntriesCanAppearAgainWhenFileIsReopened() throws {
        let fileURL = try makeMarkdownFile(named: "Reopen Me.md")
        let store = makeStore()

        _ = store.record(url: fileURL)
        _ = store.clear()

        XCTAssertTrue(store.load().isEmpty)

        _ = store.record(url: fileURL)
        let documents = store.load()

        XCTAssertEqual(documents.count, 1)
        XCTAssertEqual(documents[0].path, fileURL.standardizedFileURL.path)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }

    private func makeStore() -> RecentFilesStore {
        RecentFilesStore(userDefaults: userDefaults, maximumCount: 12)
    }

    private func makeMarkdownFile(named fileName: String) throws -> URL {
        let fileURL = temporaryDirectoryURL.appendingPathComponent(fileName)
        try Data("# Test\n".utf8).write(to: fileURL)
        return fileURL
    }
}
