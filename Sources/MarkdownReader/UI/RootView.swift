import AppKit
import SwiftUI
import UniformTypeIdentifiers

private enum ToolbarLayout {
    static let iconSize: CGFloat = 14
    static let iconButtonWidth: CGFloat = 36
    static let iconButtonHeight: CGFloat = 30
    /// Holds the hover fill inside the capsule the toolbar draws around a
    /// button group. A squarer, full-bleed fill overlaps that capsule's
    /// rounded ends and the seam between grouped buttons.
    static let iconButtonFillInset: CGFloat = 2
}

struct RootView: View {
    @ObservedObject var model: AppModel
    @ObservedObject private var searchState: ReaderSearchState

    @AppStorage(ReaderPreferenceKey.baseFontSize) private var baseFontSize = 18.0
    @AppStorage(ReaderPreferenceKey.readingWidth) private var readingWidth = 820.0
    @AppStorage(ReaderPreferenceKey.showProgress) private var showProgress = true
    @AppStorage(ReaderPreferenceKey.colorTheme) private var colorTheme = ReaderColorTheme.auto

    @State private var splitViewVisibility: NavigationSplitViewVisibility = .all
    @State private var isDropTargeted = false

    init(model: AppModel) {
        self.model = model
        self._searchState = ObservedObject(wrappedValue: model.searchState)
    }

    private var displaySettings: ReaderDisplaySettings {
        ReaderDisplaySettings(baseFontSize: baseFontSize, readingWidth: readingWidth, colorTheme: colorTheme)
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $splitViewVisibility) {
            SidebarView(model: model, viewportState: model.viewportState)
                .background(AppTheme.sidebarBackground)
        } detail: {
            ZStack {
                if let renderedDocument = model.renderedDocument {
                    ReaderView(
                        model: model,
                        searchState: searchState,
                        renderedDocument: renderedDocument,
                        displaySettings: displaySettings,
                        showProgress: showProgress
                    )
                    .id(detailPageIdentity)
                    .transition(.opacity)
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
                    .id(detailPageIdentity)
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: RootDetailPagePresentation.transitionAnimationDuration), value: detailPageIdentity)
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
                if ReaderReturnPresentation.isVisible(hasDocument: model.hasDocument) {
                    Button {
                        model.returnToLibrary()
                    } label: {
                        ToolbarIconGlyph(systemName: "chevron.left")
                    }
                    .buttonStyle(ToolbarIconButtonStyle())
                    .help("Return to Library")
                    .accessibilityLabel("Return to Library")
                }

                Button {
                    model.openPanel()
                } label: {
                    ToolbarIconGlyph(systemName: "folder")
                }
                .buttonStyle(ToolbarIconButtonStyle())
                .help("Open")
                .accessibilityLabel("Open")

                Button {
                    model.reloadCurrentDocument()
                } label: {
                    ToolbarIconGlyph(systemName: "arrow.clockwise")
                }
                .buttonStyle(ToolbarIconButtonStyle())
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
                if model.hasDocument {
                    ToolbarDisplaySettingsButton(
                        baseFontSize: $baseFontSize,
                        readingWidth: $readingWidth,
                        colorTheme: $colorTheme
                    )
                }

                ToolbarSearchField(
                    searchQuery: Binding(
                        get: { searchState.searchQuery },
                        set: { model.updateSearchQuery($0) }
                    ),
                    hasDocument: model.hasDocument,
                    focusRequestToken: searchState.searchFocusToken
                )

                if !searchState.searchQuery.isEmpty, model.hasDocument {
                    ToolbarSearchResultsView(
                        searchResultCount: searchState.searchResultCount,
                        currentSearchResult: searchState.currentSearchResult
                    )

                    ToolbarSearchNavigationView(
                        hasDocument: model.hasDocument,
                        searchQueryIsEmpty: searchState.searchQuery.isEmpty,
                        searchPrevious: model.searchPrevious,
                        searchNext: model.searchNext
                    )
                }
            }
        }
    }

    private var detailPageIdentity: String {
        RootDetailPagePresentation.pageIdentity(
            hasDocument: model.hasDocument,
            documentPath: model.currentFileURL?.path
        )
    }
}

