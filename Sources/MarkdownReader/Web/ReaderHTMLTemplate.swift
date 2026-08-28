import Foundation

enum ReaderHTMLTemplate {
    static let mathPlaceholderClass = "math-placeholder"
    static let diagramPlaceholderClass = "mermaid-diagram"

    /// Shared with both the `[data-theme="dark"]` override and the
    /// `prefers-color-scheme: dark` auto-mode block so the two stay in sync.
    fileprivate static let darkVariables = """
    --page-bg: #101116;
    --page-bg-secondary: #171922;
    --text: #e9ebf1;
    --muted: #9ca1ae;
    --border: rgba(233, 235, 241, 0.16);
    --soft-border: rgba(233, 235, 241, 0.085);
    --surface-weak: rgba(255, 255, 255, 0.035);
    --surface-strong: rgba(255, 255, 255, 0.055);
    --blockquote-bg: rgba(160, 154, 255, 0.10);
    --code-bg: rgba(255, 255, 255, 0.048);
    --code-border: rgba(255, 255, 255, 0.10);
    --table-row: rgba(255, 255, 255, 0.028);
    --accent: #a7a2ff;
    --accent-soft: rgba(167, 162, 255, 0.16);
    --search-bg: rgba(214, 168, 64, 0.42);
    --search-current: rgba(255, 190, 80, 0.62);
    """

    /// The warm "paper" reading theme. This used to be the app's only light
    /// look; it is now one deliberate option beside the crisp default.
    fileprivate static let sepiaVariables = """
    --page-bg: #f7f1e5;
    --page-bg-secondary: #efe7d8;
    --text: #2a2118;
    --muted: #6b5c4a;
    --border: rgba(74, 54, 32, 0.20);
    --soft-border: rgba(74, 54, 32, 0.11);
    --surface-weak: rgba(253, 248, 240, 0.82);
    --surface-strong: rgba(251, 246, 237, 0.95);
    --blockquote-bg: rgba(150, 116, 76, 0.10);
    --code-bg: rgba(86, 64, 40, 0.07);
    --code-border: rgba(86, 64, 40, 0.15);
    --table-row: rgba(86, 64, 40, 0.04);
    --accent: #98622f;
    --accent-soft: rgba(152, 98, 47, 0.13);
    --search-bg: rgba(228, 184, 92, 0.46);
    --search-current: rgba(214, 144, 58, 0.55);
    """

