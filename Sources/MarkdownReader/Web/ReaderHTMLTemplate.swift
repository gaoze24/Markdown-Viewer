import Foundation

enum ReaderHTMLTemplate {
    static func makeDocument(bodyHTML: String, settings: ReaderDisplaySettings) -> String {
        let mathAssets = BundledMathAssets.shared

        return """
        <!doctype html>
        <html lang="en">
        <head>
            <meta charset="utf-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1" />
            <style>
                \(mathAssets.katexCSS)
            </style>
            <style>
                :root {
                    color-scheme: light dark;
                    --reader-width: \(Int(settings.readingWidth))px;
                    --base-font-size: \(String(format: "%.1f", settings.baseFontSize))px;
                    --page-bg: #f4f1e9;
                    --page-bg-secondary: #ece8df;
                    --page-grid: rgba(34, 41, 43, 0.032);
                    --text: #1d2426;
                    --muted: #647072;
                    --border: rgba(35, 41, 43, 0.12);
                    --soft-border: rgba(35, 41, 43, 0.08);
                    --surface-weak: rgba(255, 255, 255, 0.32);
                    --surface-strong: rgba(255, 255, 255, 0.5);
                    --blockquote-bg: rgba(214, 221, 217, 0.32);
                    --code-bg: rgba(48, 60, 62, 0.085);
                    --code-border: rgba(48, 60, 62, 0.12);
                    --table-row: rgba(0, 0, 0, 0.018);
                    --accent: #40675f;
                    --accent-soft: rgba(64, 103, 95, 0.14);
                    --search-bg: rgba(235, 198, 92, 0.42);
                    --search-current: rgba(218, 141, 53, 0.46);
                }

                @media (prefers-color-scheme: dark) {
                    :root {
                        --page-bg: #131617;
                        --page-bg-secondary: #16191a;
                        --page-grid: rgba(255, 255, 255, 0.03);
                        --text: #e8ebe7;
                        --muted: #a1a8a6;
                        --border: rgba(255, 255, 255, 0.09);
                        --soft-border: rgba(255, 255, 255, 0.055);
                        --surface-weak: rgba(255, 255, 255, 0.03);
                        --surface-strong: rgba(255, 255, 255, 0.06);
                        --blockquote-bg: rgba(90, 101, 98, 0.2);
                        --code-bg: rgba(255, 255, 255, 0.055);
                        --code-border: rgba(255, 255, 255, 0.08);
                        --table-row: rgba(255, 255, 255, 0.028);
                        --accent: #9abdae;
                        --accent-soft: rgba(154, 189, 174, 0.12);
                        --search-bg: rgba(196, 145, 47, 0.34);
                        --search-current: rgba(214, 163, 67, 0.56);
                    }
                }

                * {
                    box-sizing: border-box;
                }

                html, body {
                    min-height: 100%;
                }

                html {
                    scroll-behavior: smooth;
                    background:
                        linear-gradient(180deg, transparent, rgba(255, 255, 255, 0.08)),
                        linear-gradient(180deg, var(--page-bg), var(--page-bg-secondary));
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
                    background:
                        linear-gradient(180deg, rgba(255, 255, 255, 0.04), transparent 22%),
                        linear-gradient(90deg, transparent 0, transparent calc(50% - var(--reader-width) / 2 - 64px), var(--page-grid) calc(50% - var(--reader-width) / 2 - 64px), var(--page-grid) calc(50% - var(--reader-width) / 2 - 63px), transparent calc(50% - var(--reader-width) / 2 - 63px), transparent calc(50% + var(--reader-width) / 2 + 63px), var(--page-grid) calc(50% + var(--reader-width) / 2 + 63px), var(--page-grid) calc(50% + var(--reader-width) / 2 + 64px), transparent calc(50% + var(--reader-width) / 2 + 64px), transparent 100%);
                }

                main {
                    width: min(100%, calc(var(--reader-width) + 96px));
                    margin: 0 auto;
                    padding: 34px 48px 58px;
                    animation: fadeIn 180ms ease-out;
                }

                @keyframes fadeIn {
                    from { opacity: 0; transform: translateY(6px); }
                    to { opacity: 1; transform: translateY(0); }
                }

                h1, h2, h3, h4, h5, h6 {
                    font-family: "SF Pro Display", "Avenir Next", system-ui, sans-serif;
                    color: var(--text);
                    line-height: 1.14;
                    letter-spacing: -0.03em;
                    margin: 1.8em 0 0.65em;
                    position: relative;
                    scroll-margin-top: 32px;
                }

                h1 { font-size: 2.34em; margin-top: 0.18em; }
                h2 { font-size: 1.76em; }
                h3 { font-size: 1.38em; }
                h4 { font-size: 1.16em; }
                h5, h6 { font-size: 1em; text-transform: uppercase; letter-spacing: 0.04em; color: var(--muted); }

                p, ul, ol, blockquote, pre, table, .details-block, .math-block-source {
                    margin: 1.1em 0;
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
                    padding: 0.18em 0 0.18em 1.18em;
                    border-left: 3px solid color-mix(in srgb, var(--accent) 40%, transparent);
                    background: var(--blockquote-bg);
                    border-radius: 0 16px 16px 0;
                }

                blockquote > :first-child {
                    margin-top: 0.76em;
                }

                blockquote > :last-child {
                    margin-bottom: 0.76em;
                }

                ul, ol {
                    padding-left: 1.45em;
                }

                li + li {
                    margin-top: 0.38em;
                }

                li > p {
                    margin: 0.5em 0;
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
                    overflow: auto;
                    padding: 18px 20px;
                    background: linear-gradient(180deg, color-mix(in srgb, var(--code-bg) 84%, transparent), color-mix(in srgb, var(--code-bg) 100%, transparent));
                    border: 1px solid var(--code-border);
                    border-radius: 16px;
                }

                pre code {
                    display: block;
                    border: none;
                    background: transparent;
                    padding: 0;
                    line-height: 1.62;
                    font-size: 0.85em;
                }

                hr {
                    border: none;
                    height: 1px;
                    margin: 2.2em 0;
                    background: linear-gradient(90deg, transparent, var(--border), transparent);
                }

                .table-wrap {
                    overflow-x: auto;
                    border: 1px solid var(--soft-border);
                    border-radius: 16px;
                    background: var(--surface-weak);
                }

                table {
                    width: 100%;
                    border-collapse: collapse;
                    min-width: 460px;
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
                    box-shadow: 0 14px 28px rgba(0, 0, 0, 0.1);
                }

                .inline-image {
                    margin: 1.3em 0;
                }

                .details-block details {
                    border: 1px solid var(--soft-border);
                    border-radius: 16px;
                    padding: 14px 18px;
                    background: color-mix(in srgb, var(--surface-strong) 80%, transparent);
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
                    white-space: pre-wrap;
                    overflow-x: auto;
                }

                .katex {
                    color: var(--text);
                }

                .katex-display {
                    margin: 1.5em 0 1.6em;
                    overflow-x: auto;
                    overflow-y: hidden;
                    padding: 0.2em 0.16em 0.45em;
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
                    main {
                        width: 100%;
                        padding: 22px 18px 40px;
                    }

                    h1 { font-size: 2.05em; }
                    h2 { font-size: 1.58em; }
                }
            </style>
        </head>
        <body>
            <main id="reader-root">
                \(bodyHTML)
            </main>
            <script>
                \(mathAssets.katexScript)
            </script>
            <script>
                const readerState = {
                    matches: [],
                    currentMatchIndex: 0
                };

                function postProgress() {
                    const maxScroll = document.documentElement.scrollHeight - window.innerHeight;
                    const progress = maxScroll <= 0 ? 0 : window.scrollY / maxScroll;
                    if (window.webkit?.messageHandlers?.readerProgress) {
                        window.webkit.messageHandlers.readerProgress.postMessage(progress);
                    }
                }

                function applyDisplaySettings(fontSize, width) {
                    document.documentElement.style.setProperty('--base-font-size', `${fontSize}px`);
                    document.documentElement.style.setProperty('--reader-width', `${width}px`);
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

                function updateCurrentSearchResult(scrollIntoView = true) {
                    readerState.matches.forEach((mark, index) => {
                        mark.classList.toggle('current', index === readerState.currentMatchIndex - 1);
                    });

                    const current = readerState.matches[readerState.currentMatchIndex - 1];
                    if (scrollIntoView && current) {
                        current.scrollIntoView({ behavior: 'smooth', block: 'center' });
                    }

                    return { count: readerState.matches.length, current: readerState.currentMatchIndex };
                }

                function performSearch(query) {
                    clearSearchHighlights();
                    if (!query) {
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
                        element.scrollIntoView({ behavior: 'smooth', block: 'start' });
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

                window.addEventListener('load', () => {
                    renderMath();
                    postProgress();
                });
                window.addEventListener('scroll', postProgress, { passive: true });
            </script>
        </body>
        </html>
        """
    }
}
