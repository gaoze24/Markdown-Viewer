import AppKit
import SwiftUI
import UniformTypeIdentifiers

private enum ToolbarLayout {
    static let iconSize: CGFloat = 13
    static let iconButtonWidth: CGFloat = 30
    static let iconButtonHeight: CGFloat = 24
    static let iconButtonCornerRadius: CGFloat = 7
}

struct RootView: View {
    @ObservedObject var model: AppModel

    @AppStorage(ReaderPreferenceKey.baseFontSize) private var baseFontSize = 18.0
    @AppStorage(ReaderPreferenceKey.readingWidth) private var readingWidth = 820.0
    @AppStorage(ReaderPreferenceKey.showProgress) private var showProgress = true

    @State private var splitViewVisibility: NavigationSplitViewVisibility = .all
    @State private var isDropTargeted = false

    private var displaySettings: ReaderDisplaySettings {
        ReaderDisplaySettings(baseFontSize: baseFontSize, readingWidth: readingWidth)
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $splitViewVisibility) {
            SidebarView(model: model)
                .frame(minWidth: 250, idealWidth: 280)
                .background(AppTheme.sidebarBackground)
        } detail: {
            Group {
                if let renderedDocument = model.renderedDocument {
                    ReaderView(
                        model: model,
                        renderedDocument: renderedDocument,
                        displaySettings: displaySettings
                    )
                } else {
                    WelcomeView(
                        recentFiles: model.recentFiles,
                        errorMessage: model.loadErrorMessage,
                        openAction: model.openPanel,
                        openRecentAction: model.openRecent(_:),
                        removeRecentAction: { item in
                            withAnimation(.easeInOut(duration: 0.18)) {
                                model.removeRecent(item)
                            }
                        },
                        clearRecentFilesAction: model.confirmAndClearRecentFiles,
                        isDropTargeted: isDropTargeted
                    )
                }
            }
            .background(AppTheme.detailBackground)
        }
        .navigationTitle(model.windowTitle)
        .background(AppTheme.windowBackground.ignoresSafeArea())
        .tint(AppTheme.tint)
        .toolbarBackground(AppTheme.windowBackground, for: .windowToolbar)
        .toolbarBackground(.visible, for: .windowToolbar)
        .onDrop(of: [UTType.fileURL], isTargeted: $isDropTargeted) { providers in
            model.openDroppedProviders(providers)
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button {
                    model.openPanel()
                } label: {
                    ToolbarIconGlyph(systemName: "folder")
                }
                .buttonStyle(.plain)
                .help("Open")
                .accessibilityLabel("Open")

                Button {
                    model.reloadCurrentDocument()
                } label: {
                    ToolbarIconGlyph(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .help("Reload")
                .accessibilityLabel("Reload")
                .disabled(!model.hasDocument)
            }

            ToolbarItem(placement: .principal) {
                ToolbarTitleView(
                    title: model.windowTitle,
                    subtitle: model.subtitle
                )
            }

            ToolbarItemGroup(placement: .primaryAction) {
                if showProgress, model.hasDocument {
                    ToolbarProgressView(progress: model.scrollProgress)
                }

                ToolbarSearchField(
                    searchQuery: $model.searchQuery,
                    hasDocument: model.hasDocument,
                    focusRequestToken: model.searchFocusToken
                )

                if !model.searchQuery.isEmpty, model.hasDocument {
                    ToolbarSearchResultsView(
                        searchResultCount: model.searchResultCount,
                        currentSearchResult: model.currentSearchResult
                    )

                    ToolbarSearchNavigationView(
                        hasDocument: model.hasDocument,
                        searchQueryIsEmpty: model.searchQuery.isEmpty,
                        searchPrevious: model.searchPrevious,
                        searchNext: model.searchNext
                    )
                }
            }
        }
    }
}

private struct ToolbarTitleView: View {
    let title: String
    let subtitle: String?

    var body: some View {
        ViewThatFits(in: .horizontal) {
            fullTitleLayout
            titleLine
                .frame(minWidth: 120, idealWidth: 180, maxWidth: 220, alignment: .center)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .clipped()
    }

    @ViewBuilder
    private var fullTitleLayout: some View {
        if let subtitle {
            VStack(spacing: 1) {
                titleLine

                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .allowsTightening(true)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }
            .frame(minWidth: 210, idealWidth: 270, maxWidth: 320, alignment: .center)
        } else {
            titleLine
                .frame(minWidth: 120, idealWidth: 180, maxWidth: 220, alignment: .center)
        }
    }

    private var titleLine: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.primaryText)
            .lineLimit(1)
            .truncationMode(.tail)
            .allowsTightening(true)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
    }
}

