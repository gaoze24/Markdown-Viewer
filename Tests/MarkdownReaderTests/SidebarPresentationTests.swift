import XCTest
import ReaderCore
@testable import MarkdownReader

final class SidebarPresentationTests: XCTestCase {
    func testLibraryPresentationAvoidsDuplicateRecentDocumentCopy() {
        let populated = WelcomeLibraryPresentation.copy(recentFileCount: 1)

        XCTAssertEqual(populated.title, "Continue Reading")
        XCTAssertNil(populated.subtitle)
    }

    func testLibraryPresentationTitleStaysConsistentForAnyRecentCount() {
        let populated = WelcomeLibraryPresentation.copy(recentFileCount: 3)

        XCTAssertEqual(populated.title, "Continue Reading")
        XCTAssertNil(populated.subtitle)
    }

    func testLibraryPresentationShowsOpeningGuidanceOnlyWhenEmpty() {
        let empty = WelcomeLibraryPresentation.copy(recentFileCount: 0)

        XCTAssertEqual(empty.title, "Markdown Reader")
        XCTAssertEqual(empty.subtitle, "Open a local Markdown file to start reading.")
    }

    func testRecentFileLocationShowsAbbreviatedFolderWithoutRepeatingFileName() {
        let home = NSHomeDirectory()

        XCTAssertEqual(
            RecentFileLocationFormatter.location(forPath: "\(home)/Projects/Notes/plan.md"),
            "~/Projects/Notes"
        )
        XCTAssertEqual(
            RecentFileLocationFormatter.location(forPath: "/tmp/plan.md"),
            "/tmp"
        )
    }

    func testRecentFileLocationFallsBackWhenPathHasNoFolder() {
        XCTAssertEqual(RecentFileLocationFormatter.location(forPath: "plan.md"), "plan.md")
    }

    func testLibraryModeDoesNotRepeatRecentFilesInHeaderSubtitle() {
        XCTAssertNil(SidebarPresentation.subtitle(hasDocument: false, outlineIsEmpty: true))
        XCTAssertNil(SidebarPresentation.subtitle(hasDocument: false, outlineIsEmpty: false))
    }

    func testDocumentModeDoesNotRepeatEmptyOutlineStateInHeaderSubtitle() {
        XCTAssertNil(SidebarPresentation.subtitle(hasDocument: true, outlineIsEmpty: true))
        XCTAssertNil(SidebarPresentation.subtitle(hasDocument: true, outlineIsEmpty: false))
    }

    func testToolbarTitleUsesCompleteSubtitleAsHoverPopoverText() {
        XCTAssertEqual(
            ToolbarTitlePresentation.subtitlePopoverText(for: "~/Downloads/very-long-path/file.md"),
            "~/Downloads/very-long-path/file.md"
        )
        XCTAssertNil(ToolbarTitlePresentation.subtitlePopoverText(for: nil))
        XCTAssertNil(ToolbarTitlePresentation.subtitlePopoverText(for: ""))
    }

    func testReaderReturnButtonOnlyShowsWhenDocumentIsOpen() {
        XCTAssertTrue(ReaderReturnPresentation.isVisible(hasDocument: true))
        XCTAssertFalse(ReaderReturnPresentation.isVisible(hasDocument: false))
    }

    func testRootDetailPagePresentationUsesStableAnimatedPageIdentities() {
        XCTAssertEqual(
            RootDetailPagePresentation.pageIdentity(hasDocument: false, documentPath: "/tmp/example.md"),
            "library"
        )
        XCTAssertEqual(
            RootDetailPagePresentation.pageIdentity(hasDocument: true, documentPath: "/tmp/example.md"),
            "reader:/tmp/example.md"
        )
        XCTAssertEqual(
            RootDetailPagePresentation.pageIdentity(hasDocument: true, documentPath: nil),
            "reader"
        )
        XCTAssertEqual(RootDetailPagePresentation.transitionAnimationDuration, 0.2)
    }

    func testOutlineRowBuilderFlattensExpandedHierarchyInDisplayOrder() {
        let child = TableOfContentsItem(id: "child", level: 2, title: "Child")
        let sibling = TableOfContentsItem(id: "sibling", level: 2, title: "Sibling")
        let root = TableOfContentsItem(id: "root", level: 1, title: "Root", children: [child, sibling])
        let later = TableOfContentsItem(id: "later", level: 1, title: "Later")

        let rows = OutlineRowBuilder.makeRows(from: [root, later], expandedIDs: ["root"])

        XCTAssertEqual(rows.map(\.id), ["root", "child", "sibling", "later"])
        XCTAssertEqual(rows.map(\.depth), [0, 1, 1, 0])
        XCTAssertEqual(rows.map(\.isExpanded), [true, false, false, false])
    }

    func testOutlineRowBuilderSkipsCollapsedChildren() {
        let child = TableOfContentsItem(id: "child", level: 2, title: "Child")
        let root = TableOfContentsItem(id: "root", level: 1, title: "Root", children: [child])

        let rows = OutlineRowBuilder.makeRows(from: [root], expandedIDs: [])

        XCTAssertEqual(rows.map(\.id), ["root"])
        XCTAssertEqual(rows.first?.isExpanded, false)
    }

    func testOutlineTreeBuilderCreatesLookupAndExpansionSets() {
        let grandchild = TableOfContentsItem(id: "grandchild", level: 3, title: "Grandchild")
        let child = TableOfContentsItem(id: "child", level: 2, title: "Child", children: [grandchild])
        let root = TableOfContentsItem(id: "root", level: 1, title: "Root", children: [child])
        let sibling = TableOfContentsItem(id: "sibling", level: 1, title: "Sibling")

        XCTAssertEqual(
            OutlineTreeBuilder.parentLookup(for: [root, sibling]),
            ["child": "root", "grandchild": "child"]
        )
        XCTAssertEqual(OutlineTreeBuilder.expandableIDs(in: [root, sibling]), ["root", "child"])
        XCTAssertEqual(OutlineTreeBuilder.defaultExpandedIDs(in: [root, sibling]), ["root", "child"])
    }
}
