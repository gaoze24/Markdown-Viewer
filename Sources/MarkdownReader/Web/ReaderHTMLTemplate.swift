import Foundation

enum ReaderHTMLTemplate {
    static let mathPlaceholderClass = "math-placeholder"

    static func makeDocument(bodyHTML: String, settings: ReaderDisplaySettings) -> String {
        let mathAssets = BundledMathAssets.shared
        let includeMath = bodyHTML.contains(mathPlaceholderClass)

        let mathStyle = includeMath
            ? "<style>\(mathAssets.katexCSS)</style>"
            : ""
        let mathScript = includeMath
            ? "<script>\(mathAssets.katexScript)</script>"
            : ""

        return """
        <!doctype html>
        <html lang="en">
        <head>
            <meta charset="utf-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1" />
            \(mathStyle)
            <style>
                :root {
                    color-scheme: light dark;
                    --reader-width: \(Int(settings.readingWidth))px;
                    --base-font-size: \(String(format: "%.1f", settings.baseFontSize))px;
                    --viewport-padding-x: clamp(24px, 3.8vw, 52px);
                    --viewport-padding-top: 40px;
                    --viewport-padding-bottom: 88px;
                    --block-space: 1.18em;
                    --section-space: 2.12em;
                    --page-bg: #f7f2e8;
                    --page-bg-secondary: #f1eadf;
                    --page-grid: rgba(93, 74, 53, 0.03);
                    --text: #2c241d;
                    --muted: #786d61;
                    --border: rgba(82, 62, 42, 0.14);
                    --soft-border: rgba(82, 62, 42, 0.08);
                    --surface-weak: rgba(251, 245, 237, 0.74);
                    --surface-strong: rgba(244, 236, 226, 0.9);
                    --blockquote-bg: rgba(164, 133, 95, 0.08);
                    --code-bg: rgba(98, 78, 56, 0.07);
                    --code-border: rgba(98, 78, 56, 0.11);
                    --table-row: rgba(93, 73, 53, 0.03);
                    --accent: #8b6a46;
                    --accent-soft: rgba(139, 106, 70, 0.14);
                    --search-bg: rgba(228, 191, 112, 0.34);
                    --search-current: rgba(209, 151, 75, 0.38);
                }

                @media (prefers-color-scheme: dark) {
                    :root {
                        --page-bg: #1a1511;
                        --page-bg-secondary: #201915;
                        --page-grid: rgba(241, 229, 214, 0.025);
                        --text: #eee3d6;
                        --muted: #b3a391;
                        --border: rgba(238, 223, 204, 0.12);
                        --soft-border: rgba(238, 223, 204, 0.07);
                        --surface-weak: rgba(255, 246, 234, 0.028);
                        --surface-strong: rgba(255, 245, 231, 0.048);
                        --blockquote-bg: rgba(201, 161, 107, 0.075);
                        --code-bg: rgba(255, 243, 228, 0.048);
                        --code-border: rgba(255, 243, 228, 0.085);
                        --table-row: rgba(255, 243, 228, 0.024);
                        --accent: #d0aa79;
                        --accent-soft: rgba(208, 170, 121, 0.14);
                        --search-bg: rgba(196, 150, 74, 0.32);
                        --search-current: rgba(216, 169, 93, 0.46);
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
                    background:
                        linear-gradient(180deg, color-mix(in srgb, var(--page-bg-secondary) 70%, var(--page-bg) 30%) 0%, var(--page-bg) 18%, var(--page-bg) 100%);
                }

                body {
                    margin: 0;
                    color: var(--text);
                    font-family: "New York", "Iowan Old Style", "Palatino Linotype", "Book Antiqua", ui-serif, serif;
                    font-size: var(--base-font-size);
                    line-height: 1.72;
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
                    font-family: "SF Pro Display", "Avenir Next", system-ui, sans-serif;
                    color: var(--text);
                    line-height: 1.18;
                    letter-spacing: -0.03em;
                    margin: var(--section-space) 0 0.72em;
                    position: relative;
                    scroll-margin-top: 74px;
                }

                h1 { font-size: 2.34em; margin-top: 0; margin-bottom: 0.82em; line-height: 1.1; }
                h2 { font-size: 1.76em; }
                h3 { font-size: 1.38em; }
                h4 { font-size: 1.16em; }
                h5, h6 { font-size: 1em; text-transform: uppercase; letter-spacing: 0.04em; color: var(--muted); }

                p, ul, ol, blockquote, pre, .table-wrap, .details-block, .math-block-source {
                    margin: var(--block-space) 0;
                }

                p:first-child {
                    margin-top: 0;
                }

                a {
                    color: var(--accent);
                    text-decoration: none;
                    border-bottom: 1px solid color-mix(in srgb, var(--accent) 32%, transparent);
                }

                a:hover {
                    color: color-mix(in srgb, var(--accent) 90%, var(--text) 10%);
                    border-bottom-color: var(--accent);
                }

                .heading-anchor {
                    position: absolute;
                    left: -1.05em;
                    opacity: 0;
                    border-bottom: none;
                    color: color-mix(in srgb, var(--accent) 72%, white 10%);
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
                    padding: 0.4em 0 0.4em 1.18em;
                    border-left: 3px solid color-mix(in srgb, var(--accent) 40%, transparent);
                    background: var(--blockquote-bg);
                    border-radius: 0 14px 14px 0;
                    margin: 1.3em 0 1.38em;
                }

                blockquote > :first-child {
                    margin-top: 0.76em;
                }

                blockquote > :last-child {
                    margin-bottom: 0.76em;
                }

                ul, ol {
                    margin: 1.08em 0 1.24em;
                    padding-left: 1.45em;
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
                    font-family: "SF Mono", "JetBrains Mono", "Menlo", monospace;
                    font-size: 0.88em;
                    background: var(--code-bg);
                    border: 1px solid var(--code-border);
                    border-radius: 0.5em;
                    padding: 0.15em 0.45em;
                }

                pre.code-block {
                    width: 100%;
                    max-width: 100%;
                    overflow-x: auto;
                    overflow-y: hidden;
                    padding: 18px 20px;
                    background: color-mix(in srgb, var(--code-bg) 94%, var(--page-bg) 6%);
                    border: 1px solid var(--code-border);
                    border-radius: 14px;
                    margin: 1.3em 0 1.42em;
                }

                pre code {
                    display: block;
                    width: max-content;
                    min-width: 100%;
                    border: none;
                    background: transparent;
                    padding: 0;
                    line-height: 1.62;
                    font-size: 0.85em;
                }

                hr {
                    border: none;
                    height: 1px;
                    margin: 2.45em 0;
                    background: var(--border);
                }

                .table-wrap {
                    width: 100%;
                    max-width: 100%;
                    overflow-x: auto;
                    overflow-y: hidden;
                    border: 1px solid var(--soft-border);
                    border-radius: 14px;
                    background: color-mix(in srgb, var(--surface-strong) 90%, var(--page-bg) 10%);
                    margin: 1.28em 0 1.4em;
                }

                table {
                    width: max-content;
                    min-width: 100%;
                    border-collapse: collapse;
                }

                thead th {
                    font-family: "SF Pro Text", system-ui, sans-serif;
                    font-size: 0.83em;
                    letter-spacing: 0.04em;
                    text-transform: uppercase;
                    color: var(--muted);
                    background: color-mix(in srgb, var(--surface-strong) 70%, transparent);
                }

                th, td {
                    padding: 12px 14px;
                    border-bottom: 1px solid var(--soft-border);
                    vertical-align: top;
                }

                tbody tr:nth-child(even) {
                    background: var(--table-row);
                }

                img {
                    max-width: 100%;
                    height: auto;
                    border-radius: 16px;
                    display: block;
                    margin: 1.2em auto;
                    box-shadow: 0 10px 22px rgba(59, 45, 33, 0.07);
                }

                .inline-image {
                    margin: 1.3em 0;
                }

                .details-block details {
                    border: 1px solid var(--soft-border);
                    border-radius: 14px;
                    padding: 14px 18px;
                    background: color-mix(in srgb, var(--surface-strong) 92%, var(--page-bg) 8%);
                }

                .details-block summary {
                    cursor: pointer;
                    font-family: "SF Pro Text", system-ui, sans-serif;
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
                        --viewport-padding-x: 20px;
                        --viewport-padding-top: 30px;
                        --viewport-padding-bottom: 72px;
                    }

                    h1 { font-size: 2.05em; }
                    h2 { font-size: 1.58em; }
                }
            </style>
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
                    activeHeadingId: null,
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
                    settlePostTimer: null
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

                function currentHeadingId() {
                    const headings = readerState.headings;
                    if (headings.length === 0) {
                        return null;
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

                    const currentIndex = readerState.activeHeadingId ? headings.findIndex((heading) => heading.id === readerState.activeHeadingId) : -1;
                    if (currentIndex !== -1 && currentIndex !== bestIndex) {
                        const currentOffset = offsets[currentIndex] ?? 0;
                        const bestOffset = offsets[bestIndex] ?? 0;
                        if (Math.abs(bestOffset - targetOffset) < headingSwitchDeadband) {
                            return headings[currentIndex]?.id || null;
                        }
                        if (Math.abs(currentOffset - targetOffset) < headingSwitchDeadband) {
                            return headings[currentIndex]?.id || null;
                        }
                    }

                    return headings[bestIndex]?.id || null;
                }

                function postActiveHeading() {
                    const nextHeadingId = currentHeadingId();
                    if (readerState.activeHeadingId === nextHeadingId) {
                        return;
                    }

                    readerState.activeHeadingId = nextHeadingId;
                    if (window.webkit?.messageHandlers?.readerActiveHeading) {
                        window.webkit.messageHandlers.readerActiveHeading.postMessage(nextHeadingId);
                    }
                }

                function applyDisplaySettings(fontSize, width) {
                    document.documentElement.style.setProperty('--base-font-size', `${fontSize}px`);
                    document.documentElement.style.setProperty('--reader-width', `${width}px`);
                    requestAnimationFrame(() => {
                        markMetricsDirty();
                        markHeadingsDirty();
                        scheduleProgressPost(true);
                        scheduleHeadingPost(true);
                        scheduleSettlePost(0);
                    });
                }

                function decodeMathSource(encoded) {
                    try {
                        const binary = atob(encoded);
                        const bytes = Uint8Array.from(binary, character => character.charCodeAt(0));
                        return new TextDecoder().decode(bytes);
                    } catch (error) {
                        console.warn('Failed to decode math source.', error);
                        return '';
                    }
                }

                function renderMath() {
                    if (typeof katex === 'undefined') {
                        return;
                    }

                    const placeholders = Array.from(document.querySelectorAll('.math-placeholder[data-math-source]'));
                    for (const node of placeholders) {
                        const source = decodeMathSource(node.getAttribute('data-math-source') || '');
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

                function clearSearchHighlights() {
                    const marks = Array.from(document.querySelectorAll('mark.search-hit'));
                    for (const mark of marks) {
                        const parent = mark.parentNode;
                        if (!parent) continue;
                        parent.replaceChild(document.createTextNode(mark.textContent || ''), mark);
                        parent.normalize();
                    }
                    readerState.matches = [];
                    readerState.currentMatchIndex = 0;
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
                    readerState.matches.forEach((mark, index) => {
                        mark.classList.toggle('current', index === readerState.currentMatchIndex - 1);
                    });

                    const current = readerState.matches[readerState.currentMatchIndex - 1];
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
                            if (node.parentElement?.closest('.katex, .katex-mathml, script, style, mark')) return NodeFilter.FILTER_REJECT;
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
                    performSearch,
                    stepSearch,
                    scrollToAnchor
                };

                function initialize() {
                    renderMath();
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
