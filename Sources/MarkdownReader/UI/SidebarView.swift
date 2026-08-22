import ReaderCore
import SwiftUI

private enum OutlineLayout {
    // The left gutter (indent + disclosure slot + padding) is pure overhead on
    // every row, and in a narrow sidebar it is what forces long headings to
    // wrap. Each value here is kept as tight as it can be while still leaving
    // the chevron comfortably clickable.
    static let rowInsets = EdgeInsets(top: 1, leading: 2, bottom: 1, trailing: 4)
    static let depthIndent: CGFloat = 10
    static let hierarchyGuideWidth: CGFloat = 1
    static let hierarchyGuideHeight: CGFloat = 15
    static let hierarchyGuideCornerRadius: CGFloat = 0.5
    static let disclosureSlot: CGFloat = 13
    static let leafDisclosureSlot: CGFloat = 13
    static let disclosureIconSize: CGFloat = 9
    static let disclosureTapHeight: CGFloat = 22
    static let disclosureToLabelSpacing: CGFloat = 2
    static let labelVerticalPadding: CGFloat = 4
    static let labelLeadingPadding: CGFloat = 7
    static let labelTrailingPadding: CGFloat = 6
    static let selectionCornerRadius: CGFloat = 7
    static let headerSpacing: CGFloat = 8
    static let headerBottomPadding: CGFloat = 4
    static let headerMenuIconSize: CGFloat = 13
    static let headerMenuButtonSize: CGFloat = 26
    static let chromeHorizontalPadding: CGFloat = 16
    static let chromeTopPadding: CGFloat = 14
    static let chromeBottomPadding: CGFloat = 12
}

enum SidebarPresentation {
    static func subtitle(hasDocument _: Bool, outlineIsEmpty _: Bool) -> String? {
        nil
    }
}

struct SidebarView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var viewportState: ReaderViewportState

    var body: some View {
        VStack(spacing: 0) {
            SidebarChromeHeader(
                title: model.hasDocument ? "Outline" : "Library",
                subtitle: sidebarSubtitle,
                hasExpandableItems: model.hasDocument && model.hasExpandableOutlineItems,
                expandAllAction: model.expandAllOutlineItems,
                collapseAllAction: model.collapseAllOutlineItems
            )

            List {
                if model.hasDocument {
                    outlineSection
                } else {
                    recentFilesSection
                }
            }
            .id(model.sidebarListIdentity)
            .scrollContentBackground(.hidden)
            .listStyle(.sidebar)
            // A slightly wider default buys real text width in the outline,
            // which is what keeps long headings from wrapping.
            .navigationSplitViewColumnWidth(min: 244, ideal: 304)
            .animation(.easeInOut(duration: 0.16), value: model.outlineStructureToken)
            .animation(.easeInOut(duration: 0.18), value: model.recentFiles.count)
        }
        .background(AppTheme.sidebarBackground)
    }

    private var sidebarSubtitle: String? {
        SidebarPresentation.subtitle(
            hasDocument: model.hasDocument,
            outlineIsEmpty: model.outlineRows.isEmpty
        )
    }

    @ViewBuilder
    private var outlineSection: some View {
        Section {
            if model.outlineRows.isEmpty {
                Text("No headings found")
                    .foregroundStyle(AppTheme.secondaryText)
                    .padding(.vertical, 4)
            } else {
                OutlineListRows(
                    rows: model.outlineRows,
                    viewportState: viewportState,
                    toggleAction: { heading in
                        withAnimation(.easeInOut(duration: 0.16)) {
                            model.toggleOutlineExpansion(for: heading)
                        }
                    },
                    selectAction: model.jumpToHeading(_:)
                )
            }
        }
    }

    @ViewBuilder
    private var recentFilesSection: some View {
        Section {
            if model.recentFiles.isEmpty {
                Text("Open a Markdown file to build a reading history.")
                    .foregroundStyle(AppTheme.secondaryText)
                    .padding(.vertical, 4)
            } else {
                ForEach(model.recentFiles) { item in
                    SidebarRecentFileRow(
                        item: item,
                        openAction: { model.openRecent(item) },
                        removeAction: {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                model.removeRecent(item)
                            }
                        }
                    )
                }
            }
        } header: {
            SecondarySidebarSectionHeader(title: "Recent Files")
        }
    }
}

private struct OutlineListRows: View {
    let rows: [OutlineRowItem]
    @ObservedObject var viewportState: ReaderViewportState
    let toggleAction: (TableOfContentsItem) -> Void
    let selectAction: (TableOfContentsItem) -> Void

    var body: some View {
        ForEach(rows) { row in
            OutlineSidebarRow(
                row: row,
                isActive: viewportState.activeHeadingID == row.heading.id,
                hasActiveDescendant: row.heading.id != viewportState.activeHeadingID && viewportState.activePathIDs.contains(row.heading.id),
                toggleAction: { toggleAction(row.heading) },
                selectAction: { selectAction(row.heading) }
            )
            .listRowInsets(OutlineLayout.rowInsets)
        }
    }
}

