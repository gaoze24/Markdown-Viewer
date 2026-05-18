import AppKit
import SwiftUI

struct RecentFileRemoveButton: View {
    let isVisible: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 12.5, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(iconForeground)
                .frame(width: 26, height: 26)
                .background(backgroundStyle, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .help("Remove from Recents")
        .accessibilityLabel("Remove from Recents")
        .opacity(isVisible ? 1 : 0.68)
        .scaleEffect(isVisible || isHovered ? 1 : 0.96)
        .animation(.easeOut(duration: 0.14), value: isVisible)
        .animation(.easeOut(duration: 0.12), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var backgroundStyle: Color {
        isHovered ? AppTheme.controlHoverFill : AppTheme.controlFill
    }

    private var iconForeground: Color {
        isHovered ? AppTheme.primaryText : AppTheme.secondaryText
    }
}

@MainActor
@ViewBuilder
func recentFileContextMenu(
    for item: RecentFileItem,
    openAction: @escaping () -> Void,
    removeAction: @escaping () -> Void
) -> some View {
    Button("Open") {
        openAction()
    }
    .disabled(!item.isAvailable)

    if item.isAvailable {
        Button("Reveal in Finder") {
            NSWorkspace.shared.activateFileViewerSelecting([item.url])
        }
    }

    Button("Copy Path") {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.path, forType: .string)
    }

    Divider()

    Button("Remove from Recents") {
        removeAction()
    }
}
