import Foundation

struct Slugifier {
    private var counts: [String: Int] = [:]

    mutating func slug(for string: String) -> String {
        let scalarView = string.lowercased().unicodeScalars
        var pieces: [String] = []
        var current = ""

        for scalar in scalarView {
            if CharacterSet.alphanumerics.contains(scalar) {
                current.unicodeScalars.append(scalar)
            } else if !current.isEmpty {
                pieces.append(current)
                current.removeAll(keepingCapacity: true)
            }
        }

        if !current.isEmpty {
            pieces.append(current)
        }

        let base = pieces.joined(separator: "-").trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        let resolvedBase = base.isEmpty ? "section" : base
        let count = counts[resolvedBase, default: 0]
        counts[resolvedBase] = count + 1
        return count == 0 ? resolvedBase : "\(resolvedBase)-\(count + 1)"
    }
}
