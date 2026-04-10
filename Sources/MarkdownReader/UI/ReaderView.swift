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
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            )
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 20)

            if let banner = activeBanner {
                Text(banner)
                    .font(.callout)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.thinMaterial, in: Capsule())
                    .padding(.top, 10)
            }

            if model.isLoading {
                ProgressView()
                    .controlSize(.small)
                    .padding(12)
                    .background(.thinMaterial, in: Capsule())
                    .padding(.top, 16)
            }
        }
    }

    private var activeBanner: String? {
        model.loadErrorMessage ?? model.availabilityMessage
    }
}
