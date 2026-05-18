enum CodeHighlightingAssets {
    static let style = #"""
    <style>
        :root {
            --syntax-keyword: #8f4f76;
            --syntax-string: #7c6f2c;
            --syntax-comment: #8f8478;
            --syntax-number: #a15f3b;
            --syntax-type: #4f718b;
            --syntax-function: #8b623e;
            --syntax-operator: #7b6654;
            --syntax-attribute: #73663d;
            --syntax-tag: #6b6f95;
            --syntax-literal: #9a5b55;
        }

        @media (prefers-color-scheme: dark) {
            :root {
                --syntax-keyword: #d897bd;
                --syntax-string: #c7b66b;
                --syntax-comment: #8f8173;
                --syntax-number: #d69b73;
                --syntax-type: #92bfd5;
                --syntax-function: #d2ad78;
                --syntax-operator: #bca895;
                --syntax-attribute: #c4b87a;
                --syntax-tag: #a9acd9;
                --syntax-literal: #d88c84;
            }
        }

        .syntax-token.keyword {
            color: var(--syntax-keyword);
            font-weight: 640;
        }

        .syntax-token.string {
            color: var(--syntax-string);
        }

        .syntax-token.comment {
            color: var(--syntax-comment);
            font-style: italic;
        }

        .syntax-token.number {
            color: var(--syntax-number);
        }

        .syntax-token.type {
            color: var(--syntax-type);
            font-weight: 600;
        }

        .syntax-token.function {
            color: var(--syntax-function);
        }

        .syntax-token.operator,
        .syntax-token.punctuation {
            color: var(--syntax-operator);
        }

        .syntax-token.attribute {
            color: var(--syntax-attribute);
        }

        .syntax-token.tag {
            color: var(--syntax-tag);
        }

        .syntax-token.literal {
            color: var(--syntax-literal);
        }
    </style>
    """#

    static let script = #"""
    <script>
        const syntaxLanguageAliases = {"golang":"go","js":"javascript","jsx":"javascript","mjs":"javascript","cjs":"javascript","ts":"typescript","tsx":"typescript","py":"python","rb":"ruby","rs":"rust","kt":"kotlin","kts":"kotlin","sh":"shell","bash":"shell","zsh":"shell","fish":"shell","yml":"yaml","c++":"cpp","cplusplus":"cpp","cc":"cpp","hpp":"cpp","h++":"cpp","c#":"csharp","cs":"csharp","objc":"objectivec","objective-c":"objectivec","html":"markup","xml":"markup","svg":"markup","md":"markdown","markdown":"markdown","jsonc":"json"};
        const syntaxTokenClassNames = {
            keyword: "syntax-token keyword",
            string: "syntax-token string",
            comment: "syntax-token comment",
            number: "syntax-token number",
            type: "syntax-token type",
            function: "syntax-token function",
            operator: "syntax-token operator",
            punctuation: "syntax-token punctuation",
            attribute: "syntax-token attribute",
            tag: "syntax-token tag",
            literal: "syntax-token literal"
        };

        const syntaxDefinitions = {
            go: {
                keywords: "break default func interface select case defer go map struct chan else goto package switch const fallthrough if range type continue for import return var".split(" "),
                types: "bool byte complex64 complex128 error float32 float64 int int8 int16 int32 int64 rune string uint uint8 uint16 uint32 uint64 uintptr any comparable".split(" "),
                literals: "true false nil iota".split(" ")
            },
            swift: {
                keywords: "associatedtype class deinit enum extension fileprivate func import init inout internal let open operator private protocol public rethrows static struct subscript typealias var break case catch continue default defer do else fallthrough for guard if in repeat return throw switch where while as Any false is nil self Self super true throws try await async actor nonisolated".split(" "),
                types: "Bool Character Double Float Int String UInt Array Dictionary Optional Result Set Task URL Data".split(" "),
                literals: "true false nil".split(" ")
            },
            javascript: {
                keywords: "async await break case catch class const continue debugger default delete do else export extends finally for from function get if import in instanceof let new of return set static super switch this throw try typeof var void while with yield".split(" "),
                types: "Array Boolean Date Error Map Math Number Object Promise Proxy Reflect RegExp Set String Symbol WeakMap WeakSet JSON Intl".split(" "),
                literals: "true false null undefined NaN Infinity".split(" ")
            },
            typescript: {
                extends: "javascript",
                keywords: "abstract any as asserts boolean declare enum implements infer interface keyof module namespace never override private protected public readonly require satisfies string symbol type unknown".split(" "),
                types: "Array Boolean Date Error Map Number Object Promise Record Set String Partial Pick Omit Readonly Required".split(" "),
                literals: "true false null undefined".split(" ")
            },
            python: {
                keywords: "and as assert async await break class continue def del elif else except finally for from global if import in is lambda nonlocal not or pass raise return try while with yield".split(" "),
                types: "bool bytes dict float frozenset int list object set str tuple type Exception ValueError RuntimeError".split(" "),
                literals: "True False None".split(" ")
            },
            rust: {
                keywords: "as async await break const continue crate dyn else enum extern false fn for if impl in let loop match mod move mut pub ref return self Self static struct super trait true type unsafe use where while".split(" "),
                types: "bool char f32 f64 i8 i16 i32 i64 i128 isize str String u8 u16 u32 u64 u128 usize Vec Option Result Box HashMap".split(" "),
                literals: "true false None Some Ok Err".split(" ")
            },
            java: {
                keywords: "abstract assert break case catch class const continue default do else enum extends final finally for goto if implements import instanceof interface native new package private protected public return static strictfp super switch synchronized this throw throws transient try void volatile while".split(" "),
                types: "Boolean Byte Character Class Double Exception Float Integer Long Object Optional Short String Thread Void List Map Set".split(" "),
                literals: "true false null".split(" ")
            },
            kotlin: {
                keywords: "as break class continue do else false for fun if in interface is null object package return super this throw true try typealias val var when while by catch constructor delegate dynamic field file finally get import init param property receiver set setparam where actual abstract annotation companion const crossinline data enum expect external final infix inline inner internal lateinit noinline open operator out override private protected public reified sealed suspend tailrec vararg".split(" "),
                types: "Any Boolean Byte Char Double Float Int Long Nothing Short String Unit List Map MutableList MutableMap Set".split(" "),
                literals: "true false null".split(" ")
            },
            cpp: {
                keywords: "alignas alignof asm auto break case catch class concept const constexpr continue decltype default delete do else enum explicit export extern for friend goto if import inline mutable namespace new noexcept operator private protected public register requires return sizeof static static_assert struct switch template this throw try typedef typeid typename union using virtual volatile while".split(" "),
                types: "bool char double float int long short signed size_t std string uint8_t uint16_t uint32_t uint64_t void wchar_t".split(" "),
                literals: "true false nullptr NULL".split(" ")
            },
            c: {
                keywords: "auto break case const continue default do else enum extern for goto if inline register restrict return sizeof static struct switch typedef union volatile while".split(" "),
                types: "bool char double float int long short signed size_t uint8_t uint16_t uint32_t uint64_t void".split(" "),
                literals: "true false NULL".split(" ")
            },
            csharp: {
                keywords: "abstract as base bool break byte case catch char checked class const continue decimal default delegate do double else enum event explicit extern false finally fixed float for foreach goto if implicit in int interface internal is lock long namespace new null object operator out override params private protected public readonly ref return sbyte sealed short sizeof stackalloc static string struct switch this throw true try typeof uint ulong unchecked unsafe ushort using virtual void volatile while async await var record init".split(" "),
                types: "Action DateTime Dictionary Exception Func Guid IEnumerable IList List Object String Task ValueTask".split(" "),
                literals: "true false null".split(" ")
            },
            ruby: {
                keywords: "BEGIN END alias and begin break case class def defined do else elsif end ensure false for if in module next nil not or redo rescue retry return self super then true undef unless until when while yield".split(" "),
                types: "Array Class Exception Float Hash Integer Module Object String Symbol".split(" "),
                literals: "true false nil".split(" ")
            },
            php: {
                keywords: "abstract and array as break callable case catch class clone const continue declare default die do echo else elseif empty enddeclare endfor endforeach endif endswitch endwhile enum eval exit extends final finally fn for foreach function global goto if implements include include_once instanceof insteadof interface isset list match namespace new or print private protected public readonly require require_once return static switch throw trait try unset use var while xor yield".split(" "),
                types: "array bool float int object string void mixed iterable".split(" "),
                literals: "true false null TRUE FALSE NULL".split(" ")
            },
            shell: {
                keywords: "case do done elif else esac export fi for function if in local readonly select set shift then unset until while".split(" "),
                types: "cd echo printf read test".split(" "),
                literals: "true false".split(" ")
            },
            sql: {
                keywords: "add all alter and as asc between by case create delete desc distinct drop else exists from group having in index inner insert into is join left like limit not null on or order outer primary right select set table then union update values when where with".split(" "),
                types: "bigint boolean char date datetime decimal double float int integer json numeric real text timestamp varchar".split(" "),
                literals: "true false null".split(" ")
            },
            json: {
                keywords: [],
                types: [],
                literals: "true false null".split(" ")
            },
            yaml: {
                keywords: "apiVersion kind metadata spec services containers image ports name labels annotations".split(" "),
                types: [],
                literals: "true false null yes no on off".split(" ")
            },
            markup: {
                keywords: "doctype html head body div span main article section header footer nav script style link meta img a p h1 h2 h3 h4 h5 h6 ul ol li table thead tbody tr th td".split(" "),
                types: [],
                literals: []
            },
            css: {
                keywords: "align-items animation background border box-shadow color display flex font grid height justify-content margin max-width min-height opacity overflow padding position transform transition width z-index".split(" "),
                types: "absolute block border-box center fixed flex grid hidden inline inline-block none relative solid sticky transparent".split(" "),
                literals: "inherit initial unset".split(" ")
            },
            markdown: {
                keywords: "blockquote code emphasis heading image link list table".split(" "),
                types: [],
                literals: []
            }
        };

        function syntaxDefinitionFor(language) {
            const definition = syntaxDefinitions[language];
            if (!definition) return null;
            if (!definition.extends) return definition;
            const parent = syntaxDefinitionFor(definition.extends);
            return {
                keywords: [...(parent?.keywords || []), ...(definition.keywords || [])],
                types: [...(parent?.types || []), ...(definition.types || [])],
                literals: [...(parent?.literals || []), ...(definition.literals || [])]
            };
        }

        function normalizedCodeLanguage(code) {
            const classNames = [...code.classList, ...code.parentElement.classList];
            const languageClass = classNames.find((name) => name.startsWith("language-"));
            if (!languageClass) return null;
            const raw = languageClass.slice("language-".length).replace(/^\./, "").toLowerCase();
            return syntaxLanguageAliases[raw] || raw;
        }

        function documentSyntaxHint() {
            const heading = document.querySelector("#reader-root h1")?.textContent || "";
            return heading.trim().toLowerCase();
        }

        function inferSyntaxLanguage(source, documentHint) {
            const normalizedHint = documentHint.toLowerCase();
            if (/\b(golang|go)\b/.test(normalizedHint) || normalizedHint.includes("golang cheat sheet")) {
                return "go";
            }
            if (/\b(swift|swiftui)\b/.test(normalizedHint)) return "swift";
            if (/\b(type\s*script|typescript|tsx)\b/.test(normalizedHint)) return "typescript";
            if (/\b(java\s*script|javascript|jsx|node)\b/.test(normalizedHint)) return "javascript";
            if (/\b(python|py)\b/.test(normalizedHint)) return "python";
            if (/\b(rust|cargo)\b/.test(normalizedHint)) return "rust";
            if (/\b(sql|postgres|mysql|sqlite)\b/.test(normalizedHint)) return "sql";
            if (/\b(shell|bash|zsh|terminal|cli)\b/.test(normalizedHint)) return "shell";

            const text = source.toLowerCase();
            let goScore = 0;
            if (/\b(func|package|import|defer|select|chan|goroutine|go\s+func|range)\b/.test(text)) goScore += 3;
            if (/\b(bool|string|byte|rune|float32|float64|complex64|complex128|uint8|uint16|uint32|uint64|uintptr)\b/.test(text)) goScore += 2;
            if (text.includes(":=") || text.includes("<-") || text.includes("fmt.")) goScore += 2;
            if (/\/\/|\/\*/.test(text)) goScore += 1;
            if (goScore >= 3) return "go";

            if (/^\s*[{[]/.test(text) && /"[^"]+"\s*:/.test(text)) return "json";
            if (/\b(select|insert|update|delete|from|where|join|create table)\b/.test(text)) return "sql";
            if (/^\s*(#!\/|npm |yarn |pnpm |cd |echo |export )/m.test(text)) return "shell";
            if (/\b(def|import|from|elif|lambda|self)\b/.test(text)) return "python";
            if (/\b(let|const|function|import|export|console\.|=>)\b/.test(text)) return "javascript";

            return null;
        }

        function escapeSyntaxHTML(value) {
            return value.replace(/[&<>"']/g, (character) => ({
                "&": "&amp;",
                "<": "&lt;",
                ">": "&gt;",
                '"': "&quot;",
                "'": "&#39;"
            }[character]));
        }

        function syntaxSpan(kind, value) {
            return `<span class="${syntaxTokenClassNames[kind]}">${escapeSyntaxHTML(value)}</span>`;
        }

        function readQuoted(source, start) {
            const quote = source[start];
            let cursor = start + 1;
            while (cursor < source.length) {
                const current = source[cursor];
                if (current === "\\") {
                    cursor += 2;
                    continue;
                }
                cursor += 1;
                if (current === quote) break;
            }
            return cursor;
        }

        function readLine(source, start) {
            const newline = source.indexOf("\n", start);
            return newline === -1 ? source.length : newline;
        }

        function readIdentifier(source, start) {
            let cursor = start + 1;
            while (cursor < source.length && /[A-Za-z0-9_$-]/.test(source[cursor])) {
                cursor += 1;
            }
            return cursor;
        }

        function readNumber(source, start) {
            let cursor = start + 1;
            while (cursor < source.length && /[A-Za-z0-9_.]/.test(source[cursor])) {
                cursor += 1;
            }
            return cursor;
        }

        function nextNonWhitespace(source, start) {
            let cursor = start;
            while (cursor < source.length && /\s/.test(source[cursor])) {
                cursor += 1;
            }
            return source[cursor] || "";
        }

        function tokenSetsFor(definition) {
            return {
                keywords: new Set((definition.keywords || []).map((value) => value.toLowerCase())),
                types: new Set((definition.types || []).map((value) => value.toLowerCase())),
                literals: new Set((definition.literals || []).map((value) => value.toLowerCase()))
            };
        }

        function highlightSource(source, language, definition) {
            const tokenSets = tokenSetsFor(definition);
            const hashCommentLanguages = new Set(["python", "ruby", "shell", "yaml", "toml", "makefile", "r"]);
            const slashCommentLanguages = new Set(["go", "swift", "javascript", "typescript", "rust", "java", "kotlin", "cpp", "c", "csharp", "php", "css"]);
            let output = "";
            let cursor = 0;

            while (cursor < source.length) {
                const current = source[cursor];

                if (language === "markup" && source.startsWith("<!--", cursor)) {
                    const end = source.indexOf("-->", cursor + 4);
                    const next = end === -1 ? source.length : end + 3;
                    output += syntaxSpan("comment", source.slice(cursor, next));
                    cursor = next;
                    continue;
                }

                if (slashCommentLanguages.has(language) && source.startsWith("/*", cursor)) {
                    const end = source.indexOf("*/", cursor + 2);
                    const next = end === -1 ? source.length : end + 2;
                    output += syntaxSpan("comment", source.slice(cursor, next));
                    cursor = next;
                    continue;
                }

                if (slashCommentLanguages.has(language) && source.startsWith("//", cursor)) {
                    const next = readLine(source, cursor);
                    output += syntaxSpan("comment", source.slice(cursor, next));
                    cursor = next;
                    continue;
                }

                if (language === "sql" && source.startsWith("--", cursor)) {
                    const next = readLine(source, cursor);
                    output += syntaxSpan("comment", source.slice(cursor, next));
                    cursor = next;
                    continue;
                }

                if (hashCommentLanguages.has(language) && current === "#") {
                    const next = readLine(source, cursor);
                    output += syntaxSpan("comment", source.slice(cursor, next));
                    cursor = next;
                    continue;
                }

                if (current === "\"" || current === "'" || current === "`") {
                    const next = readQuoted(source, cursor);
                    const nextToken = nextNonWhitespace(source, next);
                    const kind = language === "json" && nextToken === ":" ? "attribute" : "string";
                    output += syntaxSpan(kind, source.slice(cursor, next));
                    cursor = next;
                    continue;
                }

                if (/[0-9]/.test(current)) {
                    const next = readNumber(source, cursor);
                    output += syntaxSpan("number", source.slice(cursor, next));
                    cursor = next;
                    continue;
                }

                if (/[A-Za-z_$]/.test(current)) {
                    const next = readIdentifier(source, cursor);
                    const word = source.slice(cursor, next);
                    const key = word.toLowerCase();
                    let kind = null;
                    if (tokenSets.keywords.has(key)) {
                        kind = language === "markup" ? "tag" : "keyword";
                    } else if (tokenSets.types.has(key)) {
                        kind = "type";
                    } else if (tokenSets.literals.has(key)) {
                        kind = "literal";
                    } else if (nextNonWhitespace(source, next) === "(") {
                        kind = "function";
                    }
                    output += kind ? syntaxSpan(kind, word) : escapeSyntaxHTML(word);
                    cursor = next;
                    continue;
                }

                if (/[{}()[\].,;:]/.test(current)) {
                    output += syntaxSpan("punctuation", current);
                    cursor += 1;
                    continue;
                }

                if (/[+\-*/%=!<>|&^~?@]/.test(current)) {
                    output += syntaxSpan("operator", current);
                    cursor += 1;
                    continue;
                }

                output += escapeSyntaxHTML(current);
                cursor += 1;
            }

            return output;
        }

        function highlightCodeBlocks() {
            const blocks = document.querySelectorAll("pre.code-block code");
            const documentHint = documentSyntaxHint();
            for (const code of blocks) {
                if (code.dataset.highlighted === "true") continue;
                const source = code.textContent || "";
                const language = normalizedCodeLanguage(code) || inferSyntaxLanguage(source, documentHint);
                if (!language) continue;
                const definition = syntaxDefinitionFor(language);
                if (!definition) continue;
                code.innerHTML = highlightSource(source, language, definition);
                code.dataset.highlighted = "true";
            }
        }
    </script>
    """#
}
