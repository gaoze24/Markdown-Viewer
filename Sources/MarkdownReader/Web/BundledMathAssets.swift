import Foundation

struct BundledMathAssets {
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
        BundledResourceLocator.directory(named: "KaTeX", containing: "katex.min.css")
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
