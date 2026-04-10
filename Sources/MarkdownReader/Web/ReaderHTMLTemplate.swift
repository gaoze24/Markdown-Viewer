import Foundation

enum ReaderHTMLTemplate {
    static func makeDocument(bodyHTML: String, settings: ReaderDisplaySettings) -> String {
        """
        <!doctype html>
        <html lang="en">
        <head>
            <meta charset="utf-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1" />
            <style>
                :root {
                    color-scheme: light dark;
                    --reader-width: \(Int(settings.readingWidth))px;
                    --base-font-size: \(String(format: "%.1f", settings.baseFontSize))px;
                    --page-bg: #f7f4ec;
                    --page-bg-secondary: #f1eee6;
                    --paper-bg: rgba(255, 252, 246, 0.82);
                    --text: #1d2426;
                    --muted: #5c6668;
                    --border: rgba(35, 41, 43, 0.12);
                    --soft-border: rgba(35, 41, 43, 0.08);
                    --blockquote-bg: rgba(214, 221, 217, 0.35);
                    --code-bg: rgba(48, 60, 62, 0.08);
                    --code-border: rgba(48, 60, 62, 0.12);
                    --table-row: rgba(0, 0, 0, 0.018);
                    --accent: #40675f;
                    --accent-soft: rgba(64, 103, 95, 0.12);
                    --search-bg: rgba(235, 198, 92, 0.42);
                    --search-current: rgba(218, 141, 53, 0.46);
                    --shadow: 0 26px 56px rgba(24, 28, 29, 0.08);
                }

                @media (prefers-color-scheme: dark) {
                    :root {
                        --page-bg: #121415;
                        --page-bg-secondary: #16191a;
                        --paper-bg: rgba(24, 27, 28, 0.84);
                        --text: #e8ebe7;
                        --muted: #9ba3a1;
                        --border: rgba(255, 255, 255, 0.08);
                        --soft-border: rgba(255, 255, 255, 0.05);
                        --blockquote-bg: rgba(90, 101, 98, 0.22);
                        --code-bg: rgba(255, 255, 255, 0.06);
                        --code-border: rgba(255, 255, 255, 0.08);
                        --table-row: rgba(255, 255, 255, 0.028);
                        --accent: #96bbac;
                        --accent-soft: rgba(150, 187, 172, 0.12);
                        --search-bg: rgba(196, 145, 47, 0.34);
                        --search-current: rgba(214, 163, 67, 0.56);
                        --shadow: 0 28px 60px rgba(0, 0, 0, 0.36);
                    }
                }

                * {
                    box-sizing: border-box;
                }

                html {
                    scroll-behavior: smooth;
                    background:
                        radial-gradient(circle at top, rgba(255, 255, 255, 0.35), transparent 48%),
                        linear-gradient(180deg, var(--page-bg), var(--page-bg-secondary));
                }

                body {
                    margin: 0;
                    padding: 28px 22px 52px;
                    color: var(--text);
                    font-family: "New York", "Iowan Old Style", "Palatino Linotype", "Book Antiqua", ui-serif, serif;
                    font-size: var(--base-font-size);
                    line-height: 1.72;
                    text-rendering: optimizeLegibility;
                    -webkit-font-smoothing: antialiased;
                    overflow-wrap: anywhere;
                }

                main {
                    width: min(100%, var(--reader-width));
                    margin: 0 auto;
                    padding: 52px 60px 72px;
                    background: var(--paper-bg);
                    backdrop-filter: blur(26px) saturate(120%);
                    border: 1px solid var(--soft-border);
                    border-radius: 30px;
                    box-shadow: var(--shadow);
                    animation: fadeIn 220ms ease-out;
                }

                @keyframes fadeIn {
                    from { opacity: 0; transform: translateY(10px); }
                    to { opacity: 1; transform: translateY(0); }
                }

                h1, h2, h3, h4, h5, h6 {
                    font-family: "SF Pro Display", "Avenir Next", system-ui, sans-serif;
                    color: var(--text);
                    line-height: 1.14;
                    letter-spacing: -0.03em;
                    margin: 1.8em 0 0.65em;
                    position: relative;
                    scroll-margin-top: 48px;
                }

                h1 { font-size: 2.34em; margin-top: 0.2em; }
                h2 { font-size: 1.76em; }
                h3 { font-size: 1.38em; }
                h4 { font-size: 1.16em; }
                h5, h6 { font-size: 1em; text-transform: uppercase; letter-spacing: 0.04em; color: var(--muted); }

                p, ul, ol, blockquote, pre, table, .details-block {
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
                    padding: 1px 0 1px 1.1em;
                    border-left: 3px solid color-mix(in srgb, var(--accent) 40%, transparent);
                    background: var(--blockquote-bg);
                    border-radius: 0 18px 18px 0;
                }

                blockquote > :first-child {
                    margin-top: 0.8em;
                }

                blockquote > :last-child {
                    margin-bottom: 0.8em;
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
                    border-radius: 18px;
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
                    border-radius: 18px;
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
                    background: color-mix(in srgb, var(--paper-bg) 55%, transparent);
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
                    border-radius: 18px;
                    display: block;
                    margin: 1.2em auto;
                    box-shadow: 0 16px 36px rgba(0, 0, 0, 0.12);
                }

                .inline-image {
                    margin: 1.3em 0;
                }

                .details-block details {
                    border: 1px solid var(--soft-border);
                    border-radius: 18px;
                    padding: 14px 18px;
                    background: color-mix(in srgb, var(--paper-bg) 88%, transparent);
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

                mark.search-hit {
                    background: var(--search-bg);
                    border-radius: 0.25em;
                    padding: 0.02em 0.03em;
                }

                mark.search-hit.current {
                    background: var(--search-current);
                }

                @media (max-width: 880px) {
                    body {
                        padding: 18px 12px 34px;
                    }

                    main {
                        padding: 34px 22px 48px;
                        border-radius: 24px;
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
                            if (node.parentElement?.closest('script, style, mark')) return NodeFilter.FILTER_REJECT;
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

                window.addEventListener('load', postProgress);
                window.addEventListener('scroll', postProgress, { passive: true });
            </script>
        </body>
        </html>
        """
    }
}
