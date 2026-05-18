import Dispatch
import Foundation

public final class FileWatcher {
    private var source: DispatchSourceFileSystemObject?
    private var debouncer: FileChangeDebouncer?
    private var descriptor: Int32 = -1
    private let queue = DispatchQueue(label: "markdown-reader.file-watcher", qos: .utility)
    private let debounceInterval: DispatchTimeInterval

    public init(debounceInterval: DispatchTimeInterval = .milliseconds(180)) {
        self.debounceInterval = debounceInterval
    }

    deinit {
        stop()
    }

    public func start(url: URL, onChange: @escaping @Sendable () -> Void) {
        stop()

        descriptor = open(url.path, O_EVTONLY)
        guard descriptor >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .rename, .delete],
            queue: queue
        )
        let debouncer = FileChangeDebouncer(interval: debounceInterval, queue: queue, action: onChange)

        source.setEventHandler {
            debouncer.schedule()
        }
        source.setCancelHandler { [descriptor] in
            if descriptor >= 0 {
                close(descriptor)
            }
        }

        self.source = source
        self.debouncer = debouncer
        source.resume()
    }

    public func stop() {
        debouncer?.cancel()
        debouncer = nil
        source?.cancel()
        source = nil
        descriptor = -1
    }
}

final class FileChangeDebouncer: @unchecked Sendable {
    private let interval: DispatchTimeInterval
    private let queue: DispatchQueue
    private let action: @Sendable () -> Void
    private var pendingWorkItem: DispatchWorkItem?

    init(
        interval: DispatchTimeInterval,
        queue: DispatchQueue,
        action: @escaping @Sendable () -> Void
    ) {
        self.interval = interval
        self.queue = queue
        self.action = action
    }

    func schedule() {
        queue.async { [weak self] in
            self?.scheduleOnQueue()
        }
    }

    func cancel() {
        queue.async { [weak self] in
            self?.pendingWorkItem?.cancel()
            self?.pendingWorkItem = nil
        }
    }

    private func scheduleOnQueue() {
        pendingWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.pendingWorkItem = nil
            self.action()
        }
        pendingWorkItem = workItem
        queue.asyncAfter(deadline: .now() + interval, execute: workItem)
    }
}
