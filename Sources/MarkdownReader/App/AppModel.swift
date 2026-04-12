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

struct OutlineRowItem: Identifiable, Equatable {
    let heading: TableOfContentsItem
    let depth: Int
    let isExpanded: Bool
    let isActive: Bool
    let hasActiveDescendant: Bool

    var id: String {
        heading.id
    }

    var title: String {
        heading.title
    }

    var level: Int {
        heading.level
    }

    var hasChildren: Bool {
        heading.hasChildren
    }
}

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var renderedDocument: RenderedDocument?
    @Published private(set) var currentFileURL: URL?
    @Published private(set) var outlineRows: [OutlineRowItem] = []
    @Published private(set) var recentFiles: [RecentFileItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var loadErrorMessage: String?
    @Published private(set) var availabilityMessage: String?
    @Published var searchQuery = ""
    @Published private(set) var searchResultCount = 0
    @Published private(set) var currentSearchResult = 0
    @Published private(set) var scrollProgress = 0.0
    @Published private(set) var activeHeadingID: String?
    @Published var searchNavigationRequest: SearchNavigationRequest?
    @Published var anchorNavigationRequest: AnchorNavigationRequest?
    @Published private(set) var searchFocusToken = UUID()

    var windowTitle: String {
        renderedDocument?.title ?? currentFileURL?.lastPathComponent ?? "Markdown Reader"
    }

    var subtitle: String? {
        guard let currentFileURL else { return nil }

        let directoryPath = currentFileURL
            .deletingLastPathComponent()
            .path(percentEncoded: false)

        guard !directoryPath.isEmpty else { return nil }
        return (directoryPath as NSString).abbreviatingWithTildeInPath
    }

    var documentBaseURL: URL? {
        currentFileURL?.deletingLastPathComponent()
    }

    var hasDocument: Bool {
        renderedDocument != nil
    }

    var hasOutline: Bool {
        !outlineRows.isEmpty
    }

    var sidebarListIdentity: String {
        guard hasDocument, let currentFileURL else {
            return "recents-mode"
        }

        return "outline-mode-\(Self.documentKey(for: currentFileURL))"
    }

    var hasExpandableOutlineItems: Bool {
        renderedDocument?.tableOfContents.contains { $0.hasChildren } == true
    }

    private let renderer = MarkdownRenderer()
    private let recentStore = RecentFilesStore()
    private let watcher = FileWatcher()
    private let scrollProgressDeltaThreshold = 0.0025
    private var loadTask: Task<Void, Never>?
    private var pendingBootstrap = false
    private var outlineExpandedIDsByDocument: [String: Set<String>] = [:]
    private var outlineParentByID: [String: String] = [:]

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
        activeHeadingID = heading.id
        let didExpandAncestors = expandAncestors(of: heading.id)
        if didExpandAncestors {
            refreshOutlineRows()
        } else {
            refreshOutlineHighlightState()
        }
        anchorNavigationRequest = AnchorNavigationRequest(anchor: heading.id)
    }

    func toggleOutlineExpansion(for heading: TableOfContentsItem) {
        guard heading.hasChildren else { return }
        var expandedIDs = currentOutlineExpandedIDs()
        if expandedIDs.contains(heading.id) {
            expandedIDs.remove(heading.id)
        } else {
            expandedIDs.insert(heading.id)
        }
        persistOutlineExpandedIDs(expandedIDs)
        refreshOutlineRows()
    }

    func expandAllOutlineItems() {
        guard let renderedDocument else { return }
        persistOutlineExpandedIDs(Self.expandableOutlineIDs(in: renderedDocument.tableOfContents))
        refreshOutlineRows()
    }

    func collapseAllOutlineItems() {
        persistOutlineExpandedIDs(Set<String>())
        refreshOutlineRows()
    }

    func updateSearchResults(count: Int, currentIndex: Int) {
        searchResultCount = count
        currentSearchResult = currentIndex
    }

    func updateScrollProgress(_ progress: Double) {
        let clampedProgress = min(max(progress, 0), 1)
        if abs(clampedProgress - scrollProgress) < scrollProgressDeltaThreshold,
           clampedProgress != 0,
           clampedProgress != 1 {
            return
        }

        scrollProgress = clampedProgress
    }

    func updateActiveHeading(_ headingID: String?) {
        guard headingID != activeHeadingID else { return }
        activeHeadingID = headingID
        let didExpandAncestors = expandAncestors(of: headingID)

        if didExpandAncestors {
            refreshOutlineRows()
        } else {
            refreshOutlineHighlightState()
        }
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
                self.configureOutlineState(for: rendered, documentURL: standardized)
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

    private func configureOutlineState(for renderedDocument: RenderedDocument, documentURL: URL) {
        outlineParentByID = Self.outlineParentLookup(for: renderedDocument.tableOfContents)

        let documentKey = Self.documentKey(for: documentURL)
        let defaultExpandedIDs = Self.defaultExpandedOutlineIDs(in: renderedDocument.tableOfContents)
        let sanitizedExpandedIDs = outlineExpandedIDsByDocument[documentKey, default: defaultExpandedIDs]
            .intersection(Self.expandableOutlineIDs(in: renderedDocument.tableOfContents))

        outlineExpandedIDsByDocument[documentKey] = sanitizedExpandedIDs
        activeHeadingID = renderedDocument.tableOfContents.first?.id
        expandAncestors(of: activeHeadingID)
        refreshOutlineRows()
    }

    private func refreshOutlineRows() {
        guard let renderedDocument else {
            outlineRows = []
            outlineParentByID = [:]
            return
        }

        let activePath = Set(ancestorIDs(for: activeHeadingID) + (activeHeadingID.map { [$0] } ?? []))
        outlineRows = Self.makeOutlineRows(
            from: renderedDocument.tableOfContents,
            expandedIDs: currentOutlineExpandedIDs(),
            activeHeadingID: activeHeadingID,
            activePath: activePath
        )
    }

    private func refreshOutlineHighlightState() {
        guard !outlineRows.isEmpty else {
            refreshOutlineRows()
            return
        }

        let activePath = Set(ancestorIDs(for: activeHeadingID) + (activeHeadingID.map { [$0] } ?? []))
        var hasChanges = false

        let updatedRows = outlineRows.map { row in
            let isActive = row.heading.id == activeHeadingID
            let hasActiveDescendant = row.heading.id != activeHeadingID && activePath.contains(row.heading.id)

            if isActive == row.isActive, hasActiveDescendant == row.hasActiveDescendant {
                return row
            }

            hasChanges = true
            return OutlineRowItem(
                heading: row.heading,
                depth: row.depth,
                isExpanded: row.isExpanded,
                isActive: isActive,
                hasActiveDescendant: hasActiveDescendant
            )
        }

        if hasChanges {
            outlineRows = updatedRows
        }
    }

    private func currentOutlineExpandedIDs() -> Set<String> {
        guard let currentFileURL else { return [] }
        return outlineExpandedIDsByDocument[Self.documentKey(for: currentFileURL), default: []]
    }

    private func persistOutlineExpandedIDs(_ expandedIDs: Set<String>) {
        guard let currentFileURL else { return }
        let documentKey = Self.documentKey(for: currentFileURL)
        outlineExpandedIDsByDocument[documentKey] = expandedIDs
    }

    @discardableResult
    private func expandAncestors(of headingID: String?) -> Bool {
        guard let headingID else { return false }

        let ancestorIDs = ancestorIDs(for: headingID)
        guard !ancestorIDs.isEmpty else { return false }

        var expandedIDs = currentOutlineExpandedIDs()
        let previousCount = expandedIDs.count
        expandedIDs.formUnion(ancestorIDs)
        guard expandedIDs.count != previousCount else { return false }
        persistOutlineExpandedIDs(expandedIDs)
        return true
    }

    private func ancestorIDs(for headingID: String?) -> [String] {
        guard let headingID else { return [] }

        var ancestors: [String] = []
        var cursor = outlineParentByID[headingID]

        while let parentID = cursor {
            ancestors.append(parentID)
            cursor = outlineParentByID[parentID]
        }

        return ancestors
    }

    private static func makeOutlineRows(
        from headings: [TableOfContentsItem],
        expandedIDs: Set<String>,
        activeHeadingID: String?,
        activePath: Set<String>,
        depth: Int = 0
    ) -> [OutlineRowItem] {
        headings.flatMap { heading -> [OutlineRowItem] in
            let isExpanded = heading.hasChildren && expandedIDs.contains(heading.id)
            let row = OutlineRowItem(
                heading: heading,
                depth: depth,
                isExpanded: isExpanded,
                isActive: heading.id == activeHeadingID,
                hasActiveDescendant: heading.id != activeHeadingID && activePath.contains(heading.id)
            )

            guard heading.hasChildren, isExpanded else {
                return [row]
            }

            return [row] + makeOutlineRows(
                from: heading.children,
                expandedIDs: expandedIDs,
                activeHeadingID: activeHeadingID,
                activePath: activePath,
                depth: depth + 1
            )
        }
    }

    private static func outlineParentLookup(for headings: [TableOfContentsItem]) -> [String: String] {
        var lookup: [String: String] = [:]

        func walk(_ items: [TableOfContentsItem], parentID: String?) {
            for item in items {
                if let parentID {
                    lookup[item.id] = parentID
                }
                walk(item.children, parentID: item.id)
            }
        }

        walk(headings, parentID: nil)
        return lookup
    }

    private static func expandableOutlineIDs(in headings: [TableOfContentsItem]) -> Set<String> {
        Set(headings.flatMap { heading -> [String] in
            let ownID = heading.hasChildren ? [heading.id] : []
            return ownID + Array(expandableOutlineIDs(in: heading.children))
        })
    }

    private static func defaultExpandedOutlineIDs(in headings: [TableOfContentsItem]) -> Set<String> {
        Set(headings.flatMap { heading -> [String] in
            let ownID = heading.hasChildren && heading.level <= 2 ? [heading.id] : []
            return ownID + Array(defaultExpandedOutlineIDs(in: heading.children))
        })
    }

    private static func documentKey(for url: URL) -> String {
        url.standardizedFileURL.path
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
