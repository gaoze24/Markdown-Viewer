import Foundation

/// The offline Mermaid runtime used to draw ```mermaid fences.
struct BundledDiagramAssets {
    let mermaidScript: String

    static let shared = (try? load()) ?? BundledDiagramAssets(mermaidScript: "")

    var isAvailable: Bool { !mermaidScript.isEmpty }

    private static func load() throws -> BundledDiagramAssets {
        guard
            let directory = BundledResourceLocator.directory(named: "Mermaid", containing: "mermaid.min.js")
        else {
            throw NSError(domain: "MarkdownReader", code: 2002, userInfo: [
                NSLocalizedDescriptionKey: "Bundled Mermaid resources are unavailable."
            ])
        }

        return BundledDiagramAssets(
            mermaidScript: try String(contentsOf: directory.appending(path: "mermaid.min.js"), encoding: .utf8)
        )
    }
}
