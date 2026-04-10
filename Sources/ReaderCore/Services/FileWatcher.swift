import Dispatch
import Foundation

public final class FileWatcher {
    private var source: DispatchSourceFileSystemObject?
    private var descriptor: Int32 = -1
    private let queue = DispatchQueue(label: "markdown-reader.file-watcher", qos: .utility)

    public init() {}

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

        source.setEventHandler(handler: onChange)
        source.setCancelHandler { [descriptor] in
            if descriptor >= 0 {
                close(descriptor)
            }
        }

        self.source = source
        source.resume()
    }

    public func stop() {
        source?.cancel()
        source = nil
        descriptor = -1
    }
}
