import Foundation
import UIKit

final class SharedStore {
    static let shared = SharedStore()
    static let historyLimit = 200
    static let maximumClipboardBytes = 256_000

    private let fileURL: URL

    var lockKeyboard: Bool {
        get {
            if UserDefaults.standard.object(forKey: "lockKeyboard") != nil {
                return UserDefaults.standard.bool(forKey: "lockKeyboard")
            }
            return false
        }
        set { UserDefaults.standard.set(newValue, forKey: "lockKeyboard") }
    }

    private init() {
        fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("appdata.json")
    }

    func load() -> AppData {
        guard let data = try? Data(contentsOf: fileURL) else { return .default }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let decoded = try? decoder.decode(AppData.self, from: data) else { return .default }
        return decoded
    }

    @discardableResult
    func save(_ appData: AppData) -> Bool {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(appData)
            try data.write(to: fileURL, options: .atomic)
            return true
        } catch {
            print("SharedStore save error: \(error)")
            return false
        }
    }

    @discardableResult
    func captureClipboard(_ text: String) -> AppData? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, text.utf8.count <= Self.maximumClipboardBytes else { return nil }
        var data = load()
        data.history.removeAll { $0.content == text }
        data.history.insert(HistoryItem(content: text), at: 0)
        if data.history.count > Self.historyLimit {
            data.history = Array(data.history.prefix(Self.historyLimit))
        }
        return save(data) ? data : nil
    }
}