private struct SidebarChromeHeader: View {
    let title: String
    let subtitle: String?
    let hasExpandableItems: Bool
    let expandAllAction: () -> Void
    let collapseAllAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: subtitle == nil ? 0 : 10) {
            HStack(spacing: OutlineLayout.headerSpacing) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.primaryText)

                Spacer(minLength: 12)

                if hasExpandableItems {
                    Menu {
                        Button("Expand All", action: expandAllAction)
                        Button("Collapse All", action: collapseAllAction)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: OutlineLayout.headerMenuIconSize, weight: .regular))
                            .foregroundStyle(AppTheme.secondaryText)
                            .frame(width: OutlineLayout.headerMenuButtonSize, height: OutlineLayout.headerMenuButtonSize)
                            .background(AppTheme.controlFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .strokeBorder(AppTheme.controlBorder, lineWidth: 1)
                            )
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .help("Outline Options")
                }
            }

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, OutlineLayout.chromeHorizontalPadding)
        .padding(.top, OutlineLayout.chromeTopPadding)
        .padding(.bottom, OutlineLayout.chromeBottomPadding)
        .background(AppTheme.sidebarBackground)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppTheme.softBorder)
                .frame(height: 1)
        }
    }
}

private struct SecondarySidebarSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 11.5, weight: .semibold))
            .foregroundStyle(AppTheme.tertiaryText)
            .padding(.bottom, OutlineLayout.headerBottomPadding)
            .textCase(nil)
    }
}

private struct OutlineSidebarRow: View {
    let row: OutlineRowItem
    let isActive: Bool
    let hasActiveDescendant: Bool
    let toggleAction: () -> Void
    let selectAction: () -> Void

    @State private var isHovered = false
    @State private var isDisclosureHovered = false

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            leadingAccessory

            Button(action: selectAction) {
                Text(row.title)
                    .font(labelFont)
                    .foregroundStyle(labelColor)
                    .lineLimit(2)
                    .allowsTightening(true)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, OutlineLayout.labelVerticalPadding)
                    .padding(.leading, OutlineLayout.labelLeadingPadding)
                    .padding(.trailing, OutlineLayout.labelTrailingPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(backgroundStyle, in: RoundedRectangle(cornerRadius: OutlineLayout.selectionCornerRadius, style: .continuous))
            }
            .buttonStyle(.plain)
            // Headings longer than two lines still truncate; the tooltip keeps
            // the full text reachable.
            .help(row.title)
        }
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
    }

    @ViewBuilder
    private var leadingAccessory: some View {
        HStack(alignment: .center, spacing: 0) {
            if row.depth > 0 {
                HStack(alignment: .center, spacing: 0) {
                    ForEach(0..<row.depth, id: \.self) { depth in
                        ZStack {
                            if depth == row.depth - 1 {
                                RoundedRectangle(cornerRadius: OutlineLayout.hierarchyGuideCornerRadius, style: .continuous)
                                    .fill(hierarchyGuideColor)
                                    .frame(width: OutlineLayout.hierarchyGuideWidth, height: OutlineLayout.hierarchyGuideHeight)
                            }
                        }
                        .frame(width: OutlineLayout.depthIndent)
                    }
                }
            }

            if row.hasChildren {
                Button(action: toggleAction) {
                    Image(systemName: row.isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: OutlineLayout.disclosureIconSize, weight: .semibold))
                        .foregroundStyle(disclosureColor)
                        .frame(width: OutlineLayout.disclosureSlot, height: OutlineLayout.disclosureTapHeight)
                        .background(disclosureBackgroundStyle, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
                .buttonStyle(.plain)
                .help(row.isExpanded ? "Collapse Section" : "Expand Section")
                .onHover { hovering in
                    withAnimation(.easeOut(duration: 0.12)) {
                        isDisclosureHovered = hovering
                    }
                }
            } else {
                Color.clear
                    .frame(width: OutlineLayout.leafDisclosureSlot, height: OutlineLayout.disclosureTapHeight)
            }

            Color.clear
                .frame(width: OutlineLayout.disclosureToLabelSpacing, height: 1)
        }
    }

    private var labelFont: Font {
        if isActive {
            return .system(size: 13, weight: .semibold)
        }

        if row.depth == 0 {
            return .system(size: 13, weight: .medium)
        }

        return .system(size: 13, weight: .regular)
    }

    private var labelColor: Color {
        if isActive {
            return AppTheme.tint
        }

        if hasActiveDescendant || row.depth == 0 {
            return AppTheme.primaryText
        }

        return AppTheme.secondaryText
    }

    private var backgroundStyle: Color {
        if isActive {
            return AppTheme.subtleAccentFill
        }

        if isHovered {
            return AppTheme.controlSubtleFill
        }

        return .clear
    }

    private var hierarchyGuideColor: Color {
        if hasActiveDescendant || isActive {
            return AppTheme.subtleAccentBorder
        }

        return AppTheme.softBorder
    }

    private var disclosureColor: Color {
        if isActive || hasActiveDescendant {
            return AppTheme.primaryText
        }

        return AppTheme.secondaryText
    }

    private var disclosureBackgroundStyle: Color {
        if isDisclosureHovered {
            return AppTheme.controlHoverFill
        }

        if hasActiveDescendant {
            return AppTheme.controlSubtleFill
        }

        return .clear
    }

}

private struct SidebarRecentFileRow: View {
    let item: RecentFileItem
    let openAction: () -> Void
    let removeAction: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            Button(action: openAction) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        recentFileIcon(isAvailable: item.isAvailable)
                        Text(item.name)
                            .lineLimit(1)
                            .foregroundStyle(item.isAvailable ? AppTheme.primaryText : AppTheme.secondaryText)
                    }

                    Text(item.displayLocation)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
            .disabled(!item.isAvailable)

            RecentFileRemoveButton(isVisible: isHovered, action: removeAction)
        }
        .contentShape(Rectangle())
        .contextMenu {
            recentFileContextMenu(for: item, openAction: openAction, removeAction: removeAction)
        }
        .onHover { hovering in
            isHovered = hovering
        }
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
}
