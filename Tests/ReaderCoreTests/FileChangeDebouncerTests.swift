import Dispatch
import XCTest
@testable import ReaderCore

final class FileChangeDebouncerTests: XCTestCase {
    func testDebouncerCoalescesRapidEventsIntoOneCallback() {
        let queue = DispatchQueue(label: "markdown-reader.file-debouncer-test")
        let counter = LockedCounter()
        let settled = expectation(description: "debouncer settled")

        let debouncer = FileChangeDebouncer(interval: .milliseconds(40), queue: queue) {
            counter.increment()
        }

        debouncer.schedule()
        debouncer.schedule()
        debouncer.schedule()

        queue.asyncAfter(deadline: .now() + .milliseconds(160)) {
            settled.fulfill()
        }

        wait(for: [settled], timeout: 1)

        XCTAssertEqual(counter.value, 1)
    }

    func testCancelPreventsPendingCallback() {
        let queue = DispatchQueue(label: "markdown-reader.file-debouncer-cancel-test")
        let counter = LockedCounter()
        let settled = expectation(description: "debouncer cancel settled")

        let debouncer = FileChangeDebouncer(interval: .milliseconds(80), queue: queue) {
            counter.increment()
        }

        debouncer.schedule()
        debouncer.cancel()

        queue.asyncAfter(deadline: .now() + .milliseconds(180)) {
            settled.fulfill()
        }

        wait(for: [settled], timeout: 1)

        XCTAssertEqual(counter.value, 0)
    }
}

private final class LockedCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return count
    }

    func increment() {
        lock.lock()
        count += 1
        lock.unlock()
    }
}
