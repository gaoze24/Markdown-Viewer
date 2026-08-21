import ReaderCore
import SwiftUI

struct ReaderView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var searchState: ReaderSearchState
    let renderedDocument: RenderedDocument
    let displaySettings: ReaderDisplaySettings
    let showProgress: Bool

    var body: some View {
        ZStack(alignment: .top) {
            MarkdownWebView(
                bodyHTML: renderedDocument.bodyHTML,
                baseURL: model.documentBaseURL,
                displaySettings: displaySettings,
                searchQuery: searchState.debouncedSearchQuery,
                searchNavigationRequest: searchState.searchNavigationRequest,
                anchorNavigationRequest: searchState.anchorNavigationRequest,
                onSearchUpdate: model.updateSearchResults(count:currentIndex:),
                onProgressUpdate: model.updateScrollProgress(_:),
                onActiveHeadingUpdate: model.updateActiveHeading(_:),
                onOpenMarkdownLink: { url in
                    Task { @MainActor in
                        model.open(url: url)
                    }
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if showProgress {
                ReaderProgressEdgeBar(progressState: model.progressState)
            }

            if let banner = activeBanner {
                Text(banner)
                    .font(.callout)
                    .foregroundStyle(AppTheme.primaryText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(AppTheme.chromeSurface, in: Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(AppTheme.softBorder, lineWidth: 1)
                    )
                    .padding(.top, 10)
            }

            if model.isLoading {
                ProgressView()
                    .controlSize(.small)
                    .padding(12)
                    .background(AppTheme.chromeSurface, in: Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(AppTheme.softBorder, lineWidth: 1)
                    )
                    .padding(.top, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var activeBanner: String? {
        model.loadErrorMessage ?? model.availabilityMessage
    }
}

enum ReaderReturnPresentation {
    static func isVisible(hasDocument: Bool) -> Bool {
        hasDocument
    }
}

private struct ReaderProgressEdgeBar: View {
    @ObservedObject var progressState: ReaderProgressState

    @State private var isHovered = false

    private let barHeight: CGFloat = 2.5
    private let hoverStripHeight: CGFloat = 14

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(AppTheme.divider)

                Rectangle()
                    .fill(AppTheme.progressTint(for: progressState.scrollProgress))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .scaleEffect(x: max(0, min(1, progressState.scrollProgress)), y: 1, anchor: .leading)
            }
            .frame(height: barHeight)
            .frame(maxWidth: .infinity, alignment: .top)

            if isHovered {
                Text("\(Int((progressState.scrollProgress * 100).rounded()))%")
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.chromeSurface, in: Capsule())
                    .overlay(
                        Capsule().strokeBorder(AppTheme.softBorder, lineWidth: 1)
                    )
                    .padding(.top, 6)
                    .padding(.trailing, 10)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .frame(height: hoverStripHeight, alignment: .top)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
        .animation(.easeOut(duration: 0.15), value: progressState.scrollProgress)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Reading progress")
        .accessibilityValue("\(Int((progressState.scrollProgress * 100).rounded())) percent")
    }
}
