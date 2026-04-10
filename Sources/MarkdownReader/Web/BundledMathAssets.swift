import Foundation

struct BundledMathAssets {
    private static let resourceBundleName = "MarkdownReader_MarkdownReader.bundle"

    let katexCSS: String
    let katexScript: String
    let autoRenderScript: String

    static let shared = (try? load()) ?? BundledMathAssets(
        katexCSS: "",
        katexScript: "",
        autoRenderScript: ""
    )

    private static func load() throws -> BundledMathAssets {
        let katexDirectory = resolvedResourceDirectory()

        let katexCSSURL = katexDirectory?.appending(path: "katex.min.css")
        let katexJSURL = katexDirectory?.appending(path: "katex.min.js")
        let autoRenderURL = katexDirectory?.appending(path: "auto-render.min.js")

        guard
            let katexCSSURL,
            let katexJSURL,
            let autoRenderURL
        else {
            throw NSError(domain: "MarkdownReader", code: 2001, userInfo: [
                NSLocalizedDescriptionKey: "Bundled KaTeX resources are unavailable."
            ])
        }

        let rawCSS = try String(contentsOf: katexCSSURL, encoding: .utf8)
        let patchedCSS = try inlineFontDataURIs(in: rawCSS, katexDirectory: katexDirectory)
        let katexScript = try String(contentsOf: katexJSURL, encoding: .utf8)
        let autoRenderScript = try String(contentsOf: autoRenderURL, encoding: .utf8)

        return BundledMathAssets(
            katexCSS: patchedCSS,
            katexScript: katexScript,
            autoRenderScript: autoRenderScript
        )
    }

    private static func resolvedResourceDirectory() -> URL? {
        // `Bundle.module` traps in the packaged `.app` because SwiftPM's generated
        // accessor expects the resource bundle beside `Bundle.main.bundleURL`,
        // while app bundles store it in `Contents/Resources`.
        for candidate in resourceBundleCandidates() {
            if let directory = katexDirectoryIfPresent(in: candidate) {
                return directory
            }
        }

        return nil
    }

    private static func resourceBundleCandidates() -> [URL] {
        let mainBundle = Bundle.main
        let executableContainer = mainBundle.bundleURL.deletingLastPathComponent()

        return [
            mainBundle.resourceURL,
            mainBundle.resourceURL?.appending(path: resourceBundleName, directoryHint: .isDirectory),
            mainBundle.bundleURL.appending(path: resourceBundleName, directoryHint: .isDirectory),
            executableContainer.appending(path: "Resources", directoryHint: .isDirectory),
            executableContainer.appending(path: "Resources/\(resourceBundleName)", directoryHint: .isDirectory)
        ].compactMap { $0 }
    }

    private static func katexDirectoryIfPresent(in bundleRoot: URL) -> URL? {
        let nestedKaTeX = bundleRoot.appending(path: "KaTeX", directoryHint: .isDirectory)
        if FileManager.default.fileExists(atPath: nestedKaTeX.appending(path: "katex.min.css").path) {
            return nestedKaTeX
        }

        if FileManager.default.fileExists(atPath: bundleRoot.appending(path: "katex.min.css").path) {
            return bundleRoot
        }

        return nil
    }

    private static func inlineFontDataURIs(in css: String, katexDirectory: URL?) throws -> String {
        guard let katexDirectory else { return css }

        let fallbackPattern = #",url\(fonts/[^)]+\.woff\) format\("woff"\),url\(fonts/[^)]+\.ttf\) format\("truetype"\)"#
        let fallbackRegex = try NSRegularExpression(pattern: fallbackPattern)
        let cssWithoutFallbacks = fallbackRegex.stringByReplacingMatches(
            in: css,
            range: NSRange(css.startIndex..., in: css),
            withTemplate: ""
        )

        let fontPattern = #"url\(fonts/([^)]+\.woff2)\)"#
        let fontRegex = try NSRegularExpression(pattern: fontPattern)
        let matches = fontRegex.matches(
            in: cssWithoutFallbacks,
            range: NSRange(cssWithoutFallbacks.startIndex..., in: cssWithoutFallbacks)
        )

        var result = cssWithoutFallbacks
        for match in matches.reversed() {
            guard
                let range = Range(match.range, in: result),
                let filenameRange = Range(match.range(at: 1), in: result)
            else {
                continue
            }

            let filename = String(result[filenameRange])
            let nestedFontURL = katexDirectory.appending(path: "fonts/\(filename)")
            let flatFontURL = katexDirectory.appending(path: filename)
            let fontURL = FileManager.default.fileExists(atPath: nestedFontURL.path) ? nestedFontURL : flatFontURL
            let fontData = try Data(contentsOf: fontURL)
            let dataURI = "url(\"data:font/woff2;base64,\(fontData.base64EncodedString())\")"
            result.replaceSubrange(range, with: dataURI)
        }

        return result
    }
}
