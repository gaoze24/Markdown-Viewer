import AppKit
import Combine
import Foundation
import ReaderCore
import UniformTypeIdentifiers

struct ReaderDisplaySettings: Equatable, Sendable {
    let baseFontSize: Double
    let readingWidth: Double
    let colorTheme: ReaderColorTheme
}

struct RecentFileItem: Identifiable, Equatable {
    let id: UUID
    let name: String
    let path: String
    let url: URL
    let isAvailable: Bool

    /// Where the file lives, for display next to `name`. Shows the containing
    /// folder abbreviated with `~` — the full `path` repeats the file name and
    /// is too long to read at a glance.
    var displayLocation: String {
        RecentFileLocationFormatter.location(forPath: path)
    }
}

enum RecentFileLocationFormatter {
    static func location(forPath path: String) -> String {
        let directory = (path as NSString).deletingLastPathComponent
        guard !directory.isEmpty else { return path }
        return (directory as NSString).abbreviatingWithTildeInPath
    }
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

enum OutlineRowBuilder {
    static func makeRows(
        from headings: [TableOfContentsItem],
        expandedIDs: Set<String>
    ) -> [OutlineRowItem] {
        var rows: [OutlineRowItem] = []
        rows.reserveCapacity(headings.count)

        var stack = headings.reversed().map { (heading: $0, depth: 0) }
        while let item = stack.popLast() {
            let isExpanded = item.heading.hasChildren && expandedIDs.contains(item.heading.id)
            rows.append(
                OutlineRowItem(
                    heading: item.heading,
                    depth: item.depth,
                    isExpanded: isExpanded
                )
            )

            guard item.heading.hasChildren, isExpanded else { continue }
            for child in item.heading.children.reversed() {
                stack.append((heading: child, depth: item.depth + 1))
            }
        }

        return rows
    }
}

enum OutlineTreeBuilder {
    static func parentLookup(for headings: [TableOfContentsItem]) -> [String: String] {
        var lookup: [String: String] = [:]
        var stack = headings.reversed().map { (heading: $0, parentID: Optional<String>.none) }

        while let item = stack.popLast() {
            if let parentID = item.parentID {
                lookup[item.heading.id] = parentID
            }

            for child in item.heading.children.reversed() {
                stack.append((heading: child, parentID: item.heading.id))
            }
        }

        return lookup
    }

    static func expandableIDs(in headings: [TableOfContentsItem]) -> Set<String> {
        var ids: Set<String> = []
        var stack = Array(headings.reversed())

        while let heading = stack.popLast() {
            if heading.hasChildren {
                ids.insert(heading.id)
            }

            stack.append(contentsOf: heading.children.reversed())
        }

        return ids
    }

    static func defaultExpandedIDs(in headings: [TableOfContentsItem]) -> Set<String> {
        var ids: Set<String> = []
        var stack = Array(headings.reversed())

        while let heading = stack.popLast() {
            if heading.hasChildren && heading.level <= 2 {
                ids.insert(heading.id)
            }

            stack.append(contentsOf: heading.children.reversed())
        }

        return ids
    }
}

@MainActor
final class ReaderProgressState: ObservableObject {
    @Published private(set) var scrollProgress = 0.0

    private var lastReportedScrollPercent: Int = -1

    func updateScrollProgress(_ progress: Double) {
        let clamped = min(max(progress, 0), 1)
        let percent = Int((clamped * 100).rounded())
        guard percent != lastReportedScrollPercent else { return }
        lastReportedScrollPercent = percent
        scrollProgress = Double(percent) / 100
    }

    func reset() {
        lastReportedScrollPercent = -1
        scrollProgress = 0
    }
}

@MainActor
final class ReaderViewportState: ObservableObject {
    @Published private(set) var activeHeadingID: String?
    @Published private(set) var activePathIDs: Set<String> = []

    private var pendingProgrammaticHeadingID: String?
    private var programmaticHeadingUnlockTask: Task<Void, Never>?

