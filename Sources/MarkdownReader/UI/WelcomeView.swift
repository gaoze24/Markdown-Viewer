import SwiftUI

struct WelcomeLibraryCopy: Equatable {
    let title: String
    let subtitle: String?
    let secondaryRecentSectionTitle: String?
    let emptySecondaryRecentNote: String?
}

enum WelcomeLibraryPresentation {
    static func copy(recentFileCount: Int) -> WelcomeLibraryCopy {
        if recentFileCount == 0 {
            return WelcomeLibraryCopy(
                title: "Markdown Reader",
                subtitle: "Open a local Markdown file to start reading.",
                secondaryRecentSectionTitle: nil,
                emptySecondaryRecentNote: nil
            )
        }

        return WelcomeLibraryCopy(
            title: "Continue Reading",
            subtitle: nil,
            secondaryRecentSectionTitle: recentFileCount > 1 ? "Other Recent Files" : nil,
            emptySecondaryRecentNote: nil
        )
    }
}

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

    private var copy: WelcomeLibraryCopy {
        WelcomeLibraryPresentation.copy(recentFileCount: recentFiles.count)
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
                    } else if !displayedRecentFiles.isEmpty {
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

                Text(copy.title)
                    .font(.system(size: 27, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryText)

                if let subtitle = copy.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }

            Spacer()

            HStack(spacing: 10) {
                if !recentFiles.isEmpty {
                    Button("Clear Recent Files…", action: clearRecentFilesAction)
                        .buttonStyle(LibraryActionButtonStyle(prominence: .secondary))
                }

                Button(action: openAction) {
                    Label("Open File", systemImage: "folder.badge.plus")
                }
                .buttonStyle(LibraryActionButtonStyle(prominence: .primary))
            }
        }
        .padding(.bottom, 4)
    }

    private func continueReadingSection(item: RecentFileItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
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
            if let secondaryRecentSectionTitle = copy.secondaryRecentSectionTitle {
                sectionLabel(secondaryRecentSectionTitle)
            }

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
            .shadow(color: Color.black.opacity(0.05), radius: 9, x: 0, y: 4)
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
                    Text("Choose a Markdown document")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)
                    Text("Recent documents appear here after you open them. You can also drag a file into the window at any time.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    Button(action: openAction) {
                        Label("Choose Markdown File", systemImage: "folder")
                    }
                    .buttonStyle(LibraryActionButtonStyle(prominence: .primary))
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
}

private enum LibraryActionButtonProminence: Equatable {
    case primary
    case secondary
}

private struct LibraryActionButtonStyle: ButtonStyle {
    let prominence: LibraryActionButtonProminence

    func makeBody(configuration: Configuration) -> some View {
        LibraryActionButtonBody(configuration: configuration, prominence: prominence)
    }
}

private struct LibraryActionButtonBody: View {
    let configuration: LibraryActionButtonStyle.Configuration
    let prominence: LibraryActionButtonProminence

    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)

        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(foregroundStyle)
            .padding(.horizontal, prominence == .primary ? 15 : 11)
            .padding(.vertical, prominence == .primary ? 8 : 7)
            .background(backgroundStyle, in: shape)
            .overlay(
                shape.strokeBorder(borderStyle, lineWidth: 1)
            )
            .contentShape(shape)
            .opacity(isEnabled ? 1 : 0.5)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: isHovered)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
            .onHover { hovering in
                isHovered = hovering
            }
    }

    private var foregroundStyle: Color {
        switch prominence {
        case .primary:
            return AppTheme.controlProminentText
        case .secondary:
            return AppTheme.primaryText
        }
    }

    private var backgroundStyle: Color {
        if prominence == .primary {
            return isHovered || configuration.isPressed
                ? AppTheme.controlProminentHoverFill
                : AppTheme.controlProminentFill
        }

        return isHovered || configuration.isPressed
            ? AppTheme.controlHoverFill
            : AppTheme.controlFill
    }

    private var borderStyle: Color {
        switch prominence {
        case .primary:
            return AppTheme.controlProminentHoverFill
        case .secondary:
            return isHovered ? AppTheme.controlHoverBorder : AppTheme.controlBorder
        }
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
        ZStack(alignment: .trailing) {
            Button(action: openAction) {
                rowContent
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .padding(.trailing, 38)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!item.isAvailable)
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            RecentFileRemoveButton(isVisible: isHovered, action: removeAction)
                .padding(.trailing, 18)
        }
        .background(backgroundStyle, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(borderColor, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(isHovered && item.isAvailable ? 0.12 : 0.07), radius: isHovered ? 16 : 10, x: 0, y: isHovered ? 8 : 5)
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.14)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            recentFileContextMenu(for: item, openAction: openAction, removeAction: removeAction)
        }
    }

    private var rowContent: some View {
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
        ZStack(alignment: .trailing) {
            Button(action: openAction) {
                rowContent
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .padding(.trailing, 34)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!item.isAvailable)

            RecentFileRemoveButton(isVisible: isHovered, action: removeAction)
                .padding(.trailing, 16)
        }
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

    private var rowContent: some View {
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
