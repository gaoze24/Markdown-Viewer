import SwiftUI
import UniformTypeIdentifiers

struct RootView: View {
    @ObservedObject var model: AppModel

    @AppStorage(ReaderPreferenceKey.baseFontSize) private var baseFontSize = 18.0
    @AppStorage(ReaderPreferenceKey.readingWidth) private var readingWidth = 820.0
    @AppStorage(ReaderPreferenceKey.showProgress) private var showProgress = true

    @FocusState private var searchFieldFocused: Bool
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
                        isDropTargeted: isDropTargeted
                    )
                }
            }
            .background(AppTheme.detailBackground)
        }
        .navigationTitle(model.windowTitle)
        .background(AppTheme.windowBackground)
        .tint(AppTheme.tint)
        .onChange(of: model.searchFocusToken) { _, _ in
            searchFieldFocused = true
        }
        .onDrop(of: [UTType.fileURL], isTargeted: $isDropTargeted) { providers in
            model.openDroppedProviders(providers)
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button {
                    model.openPanel()
                } label: {
                    Label("Open", systemImage: "folder")
                }

                Button {
                    model.reloadCurrentDocument()
                } label: {
                    Label("Reload", systemImage: "arrow.clockwise")
                }
                .disabled(!model.hasDocument)
            }

            ToolbarItem(placement: .principal) {
                if let subtitle = model.subtitle {
                    VStack(spacing: 2) {
                        Text(model.windowTitle)
                            .font(.headline)
                            .foregroundStyle(AppTheme.primaryText)
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: 480)
                }
            }

            ToolbarItemGroup {
                if showProgress, model.hasDocument {
                    ProgressPill(progress: model.scrollProgress)
                }

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AppTheme.secondaryText)

                    TextField("Search", text: $model.searchQuery)
                        .textFieldStyle(.plain)
                        .frame(width: 180)
                        .focused($searchFieldFocused)
                        .disabled(!model.hasDocument)
                        .foregroundStyle(AppTheme.primaryText)

                    if !model.searchQuery.isEmpty, model.hasDocument {
                        Text(model.searchResultCount == 0 ? "No results" : "\(model.currentSearchResult) / \(model.searchResultCount)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(AppTheme.secondaryText)
                    }

                    Button {
                        model.searchPrevious()
                    } label: {
                        Image(systemName: "chevron.up")
                    }
                    .buttonStyle(.plain)
                    .disabled(model.searchQuery.isEmpty)

                    Button {
                        model.searchNext()
                    } label: {
                        Image(systemName: "chevron.down")
                    }
                    .buttonStyle(.plain)
                    .disabled(model.searchQuery.isEmpty)
                }
                .padding(.horizontal, 12)
                .frame(height: 30)
                .background(AppTheme.chromeSurface, in: Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(AppTheme.softBorder, lineWidth: 1)
                )
            }
        }
    }
}

private struct ProgressPill: View {
    let progress: Double

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(progressTint)
                .frame(width: 7, height: 7)
            Text("\(Int(progress * 100))%")
                .font(.caption.monospacedDigit())
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding(.horizontal, 10)
        .frame(height: 28)
        .background(AppTheme.chromeSurface, in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(AppTheme.softBorder, lineWidth: 1)
        )
    }

    private var progressTint: Color {
        AppTheme.progressTint(for: progress)
    }
}