enum RootDetailPagePresentation {
    static let transitionAnimationDuration = 0.2

    static func pageIdentity(hasDocument: Bool, documentPath: String?) -> String {
        guard hasDocument else {
            return "library"
        }

        guard let documentPath else {
            return "reader"
        }

        return "reader:\(documentPath)"
    }
}

private struct ToolbarTitleView: View {
    let title: String
    let subtitle: String?

    @State private var isShowingSubtitlePopover = false

    var body: some View {
        ViewThatFits(in: .horizontal) {
            fullTitleLayout
            titleLine
                .frame(minWidth: 120, idealWidth: 180, maxWidth: 220, alignment: .center)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .clipped()
    }

    @ViewBuilder
    private var fullTitleLayout: some View {
        if let subtitle {
            VStack(spacing: 1) {
                titleLine

                subtitleLine(subtitle)
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

    private func subtitleLine(_ subtitle: String) -> some View {
        Text(subtitle)
            .font(.caption2)
            .foregroundStyle(AppTheme.secondaryText)
            .lineLimit(1)
            .truncationMode(.middle)
            .allowsTightening(true)
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            .contentShape(Rectangle())
            .onHover { hovering in
                isShowingSubtitlePopover = hovering && ToolbarTitlePresentation.subtitlePopoverText(for: subtitle) != nil
            }
            .popover(isPresented: $isShowingSubtitlePopover, arrowEdge: .bottom) {
                if let popoverText = ToolbarTitlePresentation.subtitlePopoverText(for: subtitle) {
                    ToolbarSubtitlePopover(text: popoverText)
                }
            }
    }
}

enum ToolbarTitlePresentation {
    static func subtitlePopoverText(for subtitle: String?) -> String? {
        guard let subtitle, !subtitle.isEmpty else {
            return nil
        }

        return subtitle
    }
}

private struct ToolbarSubtitlePopover: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(AppTheme.primaryText)
            .textSelection(.enabled)
            .lineLimit(3)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(minWidth: 260, idealWidth: 360, maxWidth: 480, alignment: .leading)
            .background(AppTheme.elevatedSurface)
    }
}

private struct ToolbarDisplaySettingsButton: View {
    @Binding var baseFontSize: Double
    @Binding var readingWidth: Double
    @Binding var colorTheme: ReaderColorTheme

    @State private var isShowingPopover = false

    var body: some View {
        Button {
            isShowingPopover = true
        } label: {
            ToolbarIconGlyph(systemName: "textformat.size")
        }
        .buttonStyle(ToolbarIconButtonStyle())
        .help("Display Settings")
        .accessibilityLabel("Display Settings")
        .popover(isPresented: $isShowingPopover, arrowEdge: .bottom) {
            ToolbarDisplaySettingsPopover(
                baseFontSize: $baseFontSize,
                readingWidth: $readingWidth,
                colorTheme: $colorTheme
            )
        }
    }
}

private struct ToolbarDisplaySettingsPopover: View {
    @Binding var baseFontSize: Double
    @Binding var readingWidth: Double
    @Binding var colorTheme: ReaderColorTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Theme")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.primaryText)
                HStack(spacing: 4) {
                    ForEach(ReaderColorTheme.allCases) { theme in
                        ThemeSwatchButton(
                            theme: theme,
                            isSelected: theme == colorTheme,
                            action: { colorTheme = theme }
                        )
                    }
                }
            }

            Divider()

            HStack {
                Text("Font Size")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.primaryText)
                Spacer()
                Stepper(value: $baseFontSize, in: 15...24, step: 1) {
                    Text("\(Int(baseFontSize)) pt")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(AppTheme.secondaryText)
                        .frame(width: 44, alignment: .trailing)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Reading Width")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.primaryText)
                    Spacer()
                    Text("\(Int(readingWidth)) px")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(AppTheme.secondaryText)
                }
                Slider(value: $readingWidth, in: 640...1040, step: 20)
            }
        }
        .padding(16)
        .frame(width: 240)
        .background(AppTheme.elevatedSurface)
    }
}

