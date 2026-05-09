import SwiftUI

struct WelcomeView: View {
    let recentFiles: [RecentFileItem]
    let errorMessage: String?
    let openAction: () -> Void
    let openRecentAction: (RecentFileItem) -> Void
    let removeRecentAction: (RecentFileItem) -> Void
    let clearRecentFilesAction: () -> Void
    let isDropTargeted: Bool

    private var continueReadingItem: RecentFileItem? {
        recentFiles.first
    }

    private var remainingRecentFiles: [RecentFileItem] {
        Array(recentFiles.dropFirst())
    }

    private var displayedRecentFiles: [RecentFileItem] {
        // Always show what's *not* already featured. Falling back to the full
        // list duplicated the most-recent file on the page when only one entry
        // existed.
        remainingRecentFiles
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    headerSection

                    if let errorMessage {
                        inlineMessage(errorMessage, tint: AppTheme.warning)
                    }

                    if isDropTargeted {
                        inlineMessage("Drop a Markdown file to open it here.", tint: AppTheme.tint)
                    }

                    if let continueReadingItem {
                        continueReadingSection(item: continueReadingItem)
                    }

                    if recentFiles.isEmpty {
                        emptyLibrarySection
                    } else {
                        recentFilesSection
                    }

                    utilityStrip
                }
                .frame(maxWidth: 920, alignment: .leading)
                .padding(.horizontal, 34)
                .padding(.top, 30)
                .padding(.bottom, 36)
                .frame(maxWidth: .infinity, minHeight: max(proxy.size.height - 12, 620), alignment: .top)
            }
        }
    }

    private var headerSection: some View {
        HStack(alignment: .bottom, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Library")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(AppTheme.tertiaryText)

                Text(recentFiles.isEmpty ? "No recent Markdown files" : "Recent Markdown Files")
                    .font(.system(size: 27, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryText)

                Text(statusLine)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()

            HStack(spacing: 10) {
                if !recentFiles.isEmpty {
                    Button("Clear Recent Files…", action: clearRecentFilesAction)
                        .buttonStyle(.plain)
                        .foregroundStyle(AppTheme.secondaryText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(AppTheme.controlSubtleFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                Button(action: openAction) {
                    Label("Open File", systemImage: "folder.badge.plus")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .padding(.bottom, 4)
    }

    private func continueReadingSection(item: RecentFileItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Continue Reading")

            LibraryFeatureRow(
                item: item,
                eyebrow: "Most recent",
                emphasis: .featured,
                openAction: { openRecentAction(item) },
                removeAction: { removeRecentAction(item) }
            )
        }
    }

    private var recentFilesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(continueReadingItem == nil ? "Recent Markdown Files" : "More Recent Files")

            if remainingRecentFiles.isEmpty, continueReadingItem != nil {
                secondaryNote("The latest document is ready above.")
                    .padding(.top, 2)
            } else {
                VStack(spacing: 0) {
                    ForEach(displayedRecentFiles) { item in
                        LibraryListRow(
                            item: item,
                            openAction: { openRecentAction(item) },
                            removeAction: { removeRecentAction(item) }
                        )

                        if item.id != displayedRecentFiles.last?.id {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(AppTheme.softBorder, lineWidth: 1)
                )
            }
        }
        .animation(.easeInOut(duration: 0.18), value: recentFiles.map(\.id))
    }

    private var emptyLibrarySection: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionLabel("Workspace")

            HStack(alignment: .top, spacing: 16) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.iconTile, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 10) {
                    Text("Open a local Markdown file to start reading.")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)
                    Text("Recent documents will appear here once you’ve opened a file. You can also drag a document into the window at any time.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    Button(action: openAction) {
                        Label("Choose Markdown File", systemImage: "folder")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                }
            }
            .padding(.vertical, 10)
        }
    }

    private var utilityStrip: some View {
        HStack(alignment: .center, spacing: 14) {
            Label("Drag files into the window to open them", systemImage: "arrow.down.doc")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)

            Divider()
                .frame(height: 14)

            Text("Supports .md, .markdown, .mdown, .mkd, and .mkdn")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)

            Spacer()
        }
        .padding(.top, 4)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(AppTheme.tertiaryText)
    }

    private func secondaryNote(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(AppTheme.secondaryText)
    }

    private func inlineMessage(_ message: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(tint)
                .frame(width: 6, height: 6)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(tint)
        }
        .padding(.vertical, 3)
    }

    private var statusLine: String {
        if recentFiles.isEmpty {
            return "A quiet place to open and revisit local Markdown documents."
        }

        if recentFiles.count == 1 {
            return "Your most recent document is ready to continue."
        }

        return "Pick up where you left off or open another document."
    }
}

