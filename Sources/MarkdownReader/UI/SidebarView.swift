import ReaderCore
import SwiftUI

struct SidebarView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ZStack {
            AppTheme.sidebarBackground
                .ignoresSafeArea()

            List {
                outlineSection
                recentFilesSection
            }
            .scrollContentBackground(.hidden)
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 240, ideal: 280)
        }
    }

    @ViewBuilder
    private var outlineSection: some View {
        if let renderedDocument {
            Section("Outline") {
                if renderedDocument.tableOfContents.isEmpty {
                    Text("No headings found")
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    ForEach(renderedDocument.tableOfContents) { heading in
                        Button {
                            model.jumpToHeading(heading)
                        } label: {
                            HStack(spacing: 10) {
                                Capsule()
                                    .fill(accent(for: heading.level))
                                    .frame(width: 3)
                                Text(heading.title)
                                    .foregroundStyle(AppTheme.primaryText)
                                    .lineLimit(2)
                                    .padding(.leading, CGFloat(max(heading.level - 1, 0) * 10))
                            }
                            .padding(.vertical, 3)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var recentFilesSection: some View {
        Section("Recent Files") {
            if model.recentFiles.isEmpty {
                Text("Open a Markdown file to build a reading history.")
                    .foregroundStyle(AppTheme.secondaryText)
            } else {
                ForEach(model.recentFiles) { item in
                    Button {
                        model.openRecent(item)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                recentFileIcon(isAvailable: item.isAvailable)
                                Text(item.name)
                                    .lineLimit(1)
                                    .foregroundStyle(item.isAvailable ? AppTheme.primaryText : AppTheme.secondaryText)
                            }
                            Text(item.path)
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                                .lineLimit(2)
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.plain)
                    .disabled(!item.isAvailable)
                }
            }
        }
    }

    private var renderedDocument: RenderedDocument? {
        model.renderedDocument
    }

    @ViewBuilder
    private func recentFileIcon(isAvailable: Bool) -> some View {
        if isAvailable {
            Image(systemName: "doc.text")
                .foregroundStyle(AppTheme.secondaryText)
        } else {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(AppTheme.warning)
        }
    }

    private func accent(for level: Int) -> Color {
        AppTheme.outlineAccent(for: level)
    }
}