    static func makeDocument(bodyHTML: String, settings: ReaderDisplaySettings) -> String {
        let mathAssets = BundledMathAssets.shared
        let includeMath = bodyHTML.contains(mathPlaceholderClass)

        let mathStyle = includeMath
            ? "<style>\(mathAssets.katexCSS)</style>"
            : ""
        let mathScript = includeMath
            ? "<script>\(mathAssets.katexScript)</script>"
            : ""

        let diagramAssets = BundledDiagramAssets.shared
        let includeDiagrams = bodyHTML.contains(diagramPlaceholderClass) && diagramAssets.isAvailable
        let diagramScript = includeDiagrams
            ? "<script>\(diagramAssets.mermaidScript)</script>"
            : ""

        let themeAttribute = settings.colorTheme == .auto ? "" : " data-theme=\"\(settings.colorTheme.rawValue)\""

        return """
        <!doctype html>
        <html lang="en"\(themeAttribute)>
        <head>
            <meta charset="utf-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1" />
            \(mathStyle)
            <style>
                :root {
                    color-scheme: light dark;
                    --reader-width: \(Int(settings.readingWidth))px;
                    --base-font-size: \(String(format: "%.1f", settings.baseFontSize))px;
                    --viewport-padding-x: clamp(26px, 4vw, 56px);
                    --viewport-padding-top: 44px;
                    --viewport-padding-bottom: 96px;
                    --block-space: 1.05em;
                    --section-space: 1.92em;
                    --font-body: -apple-system, "SF Pro Text", system-ui, "Segoe UI", Roboto, sans-serif;
                    --font-display: "SF Pro Display", -apple-system, system-ui, "Segoe UI", Roboto, sans-serif;
                    --font-mono: "SF Mono", "JetBrains Mono", ui-monospace, Menlo, monospace;
                    --page-bg: #fdfdfe;
                    --page-bg-secondary: #f4f5f9;
                    --text: #15171c;
                    --muted: #5f636e;
                    --border: rgba(21, 23, 28, 0.13);
                    --soft-border: rgba(21, 23, 28, 0.07);
                    --surface-weak: rgba(255, 255, 255, 0.75);
                    --surface-strong: #ffffff;
                    --blockquote-bg: rgba(91, 84, 232, 0.05);
                    --code-bg: rgba(23, 25, 35, 0.042);
                    --code-border: rgba(23, 25, 35, 0.10);
                    --table-row: rgba(23, 25, 35, 0.026);
                    --accent: #5b54e8;
                    --accent-soft: rgba(91, 84, 232, 0.12);
                    --search-bg: rgba(255, 214, 102, 0.55);
                    --search-current: rgba(255, 171, 64, 0.72);
                }

                :root[data-theme="sepia"] {
                    \(ReaderHTMLTemplate.sepiaVariables)
                }

                :root[data-theme="dark"] {
                    \(ReaderHTMLTemplate.darkVariables)
                }

                @media (prefers-color-scheme: dark) {
                    :root:not([data-theme]) {
                        \(ReaderHTMLTemplate.darkVariables)
                    }
                }

                * {
                    box-sizing: border-box;
                }

                html, body {
                    min-height: 100%;
                    width: 100%;
                    max-width: 100%;
                    overflow-x: hidden;
                }

                html {
                    background: var(--page-bg);
                }

                body {
                    margin: 0;
                    color: var(--text);
                    font-family: var(--font-body);
                    font-size: var(--base-font-size);
                    line-height: 1.72;
                    letter-spacing: -0.003em;
                    text-rendering: optimizeLegibility;
                    -webkit-font-smoothing: antialiased;
                    overflow-wrap: anywhere;
                    background: transparent;
                }

                html.smooth-scroll {
                    scroll-behavior: smooth;
                }

                main {
                    width: 100%;
                    max-width: 100%;
                    margin: 0;
                    padding:
                        calc(var(--viewport-padding-top) + env(safe-area-inset-top, 0px))
                        0
                        calc(var(--viewport-padding-bottom) + env(safe-area-inset-bottom, 0px));
                }

                .reader-page {
                    width: 100%;
                    max-width: 100%;
                    padding: 0 var(--viewport-padding-x);
                }

                .reader-content {
                    width: min(100%, var(--reader-width));
                    max-width: 100%;
                    margin: 0 auto;
                }

                .reader-content > * {
                    max-width: 100%;
                }

                .reader-content > :first-child {
                    margin-top: 0 !important;
                }

                .reader-content > :last-child {
                    margin-bottom: 0 !important;
                }

                .reader-content > :first-child:is(h1, h2, h3, h4, h5, h6) {
                    padding-top: 0.08em;
                }

                h1, h2, h3, h4, h5, h6 {
                    font-family: var(--font-display);
                    color: var(--text);
                    font-weight: 650;
                    line-height: 1.25;
                    letter-spacing: -0.021em;
                    margin: var(--section-space) 0 0.62em;
                    position: relative;
                    scroll-margin-top: 74px;
                }

                h1 {
                    font-size: 2.05em;
                    font-weight: 700;
                    letter-spacing: -0.028em;
                    line-height: 1.14;
                    margin-top: 0;
                    margin-bottom: 0.62em;
                }
                h2 { font-size: 1.48em; letter-spacing: -0.024em; }
                h3 { font-size: 1.19em; }
                h4 { font-size: 1.04em; }
                h5, h6 {
                    font-size: 0.86em;
                    font-weight: 600;
                    text-transform: uppercase;
                    letter-spacing: 0.07em;
                    color: var(--muted);
                }

                p, ul, ol, blockquote, pre, .table-wrap, .details-block, .math-block-source {
                    margin: var(--block-space) 0;
                }

                p:first-child {
                    margin-top: 0;
                }

                a {
                    color: var(--accent);
                    text-decoration: underline;
                    text-decoration-thickness: 1px;
                    text-underline-offset: 0.18em;
                    text-decoration-color: color-mix(in srgb, var(--accent) 34%, transparent);
                    font-weight: 500;
                    transition: text-decoration-color 120ms ease;
                }

                a:hover {
                    text-decoration-color: var(--accent);
                }

                .heading-anchor {
                    position: absolute;
                    left: -0.92em;
                    opacity: 0;
                    text-decoration: none;
                    color: color-mix(in srgb, var(--accent) 55%, transparent);
                    transition: opacity 120ms ease;
                    font-weight: 500;
                }

                h1:hover .heading-anchor,
                h2:hover .heading-anchor,
                h3:hover .heading-anchor,
                h4:hover .heading-anchor,
                h5:hover .heading-anchor,
                h6:hover .heading-anchor {
                    opacity: 1;
                }

                blockquote {
                    padding: 0.5em 0 0.5em 1.15em;
                    border-left: 3px solid color-mix(in srgb, var(--accent) 55%, transparent);
                    background: var(--blockquote-bg);
                    border-radius: 0 10px 10px 0;
                    margin: 1.25em 0 1.32em;
                    color: var(--muted);
                }

                blockquote > :first-child {
                    margin-top: 0.76em;
                }

                blockquote > :last-child {
                    margin-bottom: 0.76em;
                }

                /* Lead paragraph: the opening line after the document title
                   reads as a standfirst rather than plain body copy. */
                .reader-content > h1 + p {
                    font-size: 1.075em;
                    line-height: 1.62;
                    color: var(--muted);
                }

                ul, ol {
                    margin: 1.08em 0 1.24em;
                    padding-left: 1.45em;
                }

                li::marker {
                    color: color-mix(in srgb, var(--accent) 70%, var(--muted));
                }

                li + li {
                    margin-top: 0.42em;
                }

                li > p {
                    margin: 0.56em 0;
                }

                .task-item {
                    list-style: none;
                    display: grid;
                    grid-template-columns: 1.15em minmax(0, 1fr);
                    gap: 0.78em;
                    margin-left: -1.15em;
                }

                .task-box {
                    width: 1.05em;
                    height: 1.05em;
                    border-radius: 0.32em;
                    border: 1px solid color-mix(in srgb, var(--accent) 46%, transparent);
                    margin-top: 0.38em;
                    background: color-mix(in srgb, var(--accent-soft) 80%, transparent);
                    position: relative;
                }

                .task-item.checked .task-box::after {
                    content: "";
                    position: absolute;
                    inset: 0.2em;
                    border-radius: 0.18em;
                    background: var(--accent);
                }

                code {
                    font-family: var(--font-mono);
                    font-size: 0.855em;
                    background: var(--code-bg);
                    border-radius: 0.38em;
                    padding: 0.14em 0.38em;
                }

                pre.code-block {
                    width: 100%;
                    max-width: 100%;
                    overflow-x: auto;
                    overflow-y: hidden;
                    padding: 16px 18px;
                    background: var(--code-bg);
                    border: 1px solid var(--code-border);
                    border-radius: 12px;
                    margin: 1.24em 0 1.34em;
                }

                pre code {
                    display: block;
                    width: max-content;
                    min-width: 100%;
                    border: none;
                    background: transparent;
                    padding: 0;
                    line-height: 1.65;
                    font-size: 0.845em;
                }

                .mermaid-diagram {
                    display: flex;
                    justify-content: center;
                    width: 100%;
                    max-width: 100%;
                    overflow-x: auto;
                    padding: 18px;
                    background: var(--code-bg);
                    border: 1px solid var(--code-border);
                    border-radius: 12px;
                    margin: 1.24em 0 1.34em;
                }

                .mermaid-diagram.rendered {
                    display: block;
                    overflow: hidden;
                }

                .mermaid-diagram .mermaid-viewport {
                    display: flex;
                    justify-content: center;
                    transform-origin: 0 0;
                    will-change: transform;
                }

                .mermaid-diagram.zoomed .mermaid-viewport {
                    cursor: grab;
                }

                .mermaid-diagram.panning .mermaid-viewport {
                    cursor: grabbing;
                    user-select: none;
                }

                .mermaid-diagram svg {
                    max-width: 100%;
                    height: auto;
                }

                .mermaid-diagram .mermaid-source {
                    width: 100%;
                    margin: 0;
                    overflow-x: auto;
                }

                .mermaid-diagram .mermaid-source code {
                    display: block;
                    width: max-content;
                    min-width: 100%;
                    background: transparent;
                    padding: 0;
                    white-space: pre;
                    font-family: var(--font-mono);
                    font-size: 0.845em;
                    line-height: 1.65;
                }

                hr {
                    border: none;
                    height: 1px;
                    margin: 2.3em 0;
                    background: var(--soft-border);
                }

                .table-wrap {
                    width: 100%;
                    max-width: 100%;
                    overflow-x: auto;
                    overflow-y: hidden;
                    border: 1px solid var(--soft-border);
                    border-radius: 12px;
                    background: var(--surface-strong);
                    margin: 1.24em 0 1.36em;
                }

                table {
                    width: max-content;
                    min-width: 100%;
                    border-collapse: collapse;
                    font-size: 0.94em;
                }

                thead th {
                    font-size: 0.76em;
                    font-weight: 600;
                    letter-spacing: 0.07em;
                    text-transform: uppercase;
                    color: var(--muted);
                    background: transparent;
                    border-bottom: 1px solid var(--border);
                    white-space: nowrap;
                }

                th, td {
                    padding: 11px 15px;
                    border-bottom: 1px solid var(--soft-border);
                    vertical-align: top;
                }

                tbody tr:last-child td {
                    border-bottom: none;
                }

                img {
                    max-width: 100%;
                    height: auto;
                    border-radius: 12px;
                    display: block;
                    margin: 1.2em auto;
                    box-shadow: 0 6px 20px rgba(15, 17, 22, 0.08);
                }

                .inline-image {
                    margin: 1.3em 0;
                }

                .details-block details {
                    border: 1px solid var(--soft-border);
                    border-radius: 12px;
                    padding: 13px 16px;
                    background: var(--surface-weak);
                }

                .details-block summary {
                    cursor: pointer;
                    font-weight: 600;
                }

                .footnotes {
                    margin-top: 3.2em;
                    padding-top: 1.8em;
                    border-top: 1px solid var(--border);
                }

                .footnote-ref a,
                .footnote-backlink {
                    border-bottom: none;
                }

                .math-block-source {
                    width: 100%;
                    max-width: 100%;
                    white-space: pre-wrap;
                    overflow-x: auto;
                    overflow-y: hidden;
                    margin: 1.5em 0 1.62em;
                }

                .katex {
                    color: var(--text);
                }

                .katex-display {
                    width: 100%;
                    max-width: 100%;
                    margin: 1.78em 0 1.92em;
                    overflow-x: auto;
                    overflow-y: hidden;
                    padding: 0.28em 0 0.58em;
                    scrollbar-gutter: stable both-edges;
                }

                .katex-display > .katex {
                    display: inline-block;
                    min-width: max-content;
                    max-width: none;
                }

                .katex-display > .katex > .katex-html {
                    max-width: none;
                }

                .katex .base {
                    color: inherit;
                }

                .katex-error {
                    color: color-mix(in srgb, #c96e4d 88%, var(--text));
                    border-bottom: 1px dotted currentColor;
                    white-space: pre-wrap;
                }

                p .katex {
                    font-size: 1.03em;
                }

                mark.search-hit {
                    background: var(--search-bg);
                    border-radius: 0.25em;
                    padding: 0.02em 0.03em;
                }

                mark.search-hit.current {
                    background: var(--search-current);
                }

                @media (max-width: 880px) {
                    :root {
                        --viewport-padding-x: 22px;
                        --viewport-padding-top: 32px;
                        --viewport-padding-bottom: 76px;
                    }

                    h1 { font-size: 1.86em; }
                    h2 { font-size: 1.38em; }
                }
            </style>
            \(CodeHighlightingAssets.style)
        </head>
        <body>
            <main>
                <div class="reader-page">
                    <article id="reader-root" class="reader-content">
                        \(bodyHTML)
                    </article>
                </div>
            </main>
            \(mathScript)
            \(diagramScript)
            \(CodeHighlightingAssets.script)
            <script>
                const headingSelector = '#reader-root h1[id], #reader-root h2[id], #reader-root h3[id], #reader-root h4[id], #reader-root h5[id], #reader-root h6[id]';
                const scrollProgressPostIntervalMs = 90;
                const scrollHeadingPostIntervalMs = 120;
                const scrollSettleDelayMs = 140;
                const headingActivationOffset = 120;
                const headingSwitchDeadband = 14;

                const readerState = {
                    matches: [],
                    currentMatchIndex: 0,
                    lastCurrentMatchIndex: 0,
                    activeHeadingId: null,
                    activeHeadingIndex: -1,
                    headings: [],
                    headingOffsets: [],
                    lastProgressPercent: -1,
                    metricsDirty: true,
                    headingsDirty: true,
                    cachedMaxScroll: 0,
                    progressPostScheduled: false,
                    headingPostScheduled: false,
                    pendingForcedProgressPost: false,
                    pendingForcedHeadingPost: false,
                    lastProgressPostTimestamp: 0,
                    lastHeadingPostTimestamp: 0,
                    settlePostTimer: null,
                    diagramRenderToken: 0
                };

                function recomputeScrollMetrics() {
                    readerState.cachedMaxScroll = Math.max(
                        0,
                        document.documentElement.scrollHeight - window.innerHeight
                    );
                    readerState.metricsDirty = false;
                }

                function markMetricsDirty() {
                    readerState.metricsDirty = true;
                }

                function markHeadingsDirty() {
                    readerState.headingsDirty = true;
                }

                function refreshHeadingCache() {
                    readerState.headings = Array.from(document.querySelectorAll(headingSelector));
                    readerState.activeHeadingIndex = readerState.activeHeadingId === null
                        ? -1
                        : readerState.headings.findIndex((heading) => heading.id === readerState.activeHeadingId);
                    markHeadingsDirty();
                    refreshHeadingOffsetsIfNeeded();
                }

                function refreshHeadingOffsetsIfNeeded() {
                    if (!readerState.headingsDirty) {
                        return;
                    }
                    readerState.headingOffsets = readerState.headings.map((heading) => heading.offsetTop);
                    readerState.headingsDirty = false;
                    markMetricsDirty();
                }

                function clearScheduledSettlePost() {
                    if (readerState.settlePostTimer !== null) {
                        window.clearTimeout(readerState.settlePostTimer);
                        readerState.settlePostTimer = null;
                    }
                }

                function postProgressNow() {
                    postProgress();
                    readerState.lastProgressPostTimestamp = performance.now();
                }

                function postHeadingNow() {
                    postActiveHeading();
                    readerState.lastHeadingPostTimestamp = performance.now();
                }

                function scheduleSettlePost(delay = scrollSettleDelayMs) {
                    clearScheduledSettlePost();
                    readerState.settlePostTimer = window.setTimeout(() => {
                        readerState.settlePostTimer = null;
                        if (readerState.progressPostScheduled || readerState.headingPostScheduled) {
                            scheduleProgressPost(true);
                            scheduleHeadingPost(true);
                            return;
                        }
                        postProgressNow();
                        postHeadingNow();
                    }, delay);
                }

                function scheduleProgressPost(force = false) {
                    readerState.pendingForcedProgressPost = readerState.pendingForcedProgressPost || force;
                    if (readerState.progressPostScheduled) {
                        return;
                    }

                    readerState.progressPostScheduled = true;
                    requestAnimationFrame(() => {
                        readerState.progressPostScheduled = false;

                        const shouldForce = readerState.pendingForcedProgressPost;
                        readerState.pendingForcedProgressPost = false;

                        const now = performance.now();
                        const enoughTimeElapsed = now - readerState.lastProgressPostTimestamp >= scrollProgressPostIntervalMs;
                        if (shouldForce || enoughTimeElapsed) {
                            clearScheduledSettlePost();
                            postProgressNow();
                        }
                    });
                }

                function scheduleHeadingPost(force = false) {
                    readerState.pendingForcedHeadingPost = readerState.pendingForcedHeadingPost || force;
                    if (readerState.headingPostScheduled) {
                        return;
                    }

                    readerState.headingPostScheduled = true;
                    requestAnimationFrame(() => {
                        readerState.headingPostScheduled = false;

                        const shouldForce = readerState.pendingForcedHeadingPost;
                        readerState.pendingForcedHeadingPost = false;

                        const now = performance.now();
                        const enoughTimeElapsed = now - readerState.lastHeadingPostTimestamp >= scrollHeadingPostIntervalMs;
                        if (shouldForce || enoughTimeElapsed) {
                            clearScheduledSettlePost();
                            postHeadingNow();
                        }
                    });
                }

                function postProgress() {
                    if (readerState.metricsDirty) {
                        recomputeScrollMetrics();
                    }

                    const maxScroll = readerState.cachedMaxScroll;
                    const ratio = maxScroll <= 0 ? 0 : window.scrollY / maxScroll;
                    const percent = Math.max(0, Math.min(100, Math.round(ratio * 100)));

                    if (percent === readerState.lastProgressPercent) {
                        return;
                    }

                    readerState.lastProgressPercent = percent;

                    if (window.webkit?.messageHandlers?.readerProgress) {
                        window.webkit.messageHandlers.readerProgress.postMessage(percent / 100);
                    }
                }

                function currentHeadingSnapshot() {
                    const headings = readerState.headings;
                    if (headings.length === 0) {
                        return { id: null, index: -1 };
                    }

                    refreshHeadingOffsetsIfNeeded();

                    const offsets = readerState.headingOffsets;
                    const targetOffset = window.scrollY + headingActivationOffset;
                    let lowerBound = 0;
                    let upperBound = offsets.length - 1;
                    let bestIndex = 0;

                    while (lowerBound <= upperBound) {
                        const midpoint = (lowerBound + upperBound) >> 1;
                        if (offsets[midpoint] <= targetOffset) {
                            bestIndex = midpoint;
                            lowerBound = midpoint + 1;
                        } else {
                            upperBound = midpoint - 1;
                        }
                    }

                    const currentIndex = readerState.activeHeadingIndex;
                    if (currentIndex !== -1 && currentIndex !== bestIndex) {
                        const currentOffset = offsets[currentIndex] ?? 0;
                        const bestOffset = offsets[bestIndex] ?? 0;
                        if (Math.abs(bestOffset - targetOffset) < headingSwitchDeadband) {
                            return { id: headings[currentIndex]?.id || null, index: currentIndex };
                        }
                        if (Math.abs(currentOffset - targetOffset) < headingSwitchDeadband) {
                            return { id: headings[currentIndex]?.id || null, index: currentIndex };
                        }
                    }

                    return { id: headings[bestIndex]?.id || null, index: bestIndex };
                }

                function postActiveHeading() {
                    const nextHeading = currentHeadingSnapshot();
                    const nextHeadingId = nextHeading.id;
                    if (readerState.activeHeadingId === nextHeadingId) {
                        return;
                    }

                    readerState.activeHeadingId = nextHeadingId;
                    readerState.activeHeadingIndex = nextHeading.index;
                    if (window.webkit?.messageHandlers?.readerActiveHeading) {
                        window.webkit.messageHandlers.readerActiveHeading.postMessage(nextHeadingId);
                    }
                }

                function applyDisplaySettings(fontSize, width, colorTheme) {
                    document.documentElement.style.setProperty('--base-font-size', `${fontSize}px`);
                    document.documentElement.style.setProperty('--reader-width', `${width}px`);
                    const previousScheme = resolvedColorScheme();
                    if (colorTheme && colorTheme !== 'auto') {
                        document.documentElement.setAttribute('data-theme', colorTheme);
                    } else {
                        document.documentElement.removeAttribute('data-theme');
                    }
                    if (resolvedColorScheme() !== previousScheme) {
                        renderDiagrams();
                    }
                    requestAnimationFrame(() => {
                        markMetricsDirty();
                        markHeadingsDirty();
                        scheduleProgressPost(true);
                        scheduleHeadingPost(true);
                        scheduleSettlePost(0);
                    });
                }

                function decodeBase64Source(encoded) {
                    try {
                        const binary = atob(encoded);
                        const bytes = Uint8Array.from(binary, character => character.charCodeAt(0));
                        return new TextDecoder().decode(bytes);
                    } catch (error) {
                        console.warn('Failed to decode block source.', error);
                        return '';
                    }
                }

                function renderMath() {
                    if (typeof katex === 'undefined') {
                        return;
                    }

                    const placeholders = Array.from(document.querySelectorAll('.math-placeholder[data-math-source]'));
                    for (const node of placeholders) {
                        const source = decodeBase64Source(node.getAttribute('data-math-source') || '');
                        const displayMode = node.classList.contains('display');

                        try {
                            katex.render(source, node, {
                                displayMode,
                                throwOnError: false,
                                strict: 'ignore',
                                output: 'htmlAndMathml'
                            });
                        } catch (error) {
                            node.textContent = source;
                            node.classList.add('math-fallback');
                            console.warn('Math rendering failed.', error);
                        }
                    }
                }

                function resolvedColorScheme() {
                    const declared = document.documentElement.getAttribute('data-theme');
                    if (declared === 'dark' || declared === 'sepia' || declared === 'light') {
                        return declared;
                    }
                    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
                }

                function mermaidThemeName() {
                    const scheme = resolvedColorScheme();
                    if (scheme === 'dark') return 'dark';
                    if (scheme === 'sepia') return 'neutral';
                    return 'default';
                }

                function showDiagramSource(node, source) {
                    node.classList.remove('rendered');
                    node.textContent = '';
                    const pre = document.createElement('pre');
                    pre.className = 'mermaid-source';
                    const code = document.createElement('code');
                    code.textContent = source;
                    pre.appendChild(code);
                    node.appendChild(pre);
                }

                async function renderDiagrams() {
                    if (typeof mermaid === 'undefined') return;

                    const nodes = Array.from(document.querySelectorAll('.mermaid-diagram[data-mermaid-source]'));
                    if (nodes.length === 0) return;

                    // A later theme change supersedes an in-flight pass.
                    const token = ++readerState.diagramRenderToken;
                    mermaid.initialize({
                        startOnLoad: false,
                        securityLevel: 'strict',
                        theme: mermaidThemeName(),
                        fontFamily: getComputedStyle(document.body).fontFamily
                    });

                    for (let index = 0; index < nodes.length; index += 1) {
                        const node = nodes[index];
                        const source = decodeBase64Source(node.getAttribute('data-mermaid-source') || '');
                        if (!source) continue;

                        const renderID = `mermaid-diagram-${token}-${index}`;
                        try {
                            const { svg, bindFunctions } = await mermaid.render(renderID, source);
                            if (token !== readerState.diagramRenderToken) return;
                            const viewport = document.createElement('div');
                            viewport.className = 'mermaid-viewport';
                            viewport.innerHTML = svg;
                            node.textContent = '';
                            node.appendChild(viewport);
                            node.classList.add('rendered');
                            bindFunctions?.(viewport);
                            // A re-render (theme change) keeps whatever scale the reader had set.
                            applyDiagramView(node);
                        } catch (error) {
                            if (token !== readerState.diagramRenderToken) return;
                            // Mermaid leaves its measuring node behind when a diagram fails to parse.
                            document.getElementById(`d${renderID}`)?.remove();
                            showDiagramSource(node, source);
                            console.warn('Diagram rendering failed.', error);
                        }
                    }

                    markMetricsDirty();
                    markHeadingsDirty();
                    scheduleProgressPost(true);
                    scheduleHeadingPost(true);
                    scheduleSettlePost(0);
                }

                const diagramViews = new WeakMap();
                const minDiagramScale = 1;
                const maxDiagramScale = 5;

                function diagramView(diagram) {
                    let view = diagramViews.get(diagram);
                    if (!view) {
                        view = { scale: 1, x: 0, y: 0 };
                        diagramViews.set(diagram, view);
                    }
                    return view;
                }

                /// The untransformed content box the viewport is laid out in.
                function diagramContentBox(diagram) {
                    const rect = diagram.getBoundingClientRect();
                    const style = getComputedStyle(diagram);
                    const left = parseFloat(style.borderLeftWidth) + parseFloat(style.paddingLeft);
                    const top = parseFloat(style.borderTopWidth) + parseFloat(style.paddingTop);
                    return {
                        left: rect.left + left,
                        top: rect.top + top,
                        width: diagram.clientWidth - left - parseFloat(style.paddingRight),
                        height: diagram.clientHeight - top - parseFloat(style.paddingBottom)
                    };
                }

                /// Keeps the scaled diagram covering its block instead of drifting
                /// off into the padding.
                function clampDiagramPan(diagram, view) {
                    const viewport = diagram.querySelector('.mermaid-viewport');
                    if (!viewport) return;

                    const box = diagramContentBox(diagram);
                    const scaledWidth = viewport.offsetWidth * view.scale;
                    const scaledHeight = viewport.offsetHeight * view.scale;
                    view.x = scaledWidth <= box.width ? 0 : Math.min(0, Math.max(box.width - scaledWidth, view.x));
                    view.y = scaledHeight <= box.height ? 0 : Math.min(0, Math.max(box.height - scaledHeight, view.y));
                }

                function applyDiagramView(diagram) {
                    const viewport = diagram.querySelector('.mermaid-viewport');
                    if (!viewport) return;

                    const view = diagramView(diagram);
                    clampDiagramPan(diagram, view);
                    viewport.style.transform = `translate(${view.x}px, ${view.y}px) scale(${view.scale})`;
                    diagram.classList.toggle('zoomed', view.scale > 1);
                }

                /// Scales the diagram under the pointer, holding the point being
                /// pinched in place. Called from the trackpad pinch gesture.
                function magnifyDiagram(clientX, clientY, magnification) {
                    const diagram = document.elementFromPoint(clientX, clientY)?.closest('.mermaid-diagram.rendered');
                    if (!diagram) return false;

                    const view = diagramView(diagram);
                    const nextScale = Math.min(maxDiagramScale, Math.max(minDiagramScale, view.scale * (1 + magnification)));
                    if (nextScale === view.scale) return true;

                    const box = diagramContentBox(diagram);
                    const anchorX = clientX - box.left;
                    const anchorY = clientY - box.top;
                    const ratio = nextScale / view.scale;
                    view.x = anchorX - (anchorX - view.x) * ratio;
                    view.y = anchorY - (anchorY - view.y) * ratio;
                    view.scale = nextScale;
                    if (view.scale === minDiagramScale) {
                        view.x = 0;
                        view.y = 0;
                    }

                    applyDiagramView(diagram);
                    return true;
                }

                function resetDiagramZoom(diagram) {
                    const view = diagramView(diagram);
                    view.scale = 1;
                    view.x = 0;
                    view.y = 0;
                    applyDiagramView(diagram);
                }

                function installDiagramPanning() {
                    let panning = null;

                    document.addEventListener('pointerdown', event => {
                        const diagram = event.target.closest?.('.mermaid-diagram.zoomed');
                        if (!diagram || event.button !== 0) return;
                        panning = { diagram, x: event.clientX, y: event.clientY, pointerId: event.pointerId };
                        diagram.classList.add('panning');
                        diagram.setPointerCapture?.(event.pointerId);
                        event.preventDefault();
                    });

                    document.addEventListener('pointermove', event => {
                        if (!panning) return;
                        const view = diagramView(panning.diagram);
                        view.x += event.clientX - panning.x;
                        view.y += event.clientY - panning.y;
                        panning.x = event.clientX;
                        panning.y = event.clientY;
                        applyDiagramView(panning.diagram);
                    });

                    const endPan = () => {
                        if (!panning) return;
                        panning.diagram.classList.remove('panning');
                        panning.diagram.releasePointerCapture?.(panning.pointerId);
                        panning = null;
                    };
                    document.addEventListener('pointerup', endPan);
                    document.addEventListener('pointercancel', endPan);

                    document.addEventListener('dblclick', event => {
                        const diagram = event.target.closest?.('.mermaid-diagram.rendered');
                        if (!diagram) return;
                        resetDiagramZoom(diagram);
                    });
                }

                function clearSearchHighlights() {
                    const marks = Array.from(document.querySelectorAll('mark.search-hit'));
                    const parentsToNormalize = new Set();
                    for (const mark of marks) {
                        const parent = mark.parentNode;
                        if (!parent) continue;
                        parent.replaceChild(document.createTextNode(mark.textContent || ''), mark);
                        parentsToNormalize.add(parent);
                    }
                    for (const parent of parentsToNormalize) {
                        parent.normalize();
                    }
                    readerState.matches = [];
                    readerState.currentMatchIndex = 0;
                    readerState.lastCurrentMatchIndex = 0;
                }

                function highlightNode(node, query) {
                    const source = node.nodeValue;
                    const haystack = source.toLowerCase();
                    let searchIndex = haystack.indexOf(query);
                    if (searchIndex === -1) return [];

                    const fragment = document.createDocumentFragment();
                    const matches = [];
                    let cursor = 0;

                    while (searchIndex !== -1) {
                        if (searchIndex > cursor) {
                            fragment.appendChild(document.createTextNode(source.slice(cursor, searchIndex)));
                        }

                        const mark = document.createElement('mark');
                        mark.className = 'search-hit';
                        mark.textContent = source.slice(searchIndex, searchIndex + query.length);
                        fragment.appendChild(mark);
                        matches.push(mark);

                        cursor = searchIndex + query.length;
                        searchIndex = haystack.indexOf(query, cursor);
                    }

                    if (cursor < source.length) {
                        fragment.appendChild(document.createTextNode(source.slice(cursor)));
                    }

                    node.parentNode.replaceChild(fragment, node);
                    return matches;
                }

                function withSmoothScroll(action) {
                    const root = document.documentElement;
                    root.classList.add('smooth-scroll');
                    try {
                        action();
                    } finally {
                        window.setTimeout(() => {
                            root.classList.remove('smooth-scroll');
                        }, 600);
                    }
                }

                function updateCurrentSearchResult(scrollIntoView = true) {
                    const previous = readerState.matches[readerState.lastCurrentMatchIndex - 1];
                    if (previous) {
                        previous.classList.remove('current');
                    }

                    const current = readerState.matches[readerState.currentMatchIndex - 1];
                    if (current) {
                        current.classList.add('current');
                    }
                    readerState.lastCurrentMatchIndex = readerState.currentMatchIndex;

                    if (scrollIntoView && current) {
                        withSmoothScroll(() => {
                            current.scrollIntoView({ behavior: 'smooth', block: 'center' });
                        });
                        scheduleSettlePost();
                    }

                    markMetricsDirty();
                    markHeadingsDirty();
                    scheduleProgressPost(true);
                    scheduleHeadingPost(true);
                    return { count: readerState.matches.length, current: readerState.currentMatchIndex };
                }

                function performSearch(query) {
                    clearSearchHighlights();
                    if (!query) {
                        markMetricsDirty();
                        markHeadingsDirty();
                        scheduleProgressPost(true);
                        scheduleHeadingPost(true);
                        return { count: 0, current: 0 };
                    }

                    const root = document.getElementById('reader-root');
                    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, {
                        acceptNode(node) {
                            if (!node.nodeValue || !node.nodeValue.trim()) return NodeFilter.FILTER_REJECT;
                            if (node.parentElement?.closest('.katex, .katex-mathml, .mermaid-diagram.rendered, script, style, mark')) return NodeFilter.FILTER_REJECT;
                            return NodeFilter.FILTER_ACCEPT;
                        }
                    });

                    const textNodes = [];
                    while (walker.nextNode()) {
                        textNodes.push(walker.currentNode);
                    }

                    const normalized = query.toLowerCase();
                    for (const node of textNodes) {
                        readerState.matches.push(...highlightNode(node, normalized));
                    }

                    readerState.currentMatchIndex = readerState.matches.length > 0 ? 1 : 0;
                    markMetricsDirty();
                    markHeadingsDirty();
                    return updateCurrentSearchResult();
                }

                function stepSearch(direction) {
                    if (readerState.matches.length === 0) {
                        return { count: 0, current: 0 };
                    }

                    const total = readerState.matches.length;
                    const delta = direction < 0 ? -1 : 1;
                    readerState.currentMatchIndex = ((readerState.currentMatchIndex - 1 + delta + total) % total) + 1;
                    return updateCurrentSearchResult();
                }

                function scrollToAnchor(anchor) {
                    const element = document.getElementById(anchor);
                    if (element) {
                        withSmoothScroll(() => {
                            element.scrollIntoView({ behavior: 'smooth', block: 'start' });
                        });
                        scheduleSettlePost();
                        return true;
                    }
                    return false;
                }

                window.reader = {
                    applyDisplaySettings,
                    magnifyDiagram,
                    performSearch,
                    stepSearch,
                    scrollToAnchor
                };

                function initialize() {
                    renderMath();
                    renderDiagrams();
                    installDiagramPanning();
                    highlightCodeBlocks();
                    refreshHeadingCache();
                    recomputeScrollMetrics();
                    postProgressNow();
                    postHeadingNow();

                    requestAnimationFrame(() => {
                        refreshHeadingOffsetsIfNeeded();
                        recomputeScrollMetrics();
                        postProgressNow();
                        postHeadingNow();
                    });
                }

                if (document.readyState === 'complete') {
                    initialize();
                } else {
                    window.addEventListener('load', initialize, { once: true });
                }

                window.addEventListener('scroll', () => {
                    scheduleProgressPost();
                    scheduleHeadingPost();
                    scheduleSettlePost();
                }, { passive: true });
                window.addEventListener('resize', () => {
                    markMetricsDirty();
                    markHeadingsDirty();
                    scheduleProgressPost(true);
                    scheduleHeadingPost(true);
                    scheduleSettlePost();
                }, { passive: true });

                if (typeof ResizeObserver === 'function') {
                    const bodyObserver = new ResizeObserver(() => {
                        markMetricsDirty();
                        markHeadingsDirty();
                        scheduleProgressPost(true);
                        scheduleHeadingPost(true);
                        scheduleSettlePost();
                    });
                    bodyObserver.observe(document.getElementById('reader-root'));
                }
            </script>
        </body>
        </html>
        """
    }
}
