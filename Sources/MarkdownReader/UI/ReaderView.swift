import ReaderCore
import SwiftUI

struct ReaderView: View {
    @ObservedObject var model: AppModel
    let renderedDocument: RenderedDocument
    let displaySettings: ReaderDisplaySettings

    var body: some View {
        ZStack(alignment: .top) {
            MarkdownWebView(
                bodyHTML: renderedDocument.bodyHTML,
                baseURL: model.documentBaseURL,
                displaySettings: displaySettings,
                searchQuery: model.searchQuery,
                searchNavigationRequest: model.searchNavigationRequest,
                anchorNavigationRequest: model.anchorNavigationRequest,
                onSearchUpdate: model.updateSearchResults(count:currentIndex:),
                onProgressUpdate: model.updateScrollProgress(_:),
                onOpenMarkdownLink: { url in
                    Task { @MainActor in
                        model.open(url: url)
                    }
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

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
