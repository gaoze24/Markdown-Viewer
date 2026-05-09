import ReaderCore
import SwiftUI

private enum OutlineLayout {
    static let rowInsets = EdgeInsets(top: 3, leading: 4, bottom: 3, trailing: 6)
    static let depthIndent: CGFloat = 8
    static let disclosureSlot: CGFloat = 16
    static let leafDisclosureSlot: CGFloat = 16
    static let disclosureIconSize: CGFloat = 10
    static let disclosureTapHeight: CGFloat = 24
    static let disclosureToLabelSpacing: CGFloat = 4
    static let labelSpacing: CGFloat = 8
    static let labelVerticalPadding: CGFloat = 6
    static let labelLeadingPadding: CGFloat = 4
    static let labelTrailingPadding: CGFloat = 6
    static let selectionCornerRadius: CGFloat = 8
    static let accentWidth: CGFloat = 2.5
    static let accentHeight: CGFloat = 15
    static let headerSpacing: CGFloat = 8
    static let headerBottomPadding: CGFloat = 4
    static let headerMenuIconSize: CGFloat = 13
    static let headerMenuButtonSize: CGFloat = 26
    static let chromeHorizontalPadding: CGFloat = 16
    static let chromeTopPadding: CGFloat = 14
    static let chromeBottomPadding: CGFloat = 12
}

struct SidebarView: View {
    @ObservedObject var model: AppModel

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
                }
                recentFilesSection
            }
            .id(model.sidebarListIdentity)
            .scrollContentBackground(.hidden)
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 252, ideal: 288)
            .animation(.easeInOut(duration: 0.16), value: model.outlineStructureToken)
            .animation(.easeInOut(duration: 0.18), value: model.recentFiles.count)
        }
        .background(AppTheme.sidebarBackground)
    }

    private var sidebarSubtitle: String? {
        if model.hasDocument {
            model.outlineRows.isEmpty ? "No headings found" : nil
        } else {
            "Recent markdown files"
        }
    }

    @ViewBuilder
    private var outlineSection: some View {
        Section {
            if model.outlineRows.isEmpty {
                Text("No headings found")
                    .foregroundStyle(AppTheme.secondaryText)
                    .padding(.vertical, 4)
            } else {
                ForEach(model.outlineRows) { row in
                    OutlineSidebarRow(
                        row: row,
                        toggleAction: {
                            withAnimation(.easeInOut(duration: 0.16)) {
                                model.toggleOutlineExpansion(for: row.heading)
                            }
                        },
                        selectAction: { model.jumpToHeading(row.heading) }
                    )
                    .listRowInsets(OutlineLayout.rowInsets)
                }
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
                            .background(AppTheme.controlSubtleFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
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
    let toggleAction: () -> Void
    let selectAction: () -> Void

    @State private var isHovered = false
    @State private var isDisclosureHovered = false

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            leadingAccessory

            Button(action: selectAction) {
                HStack(alignment: .center, spacing: OutlineLayout.labelSpacing) {
                    Capsule()
                        .fill(accent(for: row.level))
                        .frame(width: OutlineLayout.accentWidth, height: OutlineLayout.accentHeight)

                    Text(row.title)
                        .font(row.isActive ? .system(size: 13, weight: .semibold) : .system(size: 13, weight: .regular))
                        .foregroundStyle(row.isActive ? AppTheme.primaryText : (row.hasActiveDescendant ? AppTheme.primaryText : AppTheme.secondaryText))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, OutlineLayout.labelVerticalPadding)
                .padding(.leading, OutlineLayout.labelLeadingPadding)
                .padding(.trailing, OutlineLayout.labelTrailingPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(backgroundStyle, in: RoundedRectangle(cornerRadius: OutlineLayout.selectionCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: OutlineLayout.selectionCornerRadius, style: .continuous)
                        .strokeBorder(borderStyle, lineWidth: borderWidth)
                )
            }
            .buttonStyle(.plain)
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
                Color.clear
                    .frame(width: CGFloat(row.depth) * OutlineLayout.depthIndent, height: 1)
            }

            if row.hasChildren {
                Button(action: toggleAction) {
                    Image(systemName: row.isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: OutlineLayout.disclosureIconSize, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText)
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

    private var backgroundStyle: Color {
        if row.isActive {
            return AppTheme.subtleAccentFill
        }

        if row.hasActiveDescendant {
            return AppTheme.subtleAccentFill.opacity(0.45)
        }

        if isHovered {
            return AppTheme.controlSubtleFill
        }

        return .clear
    }

    private var borderStyle: Color {
        row.isActive ? AppTheme.subtleAccentBorder : .clear
    }

    private var borderWidth: CGFloat {
        row.isActive ? 1 : 0
    }

    private var disclosureBackgroundStyle: Color {
        isDisclosureHovered ? AppTheme.controlHoverFill : .clear
    }

    private func accent(for level: Int) -> Color {
        AppTheme.outlineAccent(for: level)
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

                    Text(item.path)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(2)
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
