import AppKit
import Foundation
import ReaderCore
import UniformTypeIdentifiers

struct ReaderDisplaySettings: Equatable, Sendable {
    let baseFontSize: Double
    let readingWidth: Double
}

struct RecentFileItem: Identifiable, Equatable {
    let id: UUID
    let name: String
    let path: String
    let url: URL
    let isAvailable: Bool
}

enum SearchDirection: Equatable {
    case next
    case previous
}

struct SearchNavigationRequest: Equatable {
    let id = UUID()
    let direction: SearchDirection
}

struct AnchorNavigationRequest: Equatable {
    let id = UUID()
    let anchor: String
}

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var renderedDocument: RenderedDocument?
    @Published private(set) var currentFileURL: URL?
    @Published private(set) var recentFiles: [RecentFileItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var loadErrorMessage: String?
    @Published private(set) var availabilityMessage: String?
    @Published var searchQuery = ""
    @Published private(set) var searchResultCount = 0
    @Published private(set) var currentSearchResult = 0
    @Published private(set) var scrollProgress = 0.0
    @Published var searchNavigationRequest: SearchNavigationRequest?
    @Published var anchorNavigationRequest: AnchorNavigationRequest?
    @Published private(set) var searchFocusToken = UUID()

    var windowTitle: String {
        renderedDocument?.title ?? currentFileURL?.lastPathComponent ?? "Markdown Reader"
    }

    var subtitle: String? {
        currentFileURL?.path(percentEncoded: false)
    }

    var documentBaseURL: URL? {
        currentFileURL?.deletingLastPathComponent()
    }

    var hasDocument: Bool {
        renderedDocument != nil
    }

    private let renderer = MarkdownRenderer()
    private let recentStore = RecentFilesStore()
    private let watcher = FileWatcher()
    private var loadTask: Task<Void, Never>?
    private var pendingBootstrap = false

    func bootstrapIfNeeded() {
        guard !pendingBootstrap else { return }
        pendingBootstrap = true
        refreshRecentFiles()
        openLaunchArgumentIfPresent()
    }

    func requestSearchFocus() {
        searchFocusToken = UUID()
    }

    func searchNext() {
        guard !searchQuery.isEmpty else { return }
        searchNavigationRequest = SearchNavigationRequest(direction: .next)
    }

    func searchPrevious() {
        guard !searchQuery.isEmpty else { return }
        searchNavigationRequest = SearchNavigationRequest(direction: .previous)
    }

    func jumpToHeading(_ heading: TableOfContentsItem) {
        anchorNavigationRequest = AnchorNavigationRequest(anchor: heading.id)
    }

    func updateSearchResults(count: Int, currentIndex: Int) {
        searchResultCount = count
        currentSearchResult = currentIndex
    }

    func updateScrollProgress(_ progress: Double) {
        scrollProgress = min(max(progress, 0), 1)
    }

    func openPanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = Self.supportedTypes
        panel.prompt = "Open"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        open(url: url)
    }

    func openDroppedProviders(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) else {
            return false
        }

        provider.loadDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { data, _ in
            guard
                let data,
                let path = String(data: data, encoding: .utf8),
                let url = URL(string: path)
            else {
                return
            }

            Task { @MainActor in
                self.open(url: url)
            }
        }

        return true
    }

    func openRecent(_ item: RecentFileItem) {
        guard item.isAvailable else {
            availabilityMessage = "That document is no longer available at its last known location."
            return
        }

        open(url: item.url)
    }

    func handleExternalOpen(urls: [URL]) {
        guard let url = urls.first(where: { Self.isSupportedMarkdownURL($0) }) else { return }
        open(url: url)
    }

    func reloadCurrentDocument() {
        guard let currentFileURL else { return }
        open(url: currentFileURL, addToRecentFiles: false)
    }

    func removeRecent(_ item: RecentFileItem) {
        recentStore.remove(documentID: item.id)
        refreshRecentFiles()
    }

    func clearRecentFiles() {
        recentStore.clear()
        refreshRecentFiles()
    }

    func confirmAndClearRecentFiles() {
        guard !recentFiles.isEmpty else { return }

        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Clear Recent Files?"
        alert.informativeText = "This only clears the recent files history. Files on disk will not be deleted, moved to Trash, or modified."
        alert.addButton(withTitle: "Clear Recent Files")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            clearRecentFiles()
        }
    }

    func open(url: URL, addToRecentFiles: Bool = true) {
        let standardized = url.standardizedFileURL
        guard Self.isSupportedMarkdownURL(standardized) else {
            loadErrorMessage = "This app reads Markdown files. Try opening a .md or .markdown document."
            return
        }

        loadErrorMessage = nil
        availabilityMessage = nil
        currentFileURL = standardized
        isLoading = true
        searchQuery = ""
        searchResultCount = 0
        currentSearchResult = 0
        scrollProgress = 0

        if addToRecentFiles {
            recentStore.record(url: standardized)
            refreshRecentFiles()
        }

        startWatching(url: standardized)
        loadTask?.cancel()
        loadTask = Task { [renderer] in
            do {
                let markdown = try Self.readMarkdown(from: standardized)
                let rendered = await Task.detached(priority: .userInitiated) {
                    renderer.render(markdown: markdown, sourceURL: standardized)
                }.value

                guard !Task.isCancelled else { return }
                self.renderedDocument = rendered
                self.isLoading = false
            } catch {
                guard !Task.isCancelled else { return }
                self.isLoading = false
                self.loadErrorMessage = error.localizedDescription
            }
        }
    }

    private func startWatching(url: URL) {
        watcher.start(url: url) { [weak self] in
            Task { @MainActor in
                self?.reloadAfterExternalChange()
            }
        }
    }

    private func reloadAfterExternalChange() {
        guard let currentFileURL else { return }
        guard FileManager.default.fileExists(atPath: currentFileURL.path) else {
            availabilityMessage = "This file was moved or deleted. The last rendered view is still shown."
            watcher.stop()
            return
        }

        availabilityMessage = "Reloaded after an external file change."
        open(url: currentFileURL, addToRecentFiles: false)
    }

    private func refreshRecentFiles() {
        recentFiles = recentStore.load().map { document in
            let resolvedURL = recentStore.resolveURL(for: document) ?? URL(fileURLWithPath: document.path)
            let isAvailable = FileManager.default.fileExists(atPath: resolvedURL.path)
            return RecentFileItem(
                id: document.id,
                name: document.name,
                path: resolvedURL.path(percentEncoded: false),
                url: resolvedURL,
                isAvailable: isAvailable
            )
        }
    }

    private func openLaunchArgumentIfPresent() {
        let candidates = CommandLine.arguments.dropFirst().compactMap { argument -> URL? in
            let expanded = NSString(string: argument).expandingTildeInPath
            let url = URL(fileURLWithPath: expanded)
            return FileManager.default.fileExists(atPath: url.path) ? url : nil
        }

        if let url = candidates.first(where: { Self.isSupportedMarkdownURL($0) }) {
            open(url: url)
        }
    }

    nonisolated private static func readMarkdown(from url: URL) throws -> String {
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

    nonisolated private static func isSupportedMarkdownURL(_ url: URL) -> Bool {
        let extensionSet = Set(["md", "markdown", "mdown", "mkd", "mkdn"])
        return extensionSet.contains(url.pathExtension.lowercased())
    }

    private static let supportedTypes: [UTType] = [
        .init(filenameExtension: "md"),
        .init(filenameExtension: "markdown"),
        .init(filenameExtension: "mdown"),
        .init(filenameExtension: "mkd"),
        .init(filenameExtension: "mkdn")
    ].compactMap { $0 }
}
