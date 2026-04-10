import SwiftUI

struct WelcomeView: View {
    let recentFiles: [RecentFileItem]
    let errorMessage: String?
    let openAction: () -> Void
    let openRecentAction: (RecentFileItem) -> Void
    let isDropTargeted: Bool

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 28) {
                    heroCard
                    .padding(.top, 28)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 30)
                    .frame(maxWidth: 780)
                    .background(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .strokeBorder(
                                        isDropTargeted ? Color.accentColor.opacity(0.55) : Color.primary.opacity(0.08),
                                        lineWidth: isDropTargeted ? 2 : 1
                                    )
                            )
                    )
                    .shadow(color: .black.opacity(0.06), radius: 30, y: 10)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.callout)
                            .foregroundStyle(.red)
                    }

                    if !recentFiles.isEmpty {
                        recentReadsSection
                        .frame(maxWidth: 780, alignment: .leading)
                    }
                }
                .frame(minHeight: max(proxy.size.height - 20, 680))
                .padding(32)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var heroCard: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.93, green: 0.9, blue: 0.82),
                                Color(red: 0.82, green: 0.86, blue: 0.82)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 96, height: 96)
                Image(systemName: "text.document")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(Color(red: 0.2, green: 0.28, blue: 0.29))
            }

            VStack(spacing: 10) {
                Text("Markdown Reader")
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                Text("A calm, lightweight way to read local Markdown on macOS.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 560)
            }

            HStack(spacing: 14) {
                Button(action: openAction) {
                    Label("Open Markdown File", systemImage: "folder")
                        .padding(.horizontal, 18)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Text("or drop a file anywhere in the window")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var recentReadsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Reads")
                .font(.title3.weight(.semibold))

            VStack(spacing: 10) {
                ForEach(recentFiles) { item in
                    recentRow(for: item)
                }
            }
        }
    }

    private func recentRow(for item: RecentFileItem) -> some View {
        Button {
            openRecentAction(item)
        } label: {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.primary.opacity(0.06))
                    .frame(width: 42, height: 42)
                    .overlay {
                        icon(for: item)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundStyle(item.isAvailable ? .primary : .secondary)
                        .lineLimit(1)
                    Text(item.path)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if !item.isAvailable {
                    Text("Missing")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.12), in: Capsule())
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.primary.opacity(0.03))
            )
        }
        .buttonStyle(.plain)
        .disabled(!item.isAvailable)
    }

    @ViewBuilder
    private func icon(for item: RecentFileItem) -> some View {
        if item.isAvailable {
            Image(systemName: "doc.plaintext")
                .foregroundStyle(.secondary)
        } else {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.orange)
        }
    }
}
