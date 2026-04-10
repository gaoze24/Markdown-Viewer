# Markdown Reader Showcase

This sample document is here so you can launch the app and immediately check the reading experience.

## Typography

Markdown Reader is tuned for calm, long-form reading:

- generous line height
- restrained serif body type
- a clean heading hierarchy
- smooth internal anchor navigation

## Table of Contents

Use the sidebar to jump between sections. Headings are turned into anchors automatically.

## Tables

| Feature | Status | Notes |
| :--- | ---: | :--- |
| Native SwiftUI shell | Ready | Uses a split-view layout |
| Recent files | Ready | Stored with bookmarks when possible |
| Auto reload | Ready | Watches the current file for external edits |

## Code Blocks

```swift
struct CalmReader {
    let typography = "New York"
    let theme = "System adaptive"
}
```

## Tasks

- [x] Open Markdown files
- [x] Search within the document
- [x] Navigate by heading
- [ ] Export to PDF in a future version

## Blockquote

> Good reader software disappears and lets the document do the talking.

## Footnotes

Footnotes are rendered when the document includes them.[^reader]

[^reader]: This first version keeps the feature practical and lightweight.
