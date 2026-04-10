import ReaderCore
import SwiftUI

struct SidebarView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        List {
            outlineSection
            recentFilesSection
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 240, ideal: 280)
    }

    @ViewBuilder
    private var outlineSection: some View {
        if let renderedDocument {
            Section("Outline") {
                if renderedDocument.tableOfContents.isEmpty {
                    Text("No headings found")
                        .foregroundStyle(.secondary)
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
                    .foregroundStyle(.secondary)
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
                                    .foregroundStyle(item.isAvailable ? Color.primary : Color.secondary)
                            }
                            Text(item.path)
                                .font(.caption)
                                .foregroundStyle(.secondary)
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
                .foregroundStyle(.secondary)
        } else {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.orange)
        }
    }

    private func accent(for level: Int) -> Color {
        switch level {
        case 1:
            return Color(red: 0.3, green: 0.46, blue: 0.43)
        case 2:
            return Color(red: 0.48, green: 0.58, blue: 0.5)
        default:
            return Color(red: 0.7, green: 0.72, blue: 0.68)
        }
    }
}