    func requestProgrammaticNavigation(to headingID: String, ancestorIDs: [String]) {
        pendingProgrammaticHeadingID = headingID
        setActiveHeading(headingID, ancestorIDs: ancestorIDs)
        programmaticHeadingUnlockTask?.cancel()
        programmaticHeadingUnlockTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self, self.pendingProgrammaticHeadingID == headingID else { return }
                self.clearProgrammaticNavigationLock()
            }
        }
    }

    func acceptObservedHeading(_ headingID: String?, ancestorIDs: [String]) -> Bool {
        if let pendingProgrammaticHeadingID {
            if headingID == pendingProgrammaticHeadingID {
                clearProgrammaticNavigationLock()
            } else {
                return false
            }
        }

        return setActiveHeading(headingID, ancestorIDs: ancestorIDs)
    }

    func reset() {
        clearProgrammaticNavigationLock()
        _ = setActiveHeading(nil, ancestorIDs: [])
    }

    @discardableResult
    func setActiveHeading(_ headingID: String?, ancestorIDs: [String]) -> Bool {
        let nextPathIDs = Set(ancestorIDs + (headingID.map { [$0] } ?? []))
        guard headingID != activeHeadingID || nextPathIDs != activePathIDs else { return false }
        activeHeadingID = headingID
        activePathIDs = nextPathIDs
        return true
    }

    private func clearProgrammaticNavigationLock() {
        pendingProgrammaticHeadingID = nil
        programmaticHeadingUnlockTask?.cancel()
        programmaticHeadingUnlockTask = nil
    }
}

@MainActor
final class ReaderSearchState: ObservableObject {
    private static let searchDebounceNanoseconds: UInt64 = 140_000_000

    @Published var searchQuery = ""
    @Published private(set) var debouncedSearchQuery = ""
    @Published private(set) var searchResultCount = 0
    @Published private(set) var currentSearchResult = 0
    @Published var searchNavigationRequest: SearchNavigationRequest?
    @Published var anchorNavigationRequest: AnchorNavigationRequest?
    @Published private(set) var searchFocusToken = UUID()

    private var searchDebounceTask: Task<Void, Never>?
    private var lastSearchQueryForDebounce = ""

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

    func updateSearchResults(count: Int, currentIndex: Int) {
        searchResultCount = count
        currentSearchResult = currentIndex
    }

    func requestAnchorNavigation(_ anchor: String) {
        anchorNavigationRequest = AnchorNavigationRequest(anchor: anchor)
    }

