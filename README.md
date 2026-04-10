# Markdown Reader

Markdown Reader is a lightweight, native-feeling macOS desktop app for reading local Markdown beautifully. It is intentionally focused on calm viewing rather than editing, with a SwiftUI app shell, a polished WebKit reading surface, recent files, a generated table of contents, in-document search, drag and drop, and automatic dark mode support.

## Recommended Stack

**Swift + SwiftUI + WebKit** is the best fit for this product:

- `SwiftUI` gives the app a native macOS split-view layout, toolbar behavior, settings window, and system appearance adaptation with very little overhead.
- `WebKit` gives us excellent text layout, smooth scrolling, image handling, tables, internal anchor navigation, and search highlighting without shipping a heavy Electron runtime.
- A small in-repo Markdown renderer keeps the project self-contained and avoids pulling in external dependencies for a first version.

This keeps the app lightweight, fast to launch, maintainable, and genuinely macOS-native in the places users notice most.

## Architecture

The project is split into a small core library and a native app target:

- `ReaderCore`
  - Markdown parsing and HTML generation
  - table-of-contents extraction
  - recent file persistence
  - file watching for auto reload
- `MarkdownReader`
  - app entry and file-open handling
  - document state and commands
  - SwiftUI layout and preferences
  - custom `WKWebView` bridge for rendering, search, and progress

## Project Structure

```text
.
├── Examples/
│   └── Reader Showcase.md
├── Package.swift
├── README.md
├── Scripts/
│   └── create-app-bundle.sh
├── Sources/
│   ├── MarkdownReader/
│   │   ├── App/
│   │   │   ├── AppDelegate.swift
│   │   │   ├── AppModel.swift
│   │   │   └── MarkdownReaderApp.swift
│   │   ├── UI/
│   │   │   ├── PreferencesView.swift
│   │   │   ├── ReaderPreferenceKey.swift
│   │   │   ├── ReaderView.swift
│   │   │   ├── RootView.swift
│   │   │   ├── SidebarView.swift
│   │   │   └── WelcomeView.swift
│   │   └── Web/
│   │       ├── MarkdownWebView.swift
│   │       └── ReaderHTMLTemplate.swift
│   └── ReaderCore/
│       ├── Models/
│       │   ├── RecentDocument.swift
│       │   ├── RenderedDocument.swift
│       │   └── TableOfContentsItem.swift
│       ├── Services/
│       │   ├── FileWatcher.swift
│       │   ├── MarkdownRenderer.swift
│       │   └── RecentFilesStore.swift
│       └── Utilities/
│           ├── Slugifier.swift
│           └── String+HTML.swift
└── Tests/
    └── ReaderCoreTests/
        └── MarkdownRendererTests.swift
```

## Major Design Decisions

- The app is a **reader-first single-window experience** rather than a document editor.
- Markdown is rendered into a **custom HTML template** with carefully tuned typography, spacing, code blocks, tables, blockquotes, and responsive image handling.
- The **sidebar** focuses on the outline and recent files, keeping navigation useful without becoming a project browser.
- The app uses **system appearance by default**, with minimal preferences for reading width, base font size, and toolbar progress.
- File changes are watched so a README or notes file can **refresh automatically** if it changes on disk.

## What v1 Includes

- Open local `.md`, `.markdown`, `.mdown`, `.mkd`, and `.mkdn` files
- Open files from Finder when the packaged app bundle is used
- Drag and drop support
- Recent files history
- Table of contents sidebar
- In-document search with next/previous navigation
- Relative image support
- Light and dark appearance
- Auto reload on external file changes
- Keyboard shortcuts for open, search, next match, previous match, and reload

## Build And Run

### Development

Build the app:

```bash
swift build
```

Run it:

```bash
swift run MarkdownReader
```

Open a file directly from the command line:

```bash
swift run MarkdownReader "Examples/Reader Showcase.md"
```

### Create A Finder-Ready `.app`

The script below builds a release executable and wraps it as a lightweight macOS app bundle:

```bash
./Scripts/create-app-bundle.sh
```

That produces:

```text
dist/Markdown Reader.app
```

Once the bundle exists, you can launch it normally, drag files onto it, or set it as an `Open With` target for Markdown documents.

## Testing

Run the renderer tests with:

```bash
swift test
```

## Future Roadmap

- PDF export
- better Markdown coverage for edge-case syntax
- optional compact reading mode
- relative Markdown link routing between local files
- a tiny preview-only edit pane for quick fixes
