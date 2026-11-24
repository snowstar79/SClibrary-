import Foundation

struct Track: Codable {
    let id: UUID
    var title: String
    var artist: String
    var fileName: String
}

/// Хранит список треков (library.json) и сами файлы (Documents/Tracks)
final class Library {
    static let shared = Library()
    private(set) var tracks: [Track] = []
    let dir: URL
    private let indexURL: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        dir = docs.appendingPathComponent("Tracks", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        indexURL = docs.appendingPathComponent("library.json")
        if let d = try? Data(contentsOf: indexURL),
           let t = try? JSONDecoder().decode([Track].self, from: d) {
            tracks = t
        }
    }

    func url(for t: Track) -> URL { dir.appendingPathComponent(t.fileName) }

    func add(_ t: Track) { tracks.append(t); save() }

    func remove(at i: Int) {
        let t = tracks.remove(at: i)
        try? FileManager.default.removeItem(at: url(for: t))
        save()
    }

    private func save() {
        if let d = try? JSONEncoder().encode(tracks) { try? d.write(to: indexURL) }
    }
}
