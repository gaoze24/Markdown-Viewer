import XCTest
@testable import MarkdownReader

final class SidebarPresentationTests: XCTestCase {
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

    func testToolbarProgressIsVisibleForDocumentEvenAtTop() {
        XCTAssertTrue(
            ToolbarProgressPresentation.isVisible(
                showProgressPreference: true,
                hasDocument: true
            )
        )
        XCTAssertFalse(
            ToolbarProgressPresentation.isVisible(
                showProgressPreference: false,
                hasDocument: true
            )
        )
        XCTAssertFalse(
            ToolbarProgressPresentation.isVisible(
                showProgressPreference: true,
                hasDocument: false
            )
        )
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
}