private struct ToolbarProgressView: View {
    let progress: Double

    var body: some View {
        HStack(spacing: 7) {
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(AppTheme.divider)
                    .frame(width: 40, height: 4)

                Capsule(style: .continuous)
                    .fill(progressTint)
                    .frame(width: max(6, 40 * progress), height: 4)
            }

            Text("\(Int(progress * 100))%")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(minWidth: 82, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Reading progress")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }

    private var progressTint: Color {
        AppTheme.progressTint(for: progress)
    }
}

private struct ToolbarSearchField: View {
    @Binding var searchQuery: String
    let hasDocument: Bool
    let focusRequestToken: UUID

    var body: some View {
        NativeToolbarSearchField(
            text: $searchQuery,
            placeholder: "Search",
            isEnabled: hasDocument,
            focusRequestToken: focusRequestToken
        )
        .frame(minWidth: 132, idealWidth: 170, maxWidth: 208)
        .frame(height: 24)
    }
}

private struct NativeToolbarSearchField: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let isEnabled: Bool
    let focusRequestToken: UUID

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSSearchField {
        let searchField = NSSearchField(frame: .zero)
        searchField.delegate = context.coordinator
        searchField.placeholderString = placeholder
        searchField.sendsSearchStringImmediately = true
        searchField.sendsWholeSearchString = true
        searchField.focusRingType = .default
        searchField.lineBreakMode = .byTruncatingTail
        searchField.stringValue = text
        searchField.isEnabled = isEnabled
        return searchField
    }

    func updateNSView(_ nsView: NSSearchField, context: Context) {
        context.coordinator.parent = self

        if nsView.stringValue != text {
            nsView.stringValue = text
        }

        nsView.isEnabled = isEnabled

        if context.coordinator.lastFocusRequestToken != focusRequestToken {
            context.coordinator.lastFocusRequestToken = focusRequestToken

            DispatchQueue.main.async {
                guard isEnabled, nsView.window != nil else { return }
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }

    final class Coordinator: NSObject, NSSearchFieldDelegate {
        var parent: NativeToolbarSearchField
        var lastFocusRequestToken: UUID

        init(parent: NativeToolbarSearchField) {
            self.parent = parent
            self.lastFocusRequestToken = parent.focusRequestToken
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let searchField = obj.object as? NSSearchField else { return }
            let updatedText = searchField.stringValue

            if parent.text != updatedText {
                parent.text = updatedText
            }
        }
    }
}

private struct ToolbarSearchResultsView: View {
    let searchResultCount: Int
    let currentSearchResult: Int

    var body: some View {
        Text(searchResultCount == 0 ? "No results" : "\(currentSearchResult) / \(searchResultCount)")
            .font(.caption2.monospacedDigit())
            .foregroundStyle(AppTheme.secondaryText)
            .lineLimit(1)
    }
}

private struct ToolbarSearchNavigationView: View {
    let hasDocument: Bool
    let searchQueryIsEmpty: Bool
    let searchPrevious: () -> Void
    let searchNext: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Button {
                searchPrevious()
            } label: {
                ToolbarIconGlyph(systemName: "chevron.up")
            }
            .buttonStyle(.plain)
            .disabled(searchQueryIsEmpty || !hasDocument)

            Button {
                searchNext()
            } label: {
                ToolbarIconGlyph(systemName: "chevron.down")
            }
            .buttonStyle(.plain)
            .disabled(searchQueryIsEmpty || !hasDocument)
        }
    }
}

private struct ToolbarIconGlyph: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: ToolbarLayout.iconSize, weight: .semibold))
            .foregroundStyle(AppTheme.primaryText)
            .frame(width: ToolbarLayout.iconButtonWidth, height: ToolbarLayout.iconButtonHeight)
            .contentShape(RoundedRectangle(cornerRadius: ToolbarLayout.iconButtonCornerRadius, style: .continuous))
    }
}