private struct ThemeSwatchButton: View {
    let theme: ReaderColorTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? AppTheme.tint : .clear, lineWidth: 2)
                        .frame(width: 29, height: 29)

                    swatch
                        .frame(width: 22, height: 22)
                        .clipShape(Circle())
                        .overlay(
                            Circle().strokeBorder(AppTheme.controlBorder, lineWidth: 1)
                        )
                }
                .frame(width: 30, height: 30)

                Text(theme.displayName)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? AppTheme.tint : AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(theme.displayName)
        .accessibilityLabel(theme.displayName)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    /// Mirrors the actual page backgrounds defined in `ReaderHTMLTemplate`.
    @ViewBuilder
    private var swatch: some View {
        switch theme {
        case .auto:
            HStack(spacing: 0) {
                Color(red: 0.992, green: 0.992, blue: 0.996)
                Color(red: 0.063, green: 0.067, blue: 0.086)
            }
        case .sepia:
            Color(red: 0.969, green: 0.945, blue: 0.898)
        case .light:
            Color(red: 0.992, green: 0.992, blue: 0.996)
        case .dark:
            Color(red: 0.063, green: 0.067, blue: 0.086)
        }
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
        .frame(minWidth: 160, idealWidth: 210, maxWidth: 260)
        .frame(height: 28)
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
        searchField.focusRingType = .none
        searchField.lineBreakMode = .byTruncatingTail
        searchField.stringValue = text
        searchField.isEnabled = isEnabled
        searchField.controlSize = .regular
        searchField.isBordered = true
        searchField.drawsBackground = true
        searchField.bezelStyle = .roundedBezel
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
        HStack(spacing: 8) {
            Button {
                searchPrevious()
            } label: {
                ToolbarIconGlyph(systemName: "chevron.up")
            }
            .buttonStyle(ToolbarIconButtonStyle())
            .disabled(searchQueryIsEmpty || !hasDocument)

            Button {
                searchNext()
            } label: {
                ToolbarIconGlyph(systemName: "chevron.down")
            }
            .buttonStyle(ToolbarIconButtonStyle())
            .disabled(searchQueryIsEmpty || !hasDocument)
        }
    }
}

private struct ToolbarIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        ToolbarIconButtonBody(configuration: configuration)
    }
}

private struct ToolbarIconButtonBody: View {
    let configuration: ToolbarIconButtonStyle.Configuration

    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false

    var body: some View {
        let shape = Capsule(style: .continuous)

        configuration.label
            .frame(width: ToolbarLayout.iconButtonWidth, height: ToolbarLayout.iconButtonHeight)
            .background {
                shape
                    .fill(backgroundStyle)
                    .padding(ToolbarLayout.iconButtonFillInset)
            }
            .contentShape(shape)
            .opacity(foregroundOpacity)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: isHovered)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
            .onHover { hovering in
                isHovered = hovering
            }
    }

    private var backgroundStyle: Color {
        guard isEnabled else {
            return .clear
        }

        if configuration.isPressed {
            return AppTheme.controlHoverFill
        }

        if isHovered {
            return AppTheme.controlSubtleFill
        }

        return .clear
    }

    private var foregroundOpacity: Double {
        guard isEnabled else { return 0.45 }
        if configuration.isPressed {
            return 0.72
        }
        return isHovered ? 0.9 : 0.82
    }
}

private struct ToolbarIconGlyph: View {
    let systemName: String

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: ToolbarLayout.iconSize, weight: .semibold))
            .foregroundStyle(iconForeground)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var iconForeground: Color {
        isEnabled ? AppTheme.primaryText : AppTheme.tertiaryText
    }
}
