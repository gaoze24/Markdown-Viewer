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
            .background(
                LinearGradient(
                    colors: [
                        Color(nsColor: .windowBackgroundColor),
                        Color(nsColor: .underPageBackgroundColor)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .navigationTitle(model.windowTitle)
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
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
                        .foregroundStyle(.secondary)

                    TextField("Search", text: $model.searchQuery)
                        .textFieldStyle(.plain)
                        .frame(width: 180)
                        .focused($searchFieldFocused)
                        .disabled(!model.hasDocument)

                    if !model.searchQuery.isEmpty, model.hasDocument {
                        Text(model.searchResultCount == 0 ? "No results" : "\(model.currentSearchResult) / \(model.searchResultCount)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
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
                .background(.thinMaterial, in: Capsule())
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
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .frame(height: 28)
        .background(.thinMaterial, in: Capsule())
    }

    private var progressTint: Color {
        switch progress {
        case ..<0.33:
            return Color(red: 0.76, green: 0.63, blue: 0.4)
        case ..<0.8:
            return Color(red: 0.35, green: 0.56, blue: 0.5)
        default:
            return Color(red: 0.23, green: 0.48, blue: 0.42)
        }
    }
}
