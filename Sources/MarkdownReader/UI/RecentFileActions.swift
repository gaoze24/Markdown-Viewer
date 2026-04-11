import AppKit
import SwiftUI

struct RecentFileRemoveButton: View {
    let isVisible: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 13, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(AppTheme.tertiaryText)
        }
        .buttonStyle(.plain)
        .help("Remove from Recents")
        .accessibilityLabel("Remove from Recents")
        .opacity(isVisible ? 0.92 : 0)
        .scaleEffect(isVisible ? 1 : 0.92)
        .allowsHitTesting(isVisible)
        .animation(.easeOut(duration: 0.14), value: isVisible)
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
