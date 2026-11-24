import Foundation

enum ImportError: LocalizedError {
    case badLink, noClientID, notDownloadable, http(Int), parse

    var errorDescription: String? {
        switch self {
        case .badLink: return "Не похоже на ссылку."
        case .noClientID: return "Сначала введи SoundCloud client_id (кнопка Key)."
        case .notDownloadable: return "Автор не разрешил скачивание этого трека."
        case .http(let c): return "Ошибка сервера: \(c)"
        case .parse: return "Не удалось разобрать ответ."
        }
    }
}

struct Resolved {
    let title: String
    let artist: String
    let downloadURL: URL
    let ext: String
}

/// Официальный API SoundCloud: скачивание работает только для треков,
/// где автор включил "downloadable". Также поддерживаются прямые ссылки на mp3/m4a.
enum TrackImporter {
    static let audioExts = ["mp3", "m4a", "aac", "wav", "flac"]

    static func resolve(link: String) async throws -> Resolved {
        guard let url = URL(string: link.trimmingCharacters(in: .whitespacesAndNewlines)),
              let host = url.host else { throw ImportError.badLink }

        // Прямая ссылка на аудиофайл
        if audioExts.contains(url.pathExtension.lowercased()) {
            return Resolved(title: url.deletingPathExtension().lastPathComponent,
                            artist: host, downloadURL: url, ext: url.pathExtension.lowercased())
        }

        guard host.contains("soundcloud.com") else { throw ImportError.badLink }
        guard let cid = UserDefaults.standard.string(forKey: "sc_client_id"), !cid.isEmpty
        else { throw ImportError.noClientID }

        var c = URLComponents(string: "https://api.soundcloud.com/resolve")!
        c.queryItems = [URLQueryItem(name: "url", value: url.absoluteString),
                        URLQueryItem(name: "client_id", value: cid)]
        let (data, resp) = try await URLSession.shared.data(from: c.url!)
        if let h = resp as? HTTPURLResponse, h.statusCode != 200 { throw ImportError.http(h.statusCode) }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { throw ImportError.parse }

        let title = json["title"] as? String ?? "Track"
        let artist = (json["user"] as? [String: Any])?["username"] as? String ?? "Unknown"
        guard (json["downloadable"] as? Bool) == true,
              let dl = json["download_url"] as? String,
              let dlURL = URL(string: dl + (dl.contains("?") ? "&" : "?") + "client_id=" + cid)
        else { throw ImportError.notDownloadable }
        let ext = (json["original_format"] as? String) ?? "mp3"
        return Resolved(title: title, artist: artist, downloadURL: dlURL, ext: ext)
    }

    static func download(_ r: Resolved) async throws -> Track {
        let (tmp, resp) = try await URLSession.shared.download(from: r.downloadURL)
        if let h = resp as? HTTPURLResponse, h.statusCode != 200 { throw ImportError.http(h.statusCode) }
        let id = UUID()
        let name = "\(id.uuidString).\(r.ext)"
        let dest = Library.shared.dir.appendingPathComponent(name)
        try FileManager.default.moveItem(at: tmp, to: dest)
        return Track(id: id, title: r.title, artist: r.artist, fileName: name)
    }
}
