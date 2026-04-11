import ReaderCore
import SwiftUI

private enum OutlineLayout {
    static let rowInsets = EdgeInsets(top: 0.5, leading: 2, bottom: 0.5, trailing: 5)
    static let depthIndent: CGFloat = 6
    static let disclosureSlot: CGFloat = 8
    static let leafDisclosureSlot: CGFloat = 5
    static let disclosureIconSize: CGFloat = 8
    static let disclosureToLabelSpacing: CGFloat = 3
    static let labelSpacing: CGFloat = 7
    static let labelVerticalPadding: CGFloat = 2
    static let labelLeadingPadding: CGFloat = 2
    static let labelTrailingPadding: CGFloat = 4
    static let selectionCornerRadius: CGFloat = 6
    static let accentWidth: CGFloat = 2.5
    static let accentHeight: CGFloat = 12
    static let headerSpacing: CGFloat = 6
    static let headerBottomPadding: CGFloat = 1
    static let headerMenuIconSize: CGFloat = 12
}

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
            .animation(.easeInOut(duration: 0.16), value: model.outlineRows.map(\.id))
            .animation(.easeInOut(duration: 0.18), value: model.recentFiles.map(\.id))
        }
    }

    @ViewBuilder
    private var outlineSection: some View {
        if model.hasDocument {
            Section {
                if model.outlineRows.isEmpty {
                    Text("No headings found")
                        .foregroundStyle(AppTheme.secondaryText)
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
            } header: {
                OutlineSectionHeader(
                    hasExpandableItems: model.hasExpandableOutlineItems,
                    expandAllAction: { model.expandAllOutlineItems() },
                    collapseAllAction: { model.collapseAllOutlineItems() }
                )
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
        }
    }

}

private struct OutlineSectionHeader: View {
    let hasExpandableItems: Bool
    let expandAllAction: () -> Void
    let collapseAllAction: () -> Void

    var body: some View {
        HStack(spacing: OutlineLayout.headerSpacing) {
            Text("Outline")
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(AppTheme.tertiaryText)

            Spacer()

            if hasExpandableItems {
                Menu {
                    Button("Expand All", action: expandAllAction)
                    Button("Collapse All", action: collapseAllAction)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: OutlineLayout.headerMenuIconSize, weight: .regular))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .help("Outline Options")
            }
        }
        .padding(.bottom, OutlineLayout.headerBottomPadding)
        .textCase(nil)
    }
}

private struct OutlineSidebarRow: View {
    let row: OutlineRowItem
    let toggleAction: () -> Void
    let selectAction: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            leadingAccessory

            Button(action: selectAction) {
                HStack(alignment: .top, spacing: OutlineLayout.labelSpacing) {
                    Capsule()
                        .fill(accent(for: row.level))
                        .frame(width: OutlineLayout.accentWidth, height: OutlineLayout.accentHeight)
                        .padding(.top, 2)

                    Text(row.title)
                        .font(row.isActive ? .system(size: 12.5, weight: .semibold) : .system(size: 12.5, weight: .regular))
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
        .padding(.vertical, 0.5)
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
                        .frame(width: OutlineLayout.disclosureSlot, height: OutlineLayout.disclosureSlot)
                }
                .buttonStyle(.plain)
                .help(row.isExpanded ? "Collapse Section" : "Expand Section")
            } else {
                Color.clear
                    .frame(width: OutlineLayout.leafDisclosureSlot, height: OutlineLayout.disclosureSlot)
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

        return .clear
    }

    private var borderStyle: Color {
        row.isActive ? AppTheme.subtleAccentBorder : .clear
    }

    private var borderWidth: CGFloat {
        row.isActive ? 1 : 0
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
                .padding(.vertical, 4)
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