private struct LibraryFeatureRow: View {
    enum Emphasis {
        case featured
    }

    let item: RecentFileItem
    let eyebrow: String
    let emphasis: Emphasis
    let openAction: () -> Void
    let removeAction: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            Button(action: openAction) {
                HStack(spacing: 16) {
                    rowIcon

                    VStack(alignment: .leading, spacing: 5) {
                        Text(eyebrow)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.tertiaryText)

                        Text(item.name)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(item.isAvailable ? AppTheme.primaryText : AppTheme.secondaryText)
                            .lineLimit(1)

                        Text(item.path)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryText)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 20)

                    HStack(spacing: 10) {
                        availabilityBadge

                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                            .opacity(isHovered && item.isAvailable ? 1 : 0.45)
                            .offset(x: isHovered && item.isAvailable ? 2 : 0)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .disabled(!item.isAvailable)

            RecentFileRemoveButton(isVisible: isHovered, action: removeAction)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(backgroundStyle, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(borderColor, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.14)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            recentFileContextMenu(for: item, openAction: openAction, removeAction: removeAction)
        }
    }

    private var backgroundStyle: Color {
        if isHovered && item.isAvailable {
            return AppTheme.subtleAccentFill
        }
        return AppTheme.elevatedSurface
    }

    private var borderColor: Color {
        isHovered && item.isAvailable ? AppTheme.subtleAccentBorder : AppTheme.softBorder
    }

    private var rowIcon: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(AppTheme.iconTile)
            .frame(width: 48, height: 48)
            .overlay {
                if item.isAvailable {
                    Image(systemName: "doc.richtext")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(AppTheme.warning)
                }
            }
    }

    @ViewBuilder
    private var availabilityBadge: some View {
        if item.isAvailable {
            Text("Continue")
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.secondaryText)
        } else {
            Text("Missing")
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.warning)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(AppTheme.warning.opacity(0.14), in: Capsule())
        }
    }
}

private struct LibraryListRow: View {
    let item: RecentFileItem
    let openAction: () -> Void
    let removeAction: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            Button(action: openAction) {
                HStack(spacing: 14) {
                    icon

                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.name)
                            .font(.headline)
                            .foregroundStyle(item.isAvailable ? AppTheme.primaryText : AppTheme.secondaryText)
                            .lineLimit(1)
                        Text(item.path)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryText)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 12)

                    if item.isAvailable {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppTheme.tertiaryText)
                            .opacity(isHovered ? 1 : 0.55)
                    } else {
                        Text("Missing")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AppTheme.warning)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .disabled(!item.isAvailable)

            RecentFileRemoveButton(isVisible: isHovered, action: removeAction)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isHovered && item.isAvailable ? AppTheme.subtleAccentFill : .clear)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            recentFileContextMenu(for: item, openAction: openAction, removeAction: removeAction)
        }
    }

    @ViewBuilder
    private var icon: some View {
        if item.isAvailable {
            Image(systemName: "doc.text")
                .foregroundStyle(AppTheme.secondaryText)
                .frame(width: 22)
        } else {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(AppTheme.warning)
                .frame(width: 22)
        }
    }
}