    func scheduleSearchDebounce(for nextValue: String) {
        guard nextValue != lastSearchQueryForDebounce else { return }
        lastSearchQueryForDebounce = nextValue

        searchDebounceTask?.cancel()

        if nextValue.isEmpty {
            debouncedSearchQuery = ""
            return
        }

        searchDebounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: ReaderSearchState.searchDebounceNanoseconds)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self else { return }
                guard self.searchQuery == nextValue else { return }
                self.debouncedSearchQuery = nextValue
            }
        }
    }

    func reset() {
        searchDebounceTask?.cancel()
        lastSearchQueryForDebounce = ""
        searchQuery = ""
        debouncedSearchQuery = ""
        searchResultCount = 0
        currentSearchResult = 0
        searchNavigationRequest = nil
        anchorNavigationRequest = nil
    }
}

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var renderedDocument: RenderedDocument?
    @Published private(set) var currentFileURL: URL?
    @Published private(set) var outlineRows: [OutlineRowItem] = []
    /// Bumps when outline structure (set of rows / expansion) changes, but not
    /// when only highlight state shifts. Used to drive list animations without
    /// re-allocating an `[String]` of row ids on every body evaluation.
    @Published private(set) var outlineStructureToken: Int = 0
    @Published private(set) var recentFiles: [RecentFileItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var loadErrorMessage: String?
    @Published private(set) var availabilityMessage: String?

    let viewportState = ReaderViewportState()
    let progressState = ReaderProgressState()
    let searchState = ReaderSearchState()

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
        searchState.requestSearchFocus()
    }

    func searchNext() {
        searchState.searchNext()
    }

    func searchPrevious() {
        searchState.searchPrevious()
    }

    func jumpToHeading(_ heading: TableOfContentsItem) {
        let ancestorIDs = ancestorIDs(for: heading.id)
        viewportState.requestProgrammaticNavigation(to: heading.id, ancestorIDs: ancestorIDs)
        let didExpandAncestors = expandAncestors(of: heading.id)
        if didExpandAncestors {
            refreshOutlineRows()
        }
        searchState.requestAnchorNavigation(heading.id)
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
        persistOutlineExpandedIDs(OutlineTreeBuilder.expandableIDs(in: renderedDocument.tableOfContents))
        refreshOutlineRows()
    }

    func collapseAllOutlineItems() {
        persistOutlineExpandedIDs(Set<String>())
        refreshOutlineRows()
    }

    func updateSearchResults(count: Int, currentIndex: Int) {
        searchState.updateSearchResults(count: count, currentIndex: currentIndex)
    }

    func updateScrollProgress(_ progress: Double) {
        progressState.updateScrollProgress(progress)
    }

    func updateSearchQuery(_ nextValue: String) {
        guard searchState.searchQuery != nextValue else { return }
        searchState.searchQuery = nextValue
        searchState.scheduleSearchDebounce(for: nextValue)
    }

    func updateActiveHeading(_ headingID: String?) {
        let ancestorIDs = ancestorIDs(for: headingID)
        guard viewportState.acceptObservedHeading(headingID, ancestorIDs: ancestorIDs) else { return }

        if expandAncestors(of: headingID) {
            refreshOutlineRows()
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

    func returnToLibrary() {
        loadTask?.cancel()
        loadTask = nil
        watcher.stop()
        renderedDocument = nil
        currentFileURL = nil
        isLoading = false
        loadErrorMessage = nil
        availabilityMessage = nil
        searchState.reset()
        progressState.reset()
        viewportState.reset()
        refreshOutlineRows()
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
        searchState.reset()
        progressState.reset()
        viewportState.reset()

        if addToRecentFiles {
            recentStore.record(url: standardized)
            refreshRecentFiles()
        }

        startWatching(url: standardized)
        loadTask?.cancel()
        loadTask = Task { [renderer] in
            do {
                let rendered = try await DocumentLoader.renderDocument(from: standardized, renderer: renderer)

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
        outlineParentByID = OutlineTreeBuilder.parentLookup(for: renderedDocument.tableOfContents)

        let documentKey = Self.documentKey(for: documentURL)
        let defaultExpandedIDs = OutlineTreeBuilder.defaultExpandedIDs(in: renderedDocument.tableOfContents)
        let sanitizedExpandedIDs = outlineExpandedIDsByDocument[documentKey, default: defaultExpandedIDs]
            .intersection(OutlineTreeBuilder.expandableIDs(in: renderedDocument.tableOfContents))

        outlineExpandedIDsByDocument[documentKey] = sanitizedExpandedIDs
        let initialHeadingID = renderedDocument.tableOfContents.first?.id
        let initialAncestorIDs = ancestorIDs(for: initialHeadingID)
        viewportState.setActiveHeading(initialHeadingID, ancestorIDs: initialAncestorIDs)
        expandAncestors(of: initialHeadingID)
        refreshOutlineRows()
    }

    private func refreshOutlineRows() {
        guard let renderedDocument else {
            outlineRows = []
            outlineParentByID = [:]
            outlineStructureToken &+= 1
            return
        }

        outlineRows = OutlineRowBuilder.makeRows(
            from: renderedDocument.tableOfContents,
            expandedIDs: currentOutlineExpandedIDs()
        )
        outlineStructureToken &+= 1
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
