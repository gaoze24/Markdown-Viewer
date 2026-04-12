import SwiftUI

@main
struct MarkdownReaderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()

    init() {
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
                .onAppear {
                    appDelegate.onOpenFiles = { urls in
                        Task { @MainActor in
                            model.handleExternalOpen(urls: urls)
                        }
                    }
                    model.bootstrapIfNeeded()
                }
        }
        .windowToolbarStyle(.unifiedCompact(showsTitle: false))
        .windowResizability(.contentSize)
        .defaultSize(width: 1340, height: 860)
        .commands {
            SidebarCommands()
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .newItem) {
                Button("Open…") {
                    model.openPanel()
                }
                .keyboardShortcut("o", modifiers: .command)
            }
            CommandGroup(replacing: .saveItem) {}
            CommandMenu("Reader") {
                Button("Find in Document") {
                    model.requestSearchFocus()
                }
                .keyboardShortcut("f", modifiers: .command)
                .disabled(!model.hasDocument)

                Button("Find Next") {
                    model.searchNext()
                }
                .keyboardShortcut("g", modifiers: .command)
                .disabled(model.searchQuery.isEmpty)

                Button("Find Previous") {
                    model.searchPrevious()
                }
                .keyboardShortcut("g", modifiers: [.command, .shift])
                .disabled(model.searchQuery.isEmpty)

                Divider()

                Button("Reload Document") {
                    model.reloadCurrentDocument()
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(!model.hasDocument)

                if !model.recentFiles.isEmpty {
                    Divider()
                    ForEach(model.recentFiles.prefix(8)) { item in
                        Button(item.name) {
                            model.openRecent(item)
                        }
                        .disabled(!item.isAvailable)
                    }

                    Divider()

                    Button("Clear Recent Files…") {
                        model.confirmAndClearRecentFiles()
                    }
                }
            }
        }

        Settings {
            PreferencesView()
        }
    }
}
